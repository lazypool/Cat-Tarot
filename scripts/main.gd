extends Node3D

const CARD_SCENE := preload("res://scenes/card_3d.tscn")
const CARD_SPACING := 1.95
const CARD_Y := 0.065
const CARD_Z := 0.0
const WORLD_ID := 21
const HAND_Z := 3.2
const HAND_SCALE := 0.8
const HAND_SPACING := 0.9
const HAND_FAN_DEGREES := 8.0
const HAND_STACK_STEP := 0.01
const HAND_HOLD_POS := Vector3(0.0, 0.6, 2.4)
const HAND_HOLD_SCALE := 0.92
const DISCARD_POS := Vector3(5.4, 1.2, 2.85)
const CARD_MOVE_TIME := 0.90

@onready var card_root: Node3D = $CardRoot
@onready var camera: Camera3D = $Camera3D
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var dice: Dice3D = $Dice3D
@onready var deck: Node3D = $Deck3D
@onready var restart_button: RestartButton3D = $RestartButton3D

var _slot_cards: Array = [null, null, null]
var _hand_root: Node3D
var _hand_cards: Array[Card3D] = []
var _hand_holders: Array[Node3D] = []
var _textures: Dictionary = {}
var _world_shown: bool = false
var _world_card: Card3D = null
var _seed: int = 0
var _choice_animating: bool = false
var _defer_hand_rebuild: bool = false
var _field_update_pending: bool = false
var _pending_field_cards: Array = []
var _field_deal_id: int = 0
var _pending_hold_card: Card3D = null
var _hold_slot: int = -1
var _hand_discarding: bool = false
var _hand_lift_tween: Tween
var _roll_pending: bool = false


