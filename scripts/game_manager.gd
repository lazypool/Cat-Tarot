extends Node

signal state_changed
signal field_cards_changed(cards: Array)
signal selected_card_changed(card_id: int, slot: int)
signal choice_committed(accepted: bool, card_id: int, slot: int)
signal orientation_rolled(value: int)
signal marks_changed(marks: Array)
signal game_over(reason_key: String)
signal game_started(seed: int)
signal choice_requested(kind: String, prompt_key: String, data: Dictionary)

enum Phase { SETUP, SELECT, RESOLVE, FINAL, GAME_OVER }

const TOTAL_CARDS := 21
const MAX_MARKS := 5
const WORLD_ID := 21
const STAT_KEYS: Array[String] = ["passion", "intuition", "curiosity", "comfort"]
const ORIENT_UPRIGHT := "UPRIGHT"
const ORIENT_REVERSED := "REVERSED"
const DIE_COSTS := {
	1: {"plus": "passion", "minus": "intuition"},
	2: {"plus": "intuition", "minus": "passion"},
	3: {"plus": "curiosity", "minus": "comfort"},
	4: {"plus": "comfort", "minus": "curiosity"},
	5: {"plus": "passion", "minus": "comfort"},
	6: {"plus": "curiosity", "minus": "intuition"},
}

var stats: Dictionary = {"passion": 4, "intuition": 4, "curiosity": 4, "comfort": 4}
var die_value: int = 1
var deck: Array[int] = []
var field_cards: Array = [null, null, null]
var selected_slot: int = -1
var selected_card: int = -1
var marks: Array[Dictionary] = []
var choices_completed: int = 0
var refusals_total: int = 0
var phase: Phase = Phase.SETUP
var pending_new_mark: Dictionary = {}
var effect_queue: Array[Dictionary] = []
var flow: String = ""
var flow_new_mark_card: int = -1
var game_over_won: bool = false
var game_over_reason_key: String = ""
var roll_cost_enabled: bool = true
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var rng_seed: int = 0
var debug_forced_rolls: Array[int] = []


