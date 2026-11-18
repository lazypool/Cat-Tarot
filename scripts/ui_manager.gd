extends CanvasLayer

const C_PANEL := Color(1.0, 0.92, 0.80, 0.96)
const C_BORDER := Color(0.64, 0.43, 0.24, 0.95)
const C_TEXT := Color(0.27, 0.18, 0.12, 1.0)
const C_GOLD := Color(0.63, 0.39, 0.12, 1.0)
const C_DANGER := Color(0.68, 0.22, 0.24, 1.0)

const ICON_CAT := "res://assets/icons/cat.png"
const ICON_FIRE := "res://assets/icons/fire.png"
const ICON_EYE := "res://assets/icons/eye.png"
const ICON_STAR := "res://assets/icons/star.png"
const ICON_LEAVES := "res://assets/icons/leaves.png"

const STAT_ORDER: Array[String] = ["passion", "intuition", "curiosity", "comfort"]
const STAT_ICONS := {
	"passion": ICON_FIRE,
	"intuition": ICON_EYE,
	"curiosity": ICON_STAR,
	"comfort": ICON_LEAVES,
}
const STAT_COLORS := {
	"passion": Color(0.84, 0.27, 0.32),
	"intuition": Color(0.29, 0.47, 0.82),
	"curiosity": Color(0.72, 0.55, 0.12),
	"comfort": Color(0.24, 0.58, 0.43),
}

var root: Control
var stat_values: Dictionary = {}
var stat_fills: Dictionary = {}
var stat_boxes: Dictionary = {}


func _ready() -> void:
	_build_ui()
	GameManager.state_changed.connect(_refresh)
	GameManager.game_started.connect(_on_game_started)
	Loc.language_changed.connect(_refresh)
	_refresh()


func _build_ui() -> void:
	root = Control.new()
	root.name = "UIRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiFonts.build_ui_theme(UiFonts.SIZE_HUD)
	add_child(root)

	var top_bar := _panel()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_bar.position = Vector2(16.0, 10.0)
	root.add_child(top_bar)
	var top_box := HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 12)
	top_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(top_box)
	top_box.add_child(_icon(ICON_CAT, 26, C_GOLD))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_box.add_child(stats)
	for key in STAT_ORDER:
		_add_stat_widget(stats, key)
	top_bar.reset_size()


func _add_stat_widget(parent: HBoxContainer, key: String) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.tooltip_text = Loc.stat_name(key)
	stat_boxes[key] = box
	parent.add_child(box)
	box.add_child(_icon(STAT_ICONS[key], 20, STAT_COLORS[key]))
	var value_box := VBoxContainer.new()
	value_box.add_theme_constant_override("separation", 0)
	box.add_child(value_box)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", UiFonts.SIZE_HUD)
	value.add_theme_color_override("font_color", C_TEXT)
	value_box.add_child(value)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(58, 6)
	value_box.add_child(bar)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.14, 0.1, 0.25)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg)
	var fill := ColorRect.new()
	fill.color = STAT_COLORS[key]
	fill.position = Vector2.ZERO
	fill.size = Vector2(0, 6)
	bar.add_child(fill)
	stat_values[key] = value
	stat_fills[key] = fill


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_color = C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.25, 0.14, 0.07, 0.2)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _icon(path: String, size: int, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(path) as Texture2D
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _refresh() -> void:
	if root == null:
		return
	_refresh_stats()


func _refresh_stats() -> void:
	for key in STAT_ORDER:
		if stat_boxes.has(key):
			(stat_boxes[key] as Control).tooltip_text = Loc.stat_name(key)
		var value := int(GameManager.stats[key])
		stat_values[key].text = str(value)
		var color: Color = C_DANGER if value <= 1 or value >= 9 else STAT_COLORS[key]
		stat_values[key].add_theme_color_override("font_color", color)
		var fill: ColorRect = stat_fills[key]
		fill.color = color
		fill.size = Vector2(58.0 * clampf(float(value) / 10.0, 0.0, 1.0), 6)


func _on_game_started(_seed: int) -> void:
	_refresh()