func _ready() -> void:
	camera.look_at(Vector3(0.0, 0.0, 0.5), Vector3.UP)
	sun.rotation_degrees = Vector3(-60, -30, 0)
	_hand_root = Node3D.new()
	_hand_root.name = "HandRoot"
	add_child(_hand_root)
	GameManager.field_cards_changed.connect(_on_field_cards_changed)
	GameManager.selected_card_changed.connect(_on_selected_card_changed)
	GameManager.choice_committed.connect(_on_choice_committed)
	GameManager.orientation_rolled.connect(_on_orientation_rolled)
	GameManager.marks_changed.connect(_on_marks_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.game_started.connect(_on_game_started)
	dice.clicked.connect(_on_die_clicked)
	dice.roll_finished.connect(_on_die_roll_finished)
	restart_button.pressed.connect(_on_restart_pressed)
	Loc.language_changed.connect(_on_language_changed)
	_seed = _read_seed()
	GameManager.new_game(_seed)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			GameManager.new_game(_seed)


func _read_seed() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			var value := arg.trim_prefix("--seed=")
			if value.is_valid_int():
				return int(value)
	return 0


func _slot_position(index: int) -> Vector3:
	return Vector3((index - 1) * CARD_SPACING, CARD_Y, CARD_Z)


func _on_field_cards_changed(cards: Array) -> void:
	if _choice_animating:
		_pending_field_cards = cards.duplicate()
		_field_update_pending = true
		return
	_apply_field_cards(cards)


func _apply_field_cards(cards: Array) -> void:
	_field_deal_id += 1
	var deal_id := _field_deal_id
	var incoming: Array[Dictionary] = []
	for i in 3:
		var runtime: Dictionary = {}
		if i < cards.size() and cards[i] != null:
			runtime = cards[i]
		var node: Card3D = _slot_cards[i]
		if runtime.is_empty():
			if node != null and is_instance_valid(node):
				node.queue_free()
			_slot_cards[i] = null
			continue
		var target := _slot_position(i)
		var card_id := int(runtime["card_id"])
		if node != null and is_instance_valid(node) and node.card_id == card_id:
			node.base_position = target
			if not _roll_pending:
				node.set_state(str(runtime["orientation"]))
				node.set_effect_text(_effect_text(card_id, str(runtime["orientation"])))
			continue
		if node != null and is_instance_valid(node):
			node.queue_free()
		_slot_cards[i] = null
		incoming.append({
			"slot": i,
			"runtime": runtime,
			"target": target,
		})
	_apply_selection_visual()
	for request in incoming:
		if deal_id != _field_deal_id:
			return
		await _deal_card(request)


func _deal_card(request: Dictionary) -> void:
	var slot := int(request["slot"])
	var runtime: Dictionary = request["runtime"]
	var target: Vector3 = request["target"]
	var orientation := str(runtime["orientation"])
	var card_id := int(runtime["card_id"])
	var pivot := Node3D.new()
	pivot.position = card_root.to_local(deck.top_card_position())
	card_root.add_child(pivot)
	var card: Card3D = CARD_SCENE.instantiate()
	pivot.add_child(card)
	card.position = Vector3.ZERO
	card.setup(card_id, _texture_for(card_id))
	card.base_position = target
	card.scale = Vector3.ONE * 0.9
	card.animation_locked = true
	card.area.input_ray_pickable = false
	card.set_effect_text(_effect_text(card_id, orientation))
	card.clicked.connect(_on_card_clicked)
	card.accept_pressed.connect(_on_card_accept)
	card.refuse_pressed.connect(_on_card_refuse)
	_slot_cards[slot] = card
	Audio.play_sfx("card_draw", -4.0)
	deck.draw_cards(1)
	if not await _animate_card_draw(pivot, card):
		return
	card.reparent(card_root, true)
	pivot.queue_free()
	await _animate_card_entry(card, target, orientation)


func _animate_card_draw(pivot: Node3D, card: Card3D, reveal_sound: bool = false) -> bool:
	pivot.rotation.z = PI
	card.set_back_visible(true)
	var start_y := pivot.position.y
	var spin := create_tween()
	spin.tween_property(pivot, "rotation:z", 0.0, 0.50)
	var arc := create_tween()
	arc.tween_property(pivot, "position:y", start_y + 0.8, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	arc.tween_property(pivot, "position:y", start_y + 0.2, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(card):
		card.set_back_visible(false)
		if reveal_sound:
			Audio.play_sfx("card_reveal", -2.0)
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(pivot):
		pivot.rotation.z = 0.0
		pivot.position.y = start_y + 0.2
	if not is_instance_valid(card) or not is_instance_valid(pivot):
		if is_instance_valid(pivot):
			pivot.queue_free()
		return false
	return true


func _animate_card_entry(card: Card3D, target: Vector3, orientation: String) -> void:
	Audio.play_sfx("card_slide", -7.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "position", target, CARD_MOVE_TIME)
	tween.tween_property(card, "scale", Vector3.ONE, CARD_MOVE_TIME * 0.8)
	await tween.finished
	if not is_instance_valid(card):
		return
	var target_reversed := orientation.to_upper() == "REVERSED"
	if card.is_reversed != target_reversed:
		Audio.play_sfx("card_flip", -5.0)
		card.set_state(orientation)
		if card._flip_tween != null and card._flip_tween.is_valid():
			await card._flip_tween.finished
	if not is_instance_valid(card):
		return
	card.animation_locked = false
	card.base_position = target
	card.area.input_ray_pickable = true
	_apply_selection_visual()


func _on_card_clicked(card_id: int) -> void:
	Audio.play_sfx("card_tap", -5.0)
	GameManager.select_card(card_id)


func _on_selected_card_changed(_card_id: int, _slot: int) -> void:
	_apply_selection_visual()


func _on_card_accept() -> void:
	GameManager.accept_selected()


func _on_card_refuse() -> void:
	GameManager.refuse_selected()


func _on_choice_committed(accepted: bool, card_id: int, slot: int) -> void:
	if _choice_animating:
		return
	if slot < 0 or slot >= _slot_cards.size():
		return
	var card: Card3D = _slot_cards[slot]
	if card == null or not is_instance_valid(card) or card.card_id != card_id:
		return
	for other in _slot_cards:
		if other != null and is_instance_valid(other):
			other.hide_actions()
	_choice_animating = true
	_defer_hand_rebuild = accepted
	card.animation_locked = true
	card.set_selected(false)
	card.set_dimmed(false)
	card.set_effect_text("")
	card.area.input_ray_pickable = false
	# A full hand holds the accepted card above the fan so the player drops one first.
	var hold := accepted and GameManager.marks.size() >= GameManager.MAX_MARKS
	if hold:
		_hold_slot = slot
		_pending_hold_card = card
		_lift_hand()
		return
	var accept_layout: Dictionary = {}
	var hand_count := 0
	if accepted:
		hand_count = GameManager.marks.size() + 1
		accept_layout = _hand_slot_layout(hand_count - 1, hand_count)
	_play_choice_exit(card, accepted, slot, accept_layout, false, hand_count)


func _lift_hand() -> void:
	if _hand_lift_tween != null and _hand_lift_tween.is_valid():
		_hand_lift_tween.kill()
	_hand_lift_tween = create_tween()
	_hand_lift_tween.set_parallel(true)
	_hand_lift_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for holder in _hand_holders:
		if holder == null or not is_instance_valid(holder):
			continue
		_hand_lift_tween.tween_property(holder, "position:y", holder.position.y + 0.15, 0.36)


func _animate_hand_gap(count: int) -> void:
	if _hand_lift_tween != null and _hand_lift_tween.is_valid():
		_hand_lift_tween.kill()
	if count <= 1 or _hand_holders.is_empty():
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in _hand_holders.size():
		var holder: Node3D = _hand_holders[i]
		if holder == null or not is_instance_valid(holder):
			continue
		var layout := _hand_slot_layout(i, count)
		tween.tween_property(holder, "position", layout["position"], 0.40)
		tween.tween_property(holder, "rotation:y", float(layout["yaw"]), 0.40)
	await tween.finished


func _play_choice_exit(card: Card3D, accepted: bool, slot: int, accept_layout: Dictionary, hold: bool, hand_count: int) -> void:
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(card):
		_after_choice_exit(accepted, slot)
		return
	if accepted:
		await _animate_hand_gap(hand_count)
		Audio.play_sfx("card_slide", -3.0)
	else:
		Audio.play_sfx("card_discard", -3.0)
	var target: Vector3
	var target_scale: Vector3
	var target_yaw: float
	if hold:
		target = _slot_position(slot) + Vector3(0.0, 0.28, 0.45)
		target_scale = Vector3.ONE * HAND_HOLD_SCALE
		target_yaw = 0.0
	elif accepted:
		target = accept_layout["position"]
		target_scale = Vector3.ONE * float(accept_layout["scale"])
		target_yaw = float(accept_layout["yaw"])
	else:
		target = DISCARD_POS
		target_scale = Vector3.ONE * 0.82
		target_yaw = card.rotation.y + deg_to_rad(30.0)
	var move_time := CARD_MOVE_TIME
	if accepted:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(card, "position", target, move_time)
		tween.tween_property(card, "scale", target_scale, move_time)
		tween.tween_property(card, "rotation:y", target_yaw, move_time)
		await tween.finished
	else:
		var move := create_tween()
		move.set_parallel(true)
		move.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		move.tween_property(card, "position:x", target.x, move_time)
		move.tween_property(card, "position:z", target.z, move_time)
		move.tween_property(card, "scale", target_scale, move_time)
		move.tween_property(card, "rotation:y", target_yaw, move_time)
		var lift := create_tween()
		lift.tween_property(card, "position:y", target.y, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await lift.finished
		await move.finished
	if hold:
		if is_instance_valid(card):
			card.area.input_ray_pickable = false
			_pending_hold_card = card
		_after_choice_exit(accepted, slot)
		return
	if is_instance_valid(card):
		card.queue_free()
	_after_choice_exit(accepted, slot)


func _after_choice_exit(accepted: bool, slot: int) -> void:
	if slot >= 0 and slot < _slot_cards.size():
		_slot_cards[slot] = null
	_choice_animating = false
	if accepted:
		_defer_hand_rebuild = false
		_rebuild_hand()
	else:
		_defer_hand_rebuild = false
	if not _field_update_pending:
		return
	_field_update_pending = false
	var cards := _pending_field_cards
	_pending_field_cards = []
	await get_tree().create_timer(0.08).timeout
	_apply_field_cards(cards)


func _apply_selection_visual() -> void:
	var has_selection: bool = int(GameManager.selected_card) >= 0
	for card in _slot_cards:
		if card == null or not is_instance_valid(card):
			continue
		var is_selected: bool = card.card_id == int(GameManager.selected_card)
		card.set_selected(is_selected)
		card.set_dimmed(has_selection and not is_selected)
	_refresh_card_actions()


func _refresh_card_actions() -> void:
	if _roll_pending:
		return
	for card in _slot_cards:
		if card != null and is_instance_valid(card):
			card.hide_actions()
	if GameManager.phase != GameManager.Phase.SELECT or GameManager.selected_slot < 0:
		return
	var card: Card3D = _slot_cards[GameManager.selected_slot]
	var runtime := GameManager.get_selected_runtime()
	if card == null or not is_instance_valid(card) or runtime.is_empty():
		return
	var o_data := CardDatabase.orientation_data(int(runtime["card_id"]), str(runtime["orientation"]).to_lower())
	card.show_actions(o_data.get("accept", []), o_data.get("refuse", []))


func _on_orientation_rolled(value: int) -> void:
	_roll_pending = true
	for card in _slot_cards:
		if card != null and is_instance_valid(card):
			card.hide_actions()
	dice.roll_to(value)


func _on_die_roll_finished(_value: int) -> void:
	if not _roll_pending:
		return
	_roll_pending = false
	var any_flip := false
	for i in _slot_cards.size():
		var card: Card3D = _slot_cards[i]
		var runtime = GameManager.field_cards[i] if i < GameManager.field_cards.size() else null
		if card != null and is_instance_valid(card) and runtime != null:
			var target_reversed := str(runtime["orientation"]).to_upper() == "REVERSED"
			if card.is_reversed != target_reversed:
				any_flip = true
			card.set_state(str(runtime["orientation"]))
			card.set_effect_text(_effect_text(int(runtime["card_id"]), str(runtime["orientation"])))
	if any_flip:
		Audio.play_sfx("card_flip", -4.0)
	_refresh_card_actions()


func _on_die_clicked() -> void:
	if GameManager.phase == GameManager.Phase.SELECT:
		Audio.play_sfx("dice_roll", -2.0)
		GameManager.roll_die()


func _on_game_started(_seed_value: int) -> void:
	Audio.start_music()
	restart_button.set_highlight(false)
	_roll_pending = false
	dice.reset(int(GameManager.die_value))
	deck.reset()
	_clear_cards()
	_clear_hand()
	_clear_hold_card()
	_world_shown = false
	_choice_animating = false
	_defer_hand_rebuild = false
	_hand_discarding = false
	_field_update_pending = false
	_pending_field_cards = []


func _on_language_changed() -> void:
	for i in _slot_cards.size():
		var card: Card3D = _slot_cards[i]
		var runtime = GameManager.field_cards[i] if i < GameManager.field_cards.size() else null
		if card != null and is_instance_valid(card) and runtime != null:
			card.refresh_language()
			card.set_effect_text(_effect_text(int(runtime["card_id"]), str(runtime["orientation"])))
	for i in _hand_cards.size():
		var hand_card: Card3D = _hand_cards[i]
		var mark = GameManager.marks[i] if i < GameManager.marks.size() else null
		if hand_card != null and is_instance_valid(hand_card) and mark != null:
			var text := _effect_text(int(mark["card_id"]), str(mark["orientation"]))
			hand_card.refresh_language()
			hand_card.set_hover_effect_text(text)
			if hand_card.hovered:
				hand_card.set_effect_text(text)


func _on_state_changed() -> void:
	_apply_selection_visual()
	restart_button.set_highlight(GameManager.phase == GameManager.Phase.GAME_OVER)
	if GameManager.phase == GameManager.Phase.FINAL or (GameManager.phase == GameManager.Phase.GAME_OVER and GameManager.game_over_reason_key == "reason.world_end"):
		_show_world()


func _on_restart_pressed() -> void:
	GameManager.new_game(0)


func _show_world() -> void:
	if _world_shown:
		return
	_world_shown = true
	while _choice_animating and _world_shown:
		await get_tree().process_frame
	if not _world_shown:
		return
	_clear_cards()
	var target := Vector3(0.0, CARD_Y, CARD_Z)
	var pivot := Node3D.new()
	pivot.position = card_root.to_local(deck.top_card_position())
	card_root.add_child(pivot)
	_world_card = CARD_SCENE.instantiate()
	pivot.add_child(_world_card)
	_world_card.position = Vector3.ZERO
	_world_card.setup(WORLD_ID, _texture_for(WORLD_ID))
	_world_card.base_position = target
	_world_card.scale = Vector3.ONE * 0.9
	_world_card.animation_locked = true
	_world_card.area.input_ray_pickable = false
	Audio.play_sfx("card_draw", -4.0)
	if not await _animate_card_draw(pivot, _world_card, true):
		return
	_world_card.reparent(card_root, true)
	pivot.queue_free()
	deck.hide_all()
	await _animate_card_entry(_world_card, target, "UPRIGHT")
	if not is_instance_valid(_world_card):
		return
	_world_card.area.input_ray_pickable = false
	_world_card.base_position = target
	_world_card.set_world_display()
	_world_card.set_selected(true)


func _clear_cards() -> void:
	if _world_card != null and is_instance_valid(_world_card):
		_world_card.queue_free()
	_world_card = null
	for card in _slot_cards:
		if card != null and is_instance_valid(card):
			card.queue_free()
	_slot_cards = [null, null, null]


func _on_marks_changed(_marks: Array) -> void:
	if _defer_hand_rebuild:
		return
	_rebuild_hand()


func _hand_slot_layout(index: int, count: int) -> Dictionary:
	var center := (count - 1) * 0.5
	var offset := float(index) - center
	var spacing := HAND_SPACING if count <= 5 else 0.72
	var layer := HAND_STACK_STEP if offset > 0.0 else 0.0
	return {
		"position": Vector3(
			offset * spacing,
			CARD_Y + absf(offset) * 0.08 + layer,
			HAND_Z + offset * 0.05
		),
		"yaw": deg_to_rad(-offset * HAND_FAN_DEGREES),
		"scale": HAND_SCALE,
	}


func _rebuild_hand() -> void:
	_clear_hand()
	var count := GameManager.marks.size()
	for i in count:
		var mark: Dictionary = GameManager.marks[i]
		var card_id := int(mark["card_id"])
		var orientation := str(mark["orientation"])
		var layout := _hand_slot_layout(i, count)
		var holder := Node3D.new()
		holder.position = layout["position"]
		holder.rotation.y = float(layout["yaw"])
		holder.scale = Vector3.ONE * float(layout["scale"])
		_hand_root.add_child(holder)
		var card: Card3D = CARD_SCENE.instantiate()
		holder.add_child(card)
		card.setup(card_id, _texture_for(card_id))
		card.set_shadows_enabled(false)
		card.set_state(orientation, false)
		card.set_effect_text("")
		card.set_hover_effect_text(_effect_text(card_id, orientation))
		card.clicked.connect(_on_hand_card_clicked.bind(card_id))
		_hand_holders.append(holder)
		_hand_cards.append(card)
	# The incoming card (hand already full) floats above the fan until one is dropped.
	if not GameManager.pending_new_mark.is_empty():
		_ensure_hold_card()
	else:
		_clear_hold_card()


func _on_hand_card_clicked(_emitted_id: int, card_id: int) -> void:
	if GameManager.pending_new_mark.is_empty() or _hand_discarding:
		return
	_discard_and_replace(card_id)


func _discard_and_replace(card_id: int) -> void:
	_hand_discarding = true
	_choice_animating = true
	_defer_hand_rebuild = true
	# Drop the chosen card first, then fly the held card into the opened slot.
	var idx := -1
	for i in _hand_cards.size():
		if is_instance_valid(_hand_cards[i]) and _hand_cards[i].card_id == card_id:
			idx = i
			break
	if idx >= 0:
		var holder: Node3D = _hand_holders[idx]
		_hand_holders.remove_at(idx)
		_hand_cards.remove_at(idx)
		await _animate_hand_drop(holder)
	GameManager.replace_mark(card_id)
	await _animate_hand_gap(GameManager.marks.size())
	await _animate_hold_into_hand()
	if _hold_slot >= 0 and _hold_slot < _slot_cards.size() and _slot_cards[_hold_slot] == _pending_hold_card:
		_slot_cards[_hold_slot] = null
	_hold_slot = -1
	_choice_animating = false
	_defer_hand_rebuild = false
	_hand_discarding = false
	_rebuild_hand()
	if _field_update_pending:
		_field_update_pending = false
		var cards := _pending_field_cards
		_pending_field_cards = []
		await get_tree().create_timer(0.08).timeout
		_apply_field_cards(cards)


func _animate_hand_drop(holder: Node3D) -> void:
	if holder == null or not is_instance_valid(holder):
		return
	Audio.play_sfx("card_discard", -3.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(holder, "position", holder.position + Vector3(0.0, -0.4, 1.6), 0.36)
	tween.tween_property(holder, "scale", holder.scale * 0.4, 0.36)
	tween.tween_property(holder, "rotation:y", holder.rotation.y + deg_to_rad(40.0), 0.36)
	await tween.finished
	if is_instance_valid(holder):
		holder.queue_free()


func _animate_hold_into_hand() -> void:
	if _pending_hold_card == null or not is_instance_valid(_pending_hold_card):
		return
	var count := GameManager.marks.size()
	if count <= 0:
		return
	var layout := _hand_slot_layout(count - 1, count)
	var card := _pending_hold_card
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "position", layout["position"], 0.50)
	tween.tween_property(card, "scale", Vector3.ONE * float(layout["scale"]), 0.50)
	tween.tween_property(card, "rotation:y", float(layout["yaw"]), 0.50)
	await tween.finished


func _ensure_hold_card() -> void:
	if _pending_hold_card != null and is_instance_valid(_pending_hold_card):
		return
	var pending := GameManager.pending_new_mark
	if pending.is_empty():
		return
	var card_id := int(pending["card_id"])
	var card: Card3D = CARD_SCENE.instantiate()
	card.position = HAND_HOLD_POS
	card.scale = Vector3.ONE * HAND_HOLD_SCALE
	card_root.add_child(card)
	card.setup(card_id, _texture_for(card_id))
	card.set_shadows_enabled(false)
	card.set_state(str(pending["orientation"]), false)
	card.area.input_ray_pickable = false
	_pending_hold_card = card


func _clear_hold_card() -> void:
	if _pending_hold_card != null and is_instance_valid(_pending_hold_card):
		_pending_hold_card.queue_free()
	_pending_hold_card = null


func _clear_hand() -> void:
	for holder in _hand_holders:
		if holder != null and is_instance_valid(holder):
			holder.queue_free()
	_hand_holders.clear()
	_hand_cards.clear()


func _effect_text(card_id: int, orientation: String) -> String:
	var o_data := CardDatabase.orientation_data(card_id, orientation.to_lower())
	return str(o_data.get("mark_text_" + Loc.language, o_data.get("mark_text_en", "")))


func _texture_for(card_id: int) -> Texture2D:
	if _textures.has(card_id):
		return _textures[card_id]
	var path := CardDatabase.texture_path(card_id)
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			texture = loaded
	if texture == null:
		push_warning("Cat-Tarot: missing card texture, using placeholder: " + path)
	_textures[card_id] = texture
	return texture