func new_game(seed_value: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
		rng_seed = rng.seed
	else:
		rng_seed = seed_value
		rng.seed = seed_value
	stats = {"passion": 4, "intuition": 4, "curiosity": 4, "comfort": 4}
	die_value = rng.randi_range(1, 6)
	deck.clear()
	for id in range(TOTAL_CARDS):
		deck.append(id)
	_shuffle(deck)
	field_cards = [null, null, null]
	for i in 3:
		if deck.is_empty():
			break
		field_cards[i] = _make_runtime(deck.pop_front())
	selected_slot = -1
	selected_card = -1
	marks.clear()
	choices_completed = 0
	refusals_total = 0
	phase = Phase.SELECT
	pending_new_mark.clear()
	effect_queue.clear()
	flow = ""
	flow_new_mark_card = -1
	game_over_won = false
	game_over_reason_key = ""
	roll_cost_enabled = true
	debug_forced_rolls.clear()
	_log("=== Cat-Tarot === " + Loc.t("log.seed") + " " + str(rng_seed))
	_log(Loc.t("log.start"))
	marks_changed.emit(marks.duplicate())
	game_started.emit(rng_seed)
	field_cards_changed.emit(field_cards.duplicate())
	_emit_state()


func _make_runtime(card_id: int) -> Dictionary:
	var card := CardDatabase.get_card(card_id)
	return {
		"card_id": card_id,
		"orientation": _orientation_for(card_id, die_value),
		"last_roll": die_value,
		"upright_pips": card.get("upright_pips", []).duplicate(),
		"reversed_pips": card.get("reversed_pips", []).duplicate(),
	}


func _orientation_for(card_id: int, value: int) -> String:
	var card := CardDatabase.get_card(card_id)
	if card.is_empty():
		return ORIENT_UPRIGHT
	if card["reversed_pips"].has(value):
		return ORIENT_REVERSED
	return ORIENT_UPRIGHT


func _apply_die_to_field() -> void:
	for i in field_cards.size():
		var runtime = field_cards[i]
		if runtime == null:
			continue
		runtime["orientation"] = _orientation_for(int(runtime["card_id"]), die_value)
		runtime["last_roll"] = die_value
		field_cards[i] = runtime


func _runtime_at(slot: int) -> Dictionary:
	if slot < 0 or slot >= field_cards.size():
		return {}
	var runtime = field_cards[slot]
	if runtime == null:
		return {}
	return runtime


func get_selected_runtime() -> Dictionary:
	return _runtime_at(selected_slot)


func get_selected_card_data() -> Dictionary:
	if selected_card < 0:
		return {}
	return CardDatabase.get_card(selected_card)


func get_selected_orientation() -> String:
	var runtime := get_selected_runtime()
	if runtime.is_empty():
		return ORIENT_UPRIGHT
	return str(runtime["orientation"])


func get_selected_orientation_data() -> Dictionary:
	if selected_card < 0:
		return {}
	var runtime := get_selected_runtime()
	if runtime.is_empty():
		return {}
	return CardDatabase.orientation_data(selected_card, str(runtime["orientation"]).to_lower())


func select_card(card_id: int) -> void:
	if phase != Phase.SELECT:
		return
	var slot := -1
	for i in field_cards.size():
		var runtime = field_cards[i]
		if runtime != null and int(runtime["card_id"]) == card_id:
			slot = i
			break
	if slot < 0:
		return
	selected_slot = slot
	selected_card = card_id
	_log(Loc.tf("log.select", [Loc.card_name(card_id)]))
	selected_card_changed.emit(card_id, slot)
	_emit_state()


func select_slot(slot: int) -> void:
	if phase != Phase.SELECT or slot < 0 or slot >= field_cards.size():
		return
	var runtime = field_cards[slot]
	if runtime == null:
		return
	select_card(int(runtime["card_id"]))


func roll_die() -> void:
	if phase != Phase.SELECT:
		return
	die_value = _roll_d6()
	_apply_die_to_field()
	_log(Loc.tf("log.die", [die_value]))
	orientation_rolled.emit(die_value)
	field_cards_changed.emit(field_cards.duplicate())
	if roll_cost_enabled:
		var cost := get_die_cost(die_value)
		if _apply_stat_delta(str(cost["plus"]), 1, "roll"):
			return
		if _apply_stat_delta(str(cost["minus"]), -1, "roll"):
			return
	_emit_state()


func accept_selected() -> void:
	if phase != Phase.SELECT or selected_slot < 0:
		return
	var runtime := get_selected_runtime()
	if runtime.is_empty():
		return
	flow = "accept"
	flow_new_mark_card = -1
	choices_completed += 1
	var orientation := str(runtime["orientation"]).to_lower()
	var card := CardDatabase.get_card(int(runtime["card_id"]))
	var o_data: Dictionary = card["orientations"][orientation]
	choice_committed.emit(true, int(runtime["card_id"]), selected_slot)
	_log(Loc.tf("log.accept", [Loc.card_name(int(runtime["card_id"])), Loc.orientation_name(str(runtime["orientation"]))]))
	if _apply_actions(o_data.get("accept", []), "accept") == "death":
		return
	# Gain the mark now, then run on-acquire / existing when-accept / every-3 effects.
	if marks.size() >= MAX_MARKS:
		pending_new_mark = {"card_id": int(runtime["card_id"]), "orientation": str(runtime["orientation"])}
		marks_changed.emit(marks.duplicate())
		phase = Phase.RESOLVE
		_emit_state()
		return
	_add_mark(int(runtime["card_id"]), str(runtime["orientation"]))
	_flow_new_mark_added(int(runtime["card_id"]))
	_start_accept_queue()


func refuse_selected() -> void:
	if phase != Phase.SELECT or selected_slot < 0:
		return
	var runtime := get_selected_runtime()
	if runtime.is_empty():
		return
	flow = "refuse"
	flow_new_mark_card = -1
	choices_completed += 1
	refusals_total += 1
	var orientation := str(runtime["orientation"]).to_lower()
	var card := CardDatabase.get_card(int(runtime["card_id"]))
	var o_data: Dictionary = card["orientations"][orientation]
	choice_committed.emit(false, int(runtime["card_id"]), selected_slot)
	_log(Loc.tf("log.refuse", [Loc.card_name(int(runtime["card_id"])), Loc.orientation_name(str(runtime["orientation"]))]))
	if _apply_actions(o_data.get("refuse", []), "refuse") == "death":
		return
	_start_refuse_queue()


func _add_mark(card_id: int, orientation: String) -> int:
	var record := {
		"card_id": card_id,
		"orientation": orientation,
		"order": marks.size(),
		"uses": {},
	}
	marks.append(record)
	_log(Loc.tf("log.mark_gain", [Loc.card_name(card_id), Loc.orientation_name(orientation)]))
	marks_changed.emit(marks.duplicate())
	return marks.size() - 1


func _flow_new_mark_added(card_id: int) -> void:
	flow_new_mark_card = card_id


func replace_mark(old_card_id: int) -> void:
	if pending_new_mark.is_empty():
		return
	var new_card_id := int(pending_new_mark["card_id"])
	var new_orientation := str(pending_new_mark["orientation"])
	pending_new_mark.clear()
	var old_index := -1
	for i in marks.size():
		if int(marks[i]["card_id"]) == old_card_id:
			old_index = i
			break
	if old_index >= 0:
		marks.remove_at(old_index)
		for i in marks.size():
			marks[i]["order"] = i
	_add_mark(new_card_id, new_orientation)
	_flow_new_mark_added(new_card_id)
	phase = Phase.RESOLVE
	_start_accept_queue()


func _start_accept_queue() -> void:
	phase = Phase.RESOLVE
	effect_queue.clear()
	for mark in marks:
		if flow_new_mark_card >= 0 and int(mark["card_id"]) == flow_new_mark_card:
			continue
		_enqueue_mark_timing(int(mark["card_id"]), "on_accept")
	if choices_completed % 3 == 0:
		for mark in marks:
			if flow_new_mark_card >= 0 and int(mark["card_id"]) == flow_new_mark_card:
				continue
			_enqueue_mark_timing(int(mark["card_id"]), "on_3turn")
	_process_effect_queue()


func _start_refuse_queue() -> void:
	phase = Phase.RESOLVE
	effect_queue.clear()
	for mark in marks:
		_enqueue_mark_timing(int(mark["card_id"]), "on_refuse")
	if choices_completed % 3 == 0:
		for mark in marks:
			_enqueue_mark_timing(int(mark["card_id"]), "on_3turn")
	_process_effect_queue()


func _enqueue_mark_timing(card_id: int, trigger: String) -> void:
	var mark_index := _mark_index(card_id)
	if mark_index < 0:
		return
	var mark: Dictionary = marks[mark_index]
	var orientation := str(mark["orientation"]).to_lower()
	var o_data := CardDatabase.orientation_data(card_id, orientation)
	var effects: Array = o_data.get("effects", [])
	for j in effects.size():
		var effect: Dictionary = effects[j]
		if str(effect.get("trigger", "")) != trigger:
			continue
		effect_queue.append({"mark_index": mark_index, "effect_index": j})


func _mark_index(card_id: int) -> int:
	for i in marks.size():
		if int(marks[i]["card_id"]) == card_id:
			return i
	return -1


func _process_effect_queue() -> void:
	if phase == Phase.GAME_OVER:
		return
	while not effect_queue.is_empty():
		var job: Dictionary = effect_queue.pop_front()
		var result := _trigger_effect(job)
		if result == "pause" or result == "death":
			return
	_finish_choice_resolution()


func _trigger_effect(job: Dictionary) -> String:
	var mark_index := int(job["mark_index"])
	if mark_index < 0 or mark_index >= marks.size():
		return "ok"
	var mark: Dictionary = marks[mark_index]
	var effect_index := int(job["effect_index"])
	var card_id := int(mark["card_id"])
	var orientation := str(mark["orientation"]).to_lower()
	var o_data := CardDatabase.orientation_data(card_id, orientation)
	var effects: Array = o_data.get("effects", [])
	if effect_index < 0 or effect_index >= effects.size():
		return "ok"
	var effect: Dictionary = effects[effect_index]
	var actions: Array = effect.get("actions", [])
	for action in actions:
		var result := _apply_action(action, card_id, effect_index, mark_index)
		if result == "death":
			return "death"
	_log(Loc.tf("log.mark_trigger", [Loc.card_name(card_id), Loc.orientation_name(orientation.to_upper())]))
	return "ok"


func _apply_action(action: Dictionary, _card_id: int, _effect_index: int, _mark_index: int) -> String:
	var t := str(action.get("type", ""))
	match t:
		"stat":
			var death := _apply_stat_delta(str(action["stat"]), int(action["delta"]), "effect")
			return "death" if death else "ok"
		"all":
			for key in STAT_KEYS:
				var death := _apply_stat_delta(key, int(action["delta"]), "effect")
				if death:
					return "death"
			return "ok"
	return "ok"


func _apply_actions(actions: Array, source: String) -> String:
	for action in actions:
		var t := str(action.get("type", ""))
		if t == "stat":
			var death := _apply_stat_delta(str(action["stat"]), int(action["delta"]), source, action.get("floor", null), action.get("cap", null))
			if death:
				return "death"
		elif t == "all":
			for key in STAT_KEYS:
				var death := _apply_stat_delta(key, int(action["delta"]), source, action.get("floor", null), action.get("cap", null))
				if death:
					return "death"
	return "ok"


func _apply_stat_delta(stat: String, delta: int, source: String, floor_value = null, cap_value = null) -> bool:
	if phase == Phase.GAME_OVER:
		return true
	if not STAT_KEYS.has(stat):
		return false
	var old_value := int(stats[stat])
	var raw := old_value + delta
	if floor_value != null:
		raw = maxi(raw, int(floor_value))
	if cap_value != null:
		raw = mini(raw, int(cap_value))
	stats[stat] = raw
	if old_value != raw:
		var delta_text := ("+%d" % delta) if delta > 0 else str(delta)
		_log(Loc.tf("log.stat_change", [Loc.stat_name(stat), delta_text, raw]))
	_emit_state()
	if _check_any_death():
		return true
	return phase == Phase.GAME_OVER


func _check_any_death() -> bool:
	for key in STAT_KEYS:
		if int(stats[key]) <= 0 or int(stats[key]) >= 10:
			_start_death()
			return true
	return false


func _start_death() -> void:
	if phase == Phase.GAME_OVER:
		return
	effect_queue.clear()
	pending_new_mark.clear()
	flow_new_mark_card = -1
	game_over_won = false
	game_over_reason_key = "reason.death"
	phase = Phase.GAME_OVER
	_log(Loc.t("log.death_end"))
	game_over.emit(game_over_reason_key)
	_emit_state()



func _finish_choice_resolution() -> void:
	if phase == Phase.GAME_OVER:
		return
	# Remove the resolved card and refill from the deck.
	if selected_slot >= 0 and selected_slot < field_cards.size():
		field_cards[selected_slot] = null
		if not deck.is_empty():
			field_cards[selected_slot] = _make_runtime(deck.pop_front())
	field_cards_changed.emit(field_cards.duplicate())
	selected_slot = -1
	selected_card = -1
	flow = ""
	flow_new_mark_card = -1
	effect_queue.clear()
	if choices_completed >= TOTAL_CARDS:
		_enter_final_end()
		return
	phase = Phase.SELECT
	_emit_state()


func _enter_final_end() -> void:
	phase = Phase.FINAL
	_log(Loc.t("log.final_start"))
	_emit_state()
	game_over_won = true
	game_over_reason_key = "reason.world_end"
	_log(Loc.t("log.world_end"))
	phase = Phase.GAME_OVER
	game_over.emit(game_over_reason_key)
	_emit_state()


func get_mark_remaining(_mark: Dictionary) -> String:
	return ""


func _roll_d6() -> int:
	if not debug_forced_rolls.is_empty():
		return debug_forced_rolls.pop_front()
	return rng.randi_range(1, 6)


func _shuffle(values: Array[int]) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp


func _log(_text: String) -> void:
	pass


func _emit_state() -> void:
	state_changed.emit()


func debug_force_rolls(rolls: Array) -> void:
	debug_forced_rolls.clear()
	for roll in rolls:
		debug_forced_rolls.append(int(roll))


func debug_set_roll_cost(enabled: bool) -> void:
	roll_cost_enabled = enabled


func get_die_cost(value: int) -> Dictionary:
	return DIE_COSTS.get(clampi(value, 1, 6), DIE_COSTS[1])


func debug_set_stats(passion: int, intuition: int, curiosity: int, comfort: int) -> void:
	stats = {"passion": passion, "intuition": intuition, "curiosity": curiosity, "comfort": comfort}
	_emit_state()


func debug_grant_mark(card_id: int, orientation: String = "upright") -> void:
	_add_mark(card_id, orientation)
	_emit_state()


func debug_set_deck(ids: Array) -> void:
	deck.clear()
	for id in ids:
		deck.append(int(id))
	_emit_state()


func debug_select(slot: int) -> void:
	select_slot(slot)


func debug_roll() -> void:
	roll_die()


func debug_accept() -> void:
	accept_selected()


func debug_refuse() -> void:
	refuse_selected()


func debug_clear_field() -> void:
	field_cards = [null, null, null]
	selected_slot = -1
	selected_card = -1
	field_cards_changed.emit(field_cards.duplicate())
	_emit_state()


func debug_set_field_card(slot: int, card_id: int, orientation: String = "", last_roll: int = -1) -> void:
	if slot < 0 or slot >= 3:
		return
	var runtime := _make_runtime(card_id)
	if orientation != "":
		runtime["orientation"] = orientation.to_upper()
	if last_roll >= 0:
		runtime["last_roll"] = last_roll
	field_cards[slot] = runtime
	field_cards_changed.emit(field_cards.duplicate())
	_emit_state()


func debug_set_die(value: int) -> void:
	die_value = clampi(value, 1, 6)
	_apply_die_to_field()
	field_cards_changed.emit(field_cards.duplicate())
	_emit_state()


func debug_set_choices(count: int) -> void:
	choices_completed = count
	_emit_state()


func debug_set_refusals(count: int) -> void:
	refusals_total = count
	_emit_state()
