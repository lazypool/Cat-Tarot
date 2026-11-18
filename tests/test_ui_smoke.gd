extends Node

var main: Node
var ui: Node
var failed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	ui = main.get_node("UI")
	var top_bar: Control = ui.root.get_node_or_null("TopBar")
	check(top_bar != null, "top bar exists")
	check_eq(top_bar.get_child_count(), 1, "top bar has a single content row")
	check_eq((top_bar.get_child(0) as Node).get_child_count(), 2, "top bar shows only the cat avatar and stats")
	check_eq(Audio._streams.size(), Audio.SFX_FILES.size(), "all card and dice sounds load")
	check(Audio._music != null and Audio._music.stream != null, "background music loads")
	if Audio._music != null and Audio._music.stream is AudioStreamOggVorbis:
		check((Audio._music.stream as AudioStreamOggVorbis).loop, "background music loops seamlessly")
	check(Audio.is_music_playing(), "background music starts with a run")
	check(main.restart_button != null, "restart button sits on the table")
	await get_tree().create_timer(6.2).timeout
	check(GameManager.field_cards.size() == 3, "opening field")
	check(GameManager.deck.size() == 18, "opening deck")
	check_eq(main.deck._cards.size(), 22, "draw pile builds all cards")
	check_eq(main.deck._remaining, 18, "draw pile drops after the opening deal")
	var visible_deck_cards := 0
	for card in main.deck._cards:
		if card.visible:
			visible_deck_cards += 1
	check_eq(visible_deck_cards, 19, "draw pile keeps the World at the bottom")
	check(main.deck._cards[0].visible, "World card stays under the draw pile")
	for key in ["passion", "intuition", "curiosity", "comfort"]:
		check(ui.stat_values.has(key), "stat widget " + key)
		check_eq(ui.stat_values[key].text, "4", "initial " + key)
	for card in main._slot_cards:
		check(card._action_root == null or not card._action_root.visible, "card actions hidden before selection")
	check(main._hand_cards.is_empty(), "hand starts empty")
	for runtime in GameManager.field_cards:
		check(str(runtime["orientation"]) in ["UPRIGHT", "REVERSED"], "unselected field card is oriented")
	for card in main._slot_cards:
		check(card.effect_text != "", "field card effect text is present")
		check(card._effect_sprite != null and card._effect_sprite.visible, "field card shows its effect at the top")
	GameManager.debug_set_field_card(0, 2, "UPRIGHT")
	await get_tree().process_frame
	check(main._slot_cards[0]._effect_label.text.contains("[img="), "field effect text uses stat icons")
	check(main._slot_cards[0]._effect_label.text.contains("_color.png"), "field effect icons are colored")
	var dice = main.get_node("Dice3D")
	check(dice._cost_sprite != null and dice._cost_sprite.get_parent() == dice, "roll cost is a die child")
	check(dice._cost_sprite.position.y < 0.0, "roll cost lies on the tabletop")
	check(absf(dice._cost_sprite.rotation_degrees.x + 90.0) < 0.1, "roll cost is flat on the table")
	check(dice._cost_sprite.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "roll cost is not a billboard")
	check(dice._cost_sprite.position.z < -0.5, "roll cost is spaced away from the die")
	var dice_screen: Vector2 = main.camera.unproject_position(dice.global_position)
	var cost_screen: Vector2 = main.camera.unproject_position(dice._cost_sprite.global_position)
	check(absf(cost_screen.x - dice_screen.x) < 8.0, "roll cost is centered above the die")
	check(dice._cost_label.get_theme_font_size("normal_font_size") >= 44, "roll cost font is large")
	check_eq(main._slot_cards[0]._format_delta_text("Passion +1, Comfort -1"), "Passion + 1, Comfort - 1", "effect text spaces deltas and uses minus")
	var font := UiFonts.get_font()
	check(font != null, "tiered UI font loads")
	if font != null:
		check(font.fallbacks.size() >= 2, "tiered UI font attaches Lemi and Yozai fallbacks")
		for codepoint in [0x002D, 0x0060, 0x007C, 0x2192, 0x2264, 0x2265, 0x732B, 0x73CF, 0x74A8]:
			check(font.has_char(codepoint), "font chain supports U+%04X" % codepoint)
	var slot0_card: Card3D = main._slot_cards[0]
	var effect_width: float = float(slot0_card._effect_viewport.size.x) * slot0_card._effect_sprite.pixel_size
	check(effect_width < main.CARD_SPACING, "card effect label width fits within slot spacing")
	check(slot0_card._prevent_orphan_wrap("Comfort - 1.").contains("-\u00A01"), "sign and number glue with non-breaking space")

	# The die works without selecting anything and updates the whole field.
	GameManager.debug_force_rolls([4])
	main._on_die_clicked()
	await get_tree().create_timer(1.1).timeout
	check_eq(GameManager.selected_slot, -1, "die clicked with no selection")
	check_eq(int(GameManager.die_value), 4, "die value applied")
	for runtime in GameManager.field_cards:
		check_eq(int(runtime["last_roll"]), 4, "whole field uses the die")
		check(str(runtime["orientation"]) in ["UPRIGHT", "REVERSED"], "whole field is oriented")
	check_eq(int(GameManager.stats["passion"]), 4, "die 4 leaves passion")
	check_eq(int(GameManager.stats["intuition"]), 4, "die 4 leaves intuition")
	check_eq(int(GameManager.stats["curiosity"]), 3, "die 4 lowers curiosity")
	check_eq(int(GameManager.stats["comfort"]), 5, "die 4 raises comfort")
	check(dice._cost_label.text.contains("+ 1"), "die cost label shows the gain")
	check(dice._cost_label.text.contains("- 1"), "die cost label shows the loss")
	for card in main._slot_cards:
		check(card._action_root == null or not card._action_root.visible, "card actions stay hidden without selection")

	var card_id := int(GameManager.field_cards[0]["card_id"])
	main._on_card_clicked(card_id)
	await get_tree().process_frame
	check_eq(GameManager.selected_slot, 0, "card selected after rolling")
	var selected_card = main._slot_cards[0]
	check(selected_card._action_root != null and selected_card._action_root.visible, "card actions visible")
	check(selected_card._accept_sprite.get_parent() == selected_card._action_root, "accept icon is part of the card")
	check(selected_card._reject_sprite.get_parent() == selected_card._action_root, "refuse icon is part of the card")
	check(selected_card._accept_label.text.contains("[img="), "accept effects use stat icons")
	check(selected_card._reject_label.text.contains("[img="), "refuse effects use stat icons")
	check(selected_card._delta_bbcode(-1).contains("- 1"), "negative effect renders as minus with a space")
	check(selected_card._delta_bbcode(1).contains("+ 1"), "positive effect has a space after plus")
	var all_text: String = selected_card._actions_bbcode([{"type": "all", "delta": 1}])
	check_eq(all_text.count("[img="), 4, "all-stat effect shows four icons")
	check_eq(all_text.count("+ 1"), 4, "all-stat effect shows one value per stat")
	check(selected_card._accept_sprite.position.y < -1.2, "accept icon sits below the card surface")
	selected_card._on_action_hover(true, true)
	check(selected_card._accept_sprite.modulate.g > selected_card._accept_sprite.modulate.r, "accept hover turns green")
	selected_card._on_action_hover(true, false)

	selected_card.accept_pressed.emit()
	check(not selected_card._action_root.visible, "card actions hide when the choice starts")
	await get_tree().create_timer(1.8).timeout
	check_eq(GameManager.choices_completed, 1, "accept resolves choice")
	check(GameManager.marks.size() >= 1, "accept gains a mark")
	check_eq(main._hand_cards.size(), GameManager.marks.size(), "3D hand shows the gained mark")
	if main._hand_holders.size() >= 2:
		var first_holder: Node3D = main._hand_holders[0]
		var last_holder: Node3D = main._hand_holders[main._hand_holders.size() - 1]
		check(absf(first_holder.rotation.y - last_holder.rotation.y) > 0.01, "hand cards form a natural fan")
		check(absf(first_holder.position.z - last_holder.position.z) > 0.1, "hand cards are separated on the z axis")
	for i in main._hand_cards.size():
		var card = main._hand_cards[i]
		var mark_orientation := str(GameManager.marks[i]["orientation"]).to_upper()
		var expected_rotation := PI if mark_orientation == "REVERSED" else 0.0
		check(card.front.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "hand cards do not cast overlapping shadows")
		check(card.effect_text == "", "hand cards do not show effect text at rest")
		check(card.hover_effect_text != "", "hand cards carry their effect for hover")
		check(absf(card.front.rotation.z - expected_rotation) < 0.01, "hand card keeps its mark orientation")
		check(card._effect_sprite == null, "hand cards do not render an effect overlay at rest")
		card._on_mouse_entered()
		check(card.effect_text != "", "hand hover shows the effect text")
		check(card._effect_sprite != null and card._effect_sprite.visible, "hand hover shows the effect overlay")
		card._on_mouse_exited()
		check(card.effect_text == "", "hand hover effect clears")

	var zh_tip: String = (ui.stat_boxes["passion"] as Control).tooltip_text
	var zh_hand_text: String = main._hand_cards[0].hover_effect_text if not main._hand_cards.is_empty() else ""
	Loc.toggle_language()
	await get_tree().process_frame
	check_eq(Loc.language, "en", "language toggled to English")
	check_eq((ui.stat_boxes["passion"] as Control).tooltip_text, Loc.stat_name("passion"), "stat tooltip updates on language toggle")
	if not main._hand_cards.is_empty():
		check(main._hand_cards[0].hover_effect_text != zh_hand_text, "hand card hover text updates on language toggle")
	Loc.toggle_language()
	await get_tree().process_frame
	check_eq(Loc.language, "zh", "language toggled back")
	check_eq((ui.stat_boxes["passion"] as Control).tooltip_text, zh_tip, "stat tooltip restores zh text")
	if not main._hand_cards.is_empty():
		check_eq(main._hand_cards[0].hover_effect_text, zh_hand_text, "hand card hover text restores zh text")

	# Full hand: choose the replacement directly from the 3D hand.
	GameManager.new_game(99)
	for id in [1, 2, 3, 5, 6]:
		GameManager.debug_grant_mark(id, "reversed" if id == 3 else "upright")
	GameManager.debug_set_field_card(0, 0, "UPRIGHT")
	await get_tree().create_timer(2.2).timeout
	main._on_card_clicked(0)
	await get_tree().process_frame
	main._on_card_accept()
	await get_tree().create_timer(1.4).timeout
	check(not GameManager.pending_new_mark.is_empty(), "sixth mark waits for a hand choice")
	check(not main.restart_button.is_highlighted(), "no restart halo while the run continues")
	check_eq(main._hand_cards.size(), 5, "hand fan keeps the five held marks")
	var hand_layers: Array[float] = []
	for holder in main._hand_holders:
		hand_layers.append(holder.position.y)
	for i in hand_layers.size():
		for j in range(i + 1, hand_layers.size()):
			check(absf(hand_layers[i] - hand_layers[j]) > 0.001, "hand cards occupy distinct layers")
	for i in main._hand_cards.size():
		var mark_orientation := str(GameManager.marks[i]["orientation"]).to_upper()
		var expected_rotation := PI if mark_orientation == "REVERSED" else 0.0
		check(absf(main._hand_cards[i].front.rotation.z - expected_rotation) < 0.01, "hand fan keeps reversed marks reversed")
	check(main._pending_hold_card != null and is_instance_valid(main._pending_hold_card), "accepted card waits near the table")
	check(absf(main._pending_hold_card.position.z) < 0.05, "held card does not move forward")
	check(absf(main._pending_hold_card.position.x + 1.95) < 0.05, "held card stays in its original slot")
	check(main._hand_holders[0].position.y > 0.2, "hand cards lift up while waiting for a replacement")
	var old_id := int(GameManager.marks[0]["card_id"])
	main._on_hand_card_clicked(0, old_id)
	await get_tree().create_timer(1.8).timeout
	check(GameManager.pending_new_mark.is_empty(), "hand click resolves replacement")
	check(has_mark_in(GameManager, 0), "hand click adds the new mark")
	check(not has_mark_in(GameManager, old_id), "hand click removes the old mark")

	# Tower resolves its effect without a choice modal.
	GameManager.new_game(99)
	GameManager.debug_set_stats(6, 4, 3, 5)
	GameManager.debug_set_field_card(0, 17, "REVERSED")
	main._on_card_clicked(17)
	await get_tree().process_frame
	main._on_card_accept()
	await get_tree().process_frame
	await get_tree().process_frame
	check(not main.restart_button.is_highlighted(), "Tower does not light the restart halo")
	check_eq(int(GameManager.stats["passion"]), 5, "Tower reverses the highest stat")
	check_eq(int(GameManager.stats["intuition"]), 5, "Tower raises the lowest stat")

	# Death ends the run directly.
	GameManager.new_game(99)
	GameManager.debug_set_stats(1, 4, 4, 4)
	GameManager.debug_set_field_card(0, 1, "UPRIGHT")
	main._on_card_clicked(1)
	await get_tree().process_frame
	main._on_card_accept()
	await get_tree().process_frame
	await get_tree().process_frame
	check_eq(GameManager.phase, 4, "death ends the run")
	check_eq(GameManager.game_over_reason_key, "reason.death", "death reason")
	check(main.restart_button.is_highlighted(), "death lights the restart halo")
	check(ui.root.get_node_or_null("ModalLayer") == null, "death shows no end panel")

	# World-end restart halo wiring.
	GameManager.new_game(99)
	GameManager.debug_set_choices(20)
	GameManager.debug_set_field_card(0, 0, "UPRIGHT")
	main._on_card_clicked(0)
	await get_tree().process_frame
	main._on_card_refuse()
	await get_tree().process_frame
	await get_tree().process_frame
	check_eq(GameManager.phase, 4, "world end phase")
	check(main.restart_button.is_highlighted(), "world end lights the restart halo")
	check(ui.root.get_node_or_null("ModalLayer") == null, "world end shows no end panel")
	await get_tree().create_timer(3.5).timeout
	check(main._world_card != null and is_instance_valid(main._world_card), "World card is drawn to the table")
	var any_deck_card_visible := false
	for deck_card in main.deck._cards:
		if deck_card.visible:
			any_deck_card_visible = true
	check(not any_deck_card_visible and not main.deck._top_visual.visible, "draw pile is hidden after the World")

	# The tabletop restart button starts a clean run and clears the World card.
	main.restart_button.pressed.emit()
	await get_tree().create_timer(1.4).timeout
	check_eq(GameManager.phase, GameManager.Phase.SELECT, "table restart starts a new run")
	check(not main.restart_button.is_highlighted(), "restart halo clears on a new run")
	check(main._world_card == null, "World card leaves the table on a new run")
	check(main.deck._top_visual.visible, "draw pile returns on a new run")

	print("UI smoke failures: %d" % failed)
	get_tree().quit(1 if failed > 0 else 0)


func has_mark_in(manager: Node, card_id: int) -> bool:
	for mark in manager.marks:
		if int(mark["card_id"]) == card_id:
			return true
	return false


func check(condition: bool, label: String) -> void:
	if not condition:
		failed += 1
		push_error("FAIL " + label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return
	failed += 1
	push_error("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])
