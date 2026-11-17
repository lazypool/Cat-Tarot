extends Node

const P_SELECT := 1
const P_RESOLVE := 2
const P_FINAL := 3
const P_GAME_OVER := 4
const STATS: Array[String] = ["passion", "intuition", "curiosity", "comfort"]

var gm: Node
var passed: int = 0
var failed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	gm = load("res://scripts/game_manager.gd").new()
	add_child(gm)
	var tests: Array[String] = [
		"test_initial_state",
		"test_pip_integrity",
		"test_roll_per_card_and_switch",
		"test_accept_refuse_immediate",
		"test_mark_on_acquire_tower",
		"test_every_three_trigger",
		"test_upper_death",
		"test_new_mark_when_accept_excluded",
		"test_death_ends_run",
		"test_emperor_intercept",
		"test_mark_cap",
		"test_final_end",
		"test_effect_data",
		"test_split_flow_21",
		"test_roll_cost_tradeoff",
	]
	for test_name in tests:
		var result: Variant = call(test_name)
		if result != true:
			failed += 1
			push_error("FAIL %s: did not finish" % test_name)
	print("Results: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s" % label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


func fresh(seed_value: int = 1234) -> void:
	gm.new_game(seed_value)
	gm.debug_set_roll_cost(false)


func set_field(ids: Array, orientation: String = "", last_roll: int = -1) -> void:
	gm.debug_clear_field()
	for i in ids.size():
		gm.debug_set_field_card(i, int(ids[i]), orientation, last_roll)


func select_slot(slot: int) -> void:
	gm.debug_select(slot)


func roll(value: int) -> void:
	gm.debug_force_rolls([value])
	gm.debug_roll()


func has_mark(card_id: int) -> bool:
	for mark in gm.marks:
		if int(mark["card_id"]) == card_id:
			return true
	return false


func test_initial_state() -> bool:
	fresh()
	for key in STATS:
		check_eq(int(gm.stats[key]), 4, "initial %s" % key)
	check_eq(gm.field_cards.size(), 3, "field size")
	check(int(gm.die_value) >= 1 and int(gm.die_value) <= 6, "initial die face is rolled")
	for runtime in gm.field_cards:
		check(runtime != null, "field slot filled")
		check(str(runtime["orientation"]) in ["UPRIGHT", "REVERSED"], "field always has orientation")
		check_eq(int(runtime["last_roll"]), int(gm.die_value), "field uses the initial die face")
		check(not gm.deck.has(21), "World not in deck")
		check(not runtime["upright_pips"].is_empty(), "upright pips present")
		check(not runtime["reversed_pips"].is_empty(), "reversed pips present")
	check_eq(gm.deck.size(), 18, "opening deck")
	check_eq(gm.marks.size(), 0, "no marks")
	check_eq(gm.choices_completed, 0, "no choices")
	check_eq(gm.phase, P_SELECT, "select phase")
	return true


func test_pip_integrity() -> bool:
	for id in range(21):
		var card := CardDatabase.get_card(id)
		var up: Array = card["upright_pips"]
		var rev: Array = card["reversed_pips"]
		var union: Array[int] = []
		for v in up:
			if not union.has(int(v)):
				union.append(int(v))
		for v in rev:
			if not union.has(int(v)):
				union.append(int(v))
		check_eq(union.size(), 6, "card %d pip union size" % id)
		check_eq(up.size() + rev.size(), 6, "card %d pip total" % id)
		for v in range(1, 7):
			check(union.has(v), "card %d covers %d" % [id, v])
		for v in up:
			check(not rev.has(v), "card %d pip disjoint %d" % [id, int(v)])
	return true


func test_roll_per_card_and_switch() -> bool:
	fresh()
	set_field([13, 17, 0])
	check_eq(gm.selected_slot, -1, "no card needs selecting to roll")
	roll(1)
	check_eq(str(gm.field_cards[0]["orientation"]), "REVERSED", "Death roll 1 is reversed")
	check_eq(str(gm.field_cards[1]["orientation"]), "UPRIGHT", "Tower roll 1 is upright")
	check_eq(str(gm.field_cards[2]["orientation"]), "UPRIGHT", "Fool roll 1 is upright")
	check_eq(int(gm.field_cards[0]["last_roll"]), 1, "Death last roll")
	check_eq(int(gm.field_cards[1]["last_roll"]), 1, "Tower last roll")
	select_slot(0)
	check_eq(str(gm.field_cards[1]["orientation"]), "UPRIGHT", "selecting does not change Tower")
	roll(4)
	check_eq(str(gm.field_cards[0]["orientation"]), "UPRIGHT", "reroll flips Death")
	check_eq(str(gm.field_cards[1]["orientation"]), "REVERSED", "reroll also flips Tower")
	check_eq(int(gm.field_cards[0]["last_roll"]), 4, "reroll updates Death roll")
	check_eq(int(gm.field_cards[1]["last_roll"]), 4, "reroll updates Tower roll")
	select_slot(2)
	check_eq(str(gm.field_cards[0]["orientation"]), "UPRIGHT", "switching keeps field results")
	return true


func test_accept_refuse_immediate() -> bool:
	fresh()
	set_field([5], "UPRIGHT")
	select_slot(0)
	gm.debug_accept()
	check_eq(int(gm.stats["passion"]), 3, "accept Hierophant passion -1")
	check_eq(int(gm.stats["intuition"]), 5, "accept Hierophant intuition +1")
	check(has_mark(5), "accept gains Hierophant mark")
	check_eq(gm.choices_completed, 1, "accept increments choices")
	check(str(gm.field_cards[0]["orientation"]) in ["UPRIGHT", "REVERSED"], "replacement is oriented")
	fresh()
	set_field([5], "UPRIGHT")
	select_slot(0)
	gm.debug_refuse()
	check_eq(int(gm.stats["comfort"]), 5, "refuse Hierophant comfort +1")
	check_eq(int(gm.stats["intuition"]), 3, "refuse Hierophant intuition -1")
	check(not has_mark(5), "refuse gives no mark")
	check_eq(gm.choices_completed, 1, "refuse increments choices")
	return true


func test_mark_on_acquire_tower() -> bool:
	fresh()
	set_field([17], "UPRIGHT")
	select_slot(0)
	gm.debug_accept()
	for key in STATS:
		check_eq(int(gm.stats[key]), 5, "Tower upright sets %s to 5" % key)
	check(has_mark(17), "Tower mark gained")
	fresh()
	gm.debug_set_stats(6, 4, 3, 5)
	set_field([17], "REVERSED")
	select_slot(0)
	gm.debug_accept()
	check_eq(int(gm.stats["passion"]), 5, "Tower reversed highest stat -2")
	check_eq(int(gm.stats["intuition"]), 5, "Tower reversed lowest stat +2")
	check_eq(int(gm.stats["curiosity"]), 3, "Tower reversed leaves middle stat")
	check_eq(int(gm.stats["comfort"]), 5, "Tower reversed leaves middle stat")
	check_eq(gm.phase, P_SELECT, "Tower reversed resolves without a choice prompt")
	return true


func test_every_three_trigger() -> bool:
	fresh()
	gm.debug_set_stats(4, 4, 4, 4)
	gm.debug_grant_mark(13, "reversed")
	gm.debug_set_choices(2)
	set_field([0], "UPRIGHT")
	select_slot(0)
	gm.debug_refuse()
	check_eq(gm.choices_completed, 3, "third choice reached")
	check_eq(int(gm.stats["passion"]), 4, "every3 Death reversed passion +1 after refuse")
	check_eq(int(gm.stats["intuition"]), 2, "every3 Death reversed intuition -1")
	check_eq(int(gm.stats["comfort"]), 5, "refuse Fool comfort +1")
	return true


func test_death_ends_run() -> bool:
	fresh()
	gm.debug_set_stats(1, 4, 4, 4)
	gm.debug_grant_mark(5, "upright")
	set_field([1], "UPRIGHT")
	select_slot(0)
	gm.debug_accept()
	check_eq(gm.phase, P_GAME_OVER, "death ends the run")
	check_eq(int(gm.stats["passion"]), 0, "death keeps the lethal value")
	check_eq(gm.marks.size(), 1, "death does not remove an existing mark")
	check(has_mark(5), "existing mark survives on the end screen")
	check(not has_mark(1), "new mark is not gained when death happens first")
	check_eq(gm.game_over_reason_key, "reason.death", "death reason")
	check(not gm.game_over_won, "death is not a world end")
	return true


func test_emperor_intercept() -> bool:
	fresh()
	gm.debug_set_stats(1, 4, 4, 4)
	gm.debug_grant_mark(4, "upright")
	set_field([1], "UPRIGHT")
	select_slot(0)
	gm.debug_accept()
	check_eq(gm.phase, P_SELECT, "upright Emperor prevents death")
	check_eq(int(gm.stats["passion"]), 1, "Emperor clamps to 1")
	check_eq(gm.get_mark_remaining(gm.marks[0]), "0/1", "Emperor once-per-run used")
	fresh()
	gm.debug_set_stats(1, 4, 4, 4)
	gm.debug_grant_mark(4, "reversed")
	set_field([1], "UPRIGHT")
	select_slot(0)
	gm.debug_accept()
	check_eq(gm.phase, P_SELECT, "reversed Emperor prevents death")
	check_eq(int(gm.stats["passion"]), 1, "reversed Emperor clamps")
	check_eq(int(gm.stats["intuition"]), 4, "reversed Emperor intuition -1 after Magician +1")
	return true


func test_mark_cap() -> bool:
	fresh()
	for id in [1, 2, 3, 5, 6]:
		gm.debug_grant_mark(id, "upright")
	set_field([0], "UPRIGHT")
	select_slot(0)
	gm.debug_accept()
	check(not gm.pending_new_mark.is_empty(), "sixth mark pending")
	check_eq(gm.pending_new_mark["card_id"], 0, "new mark is Fool")
	gm.replace_mark(1)
	check(has_mark(0), "replacement adds Fool")
	check(not has_mark(1), "replacement removes old mark")
	return true


func test_final_end() -> bool:
	fresh()
	gm.debug_set_choices(20)
	set_field([0], "UPRIGHT")
	select_slot(0)
	gm.debug_refuse()
	check_eq(gm.choices_completed, 21, "21st choice resolved")
	check_eq(gm.phase, P_GAME_OVER, "world ends the run")
	check_eq(gm.game_over_reason_key, "reason.world_end", "world end reason")
	check(gm.game_over_won, "world end is positive")
	return true


func test_effect_data() -> bool:
	var fool := CardDatabase.orientation_data(0, "upright")
	var refuse: Array = fool["refuse"]
	check_eq(refuse.size(), 3, "Fool upright refuse has three stats")
	var plus := false
	var minus := false
	for action in refuse:
		if int(action["delta"]) > 0:
			plus = true
		if int(action["delta"]) < 0:
			minus = true
	check(plus, "refuse has a plus")
	check(minus, "refuse has a minus")
	var devil := CardDatabase.orientation_data(15, "upright")
	check_eq(int(devil["accept"][0]["delta"]), 2, "Devil upright accept has +2")
	var every3: Dictionary = CardDatabase.orientation_data(1, "upright")["effects"][0]
	check_eq(every3["timing"], "every_3", "Magician every3 timing")
	check_eq(every3["rules"][0]["actions"][0]["type"], "shift_extremes", "Magician shift action")
	var fool_refuse: Dictionary = CardDatabase.orientation_data(0, "reversed")["effects"][1]["rules"][0]["actions"][0]
	check(not fool_refuse.has("floor"), "Fool -1 is not clamped to 1")
	var judgement_accept: Dictionary = CardDatabase.orientation_data(20, "reversed")["accept"][0]
	check(not judgement_accept.has("floor"), "Judgement -1 is not clamped to 1")
	return true


func test_split_flow_21() -> bool:
	fresh()
	var seen: Array[int] = []
	var guard := 0
	while gm.phase != P_GAME_OVER and guard < 800:
		guard += 1
		if gm.phase != P_SELECT:
			break
		var slot := -1
		for i in 3:
			if gm.field_cards[i] != null:
				slot = i
				break
		if slot < 0:
			break
		var runtime: Dictionary = gm.field_cards[slot]
		var card_id := int(runtime["card_id"])
		seen.append(card_id)
		gm.debug_set_stats(4, 4, 4, 4)
		select_slot(slot)
		roll(1)
		gm.debug_refuse()
	check(guard < 800, "21 split flow terminates")
	check_eq(gm.choices_completed, 21, "21 choices resolved")
	check_eq(seen.size(), 21, "21 cards selected")
	var unique: Array[int] = []
	for id in seen:
		if not unique.has(id):
			unique.append(id)
	check_eq(unique.size(), 21, "no card repeats")
	for id in range(21):
		check(unique.has(id), "card %d resolved" % id)
	check_eq(gm.deck.size(), 0, "deck emptied")
	check_eq(gm.phase, P_GAME_OVER, "run ended")
	for runtime in gm.field_cards:
		check(runtime == null, "field is empty at the end")
	return true


func test_upper_death() -> bool:
	fresh()
	gm.debug_set_stats(9, 4, 4, 4)
	gm.debug_set_field_card(0, 16, "REVERSED")
	select_slot(0)
	gm.debug_accept()
	check_eq(gm.phase, P_GAME_OVER, "upper-bound stat death")
	check_eq(int(gm.stats["passion"]), 10, "upper death keeps the lethal value")
	check_eq(gm.game_over_reason_key, "reason.death", "upper death reason")
	return true


func test_roll_cost_tradeoff() -> bool:
	fresh()
	gm.debug_set_roll_cost(true)
	var cost: Dictionary = gm.get_die_cost(3)
	check_eq(str(cost["plus"]), "curiosity", "die 3 raises curiosity")
	check_eq(str(cost["minus"]), "comfort", "die 3 lowers comfort")
	gm.debug_set_die(3)
	roll(1)
	check_eq(int(gm.stats["curiosity"]), 5, "clicking a die showing 3 raises curiosity")
	check_eq(int(gm.stats["comfort"]), 3, "clicking a die showing 3 lowers comfort")
	check_eq(int(gm.stats["passion"]), 4, "die 3 leaves passion")
	check_eq(int(gm.stats["intuition"]), 4, "die 3 leaves intuition")
	check_eq(int(gm.die_value), 1, "roll still sets the die")
	check_eq(gm.phase, P_SELECT, "roll cost does not end a safe run")
	return true


func test_new_mark_when_accept_excluded() -> bool:
	fresh()
	gm.debug_grant_mark(13, "upright")
	gm.debug_set_stats(4, 4, 4, 4)
	gm.debug_set_field_card(0, 7, "REVERSED")
	select_slot(0)
	gm.debug_accept()
	check(has_mark(7), "new Chariot mark is gained")
	check_eq(int(gm.stats["passion"]), 4, "new mark when-accept does not trigger this choice")
	check_eq(int(gm.stats["curiosity"]), 4, "existing Death when-accept balances extremes")
	return true
