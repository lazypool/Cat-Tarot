class_name Card3D
extends Node3D

signal clicked(card_id: int)
signal accept_pressed
signal refuse_pressed

const HOVER_LIFT := 0.12
const SELECT_LIFT := 0.3
const SELECT_SCALE := 1.08
const ICON_FIRE := "res://assets/icons/fire_color.png"
const ICON_EYE := "res://assets/icons/eye_color.png"
const ICON_STAR := "res://assets/icons/star_color.png"
const ICON_LEAVES := "res://assets/icons/leaves_color.png"
const ICON_TICK_WHITE := "res://assets/icons/tick_white.png"
const ICON_CROSS_WHITE := "res://assets/icons/cross_white.png"
const C_MUTED := Color(0.46, 0.36, 0.27, 1.0)
const C_READY := Color(0.24, 0.52, 0.29, 1.0)
const C_DANGER := Color(0.68, 0.22, 0.24, 1.0)
const STAT_ICON_PATHS := {
	"passion": ICON_FIRE,
	"intuition": ICON_EYE,
	"curiosity": ICON_STAR,
	"comfort": ICON_LEAVES,
}
const STAT_WORD_ICONS := [
	["Passion", ICON_FIRE],
	["Intuition", ICON_EYE],
	["Curiosity", ICON_STAR],
	["Comfort", ICON_LEAVES],
	["热情", ICON_FIRE],
	["直觉", ICON_EYE],
	["好奇", ICON_STAR],
	["安逸", ICON_LEAVES],
	["热", ICON_FIRE],
	["觉", ICON_EYE],
	["奇", ICON_STAR],
	["逸", ICON_LEAVES],
]

@onready var front: MeshInstance3D = $Front
@onready var back: MeshInstance3D = $Back
@onready var area: Area3D = $Area3D

var card_id: int = -1
var effect_text: String = ""
var hover_effect_text: String = ""
var base_position: Vector3 = Vector3.ZERO
var selected: bool = false
var dimmed: bool = false
var hovered: bool = false
var animation_locked: bool = false
var is_reversed: bool = false

var _material: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _move_tween: Tween
var _flip_tween: Tween
var _effect_viewport: SubViewport
var _effect_label: RichTextLabel
var _effect_sprite: Sprite3D
var _action_root: Node3D
var _accept_label: RichTextLabel
var _reject_label: RichTextLabel
var _accept_sprite: Sprite3D
var _reject_sprite: Sprite3D
var _accept_area: Area3D
var _reject_area: Area3D


func _ready() -> void:
	base_position = position
	_ensure_material()
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)


func setup(id: int, texture: Texture2D) -> void:
	card_id = id
	_ensure_material()
	selected = false
	dimmed = false
	hovered = false
	scale = Vector3.ONE
	base_position = position
	show_reversed(false)
	if texture != null:
		_material.albedo_texture = texture
		_base_color = Color.WHITE
	else:
		_material.albedo_texture = null
		_base_color = Color(0.34, 0.27, 0.42)
	_material.albedo_color = _base_color
	_apply_visual(false)


func set_hover_effect_text(text: String) -> void:
	hover_effect_text = text


func set_shadows_enabled(enabled: bool) -> void:
	front.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_effect_text(text: String) -> void:
	effect_text = text
	if text == "":
		if _effect_sprite != null:
			_effect_sprite.visible = false
		return
	_ensure_effect_display()
	_effect_label.text = _prevent_orphan_wrap(_replace_stat_words(text))
	_effect_sprite.visible = true


func _ensure_effect_display() -> void:
	if _effect_sprite != null:
		return
	_effect_viewport = SubViewport.new()
	_effect_viewport.size = Vector2i(640, 176)
	_effect_viewport.transparent_bg = true
	_effect_viewport.gui_disable_input = true
	_effect_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_effect_viewport)
	_effect_label = RichTextLabel.new()
	_effect_label.bbcode_enabled = true
	_effect_label.fit_content = false
	_effect_label.scroll_active = false
	_effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_richtext_tier(_effect_label, UiFonts.SIZE_CARD_EFFECT)
	_effect_viewport.add_child(_effect_label)
	_effect_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_effect_sprite = Sprite3D.new()
	_effect_sprite.texture = _effect_viewport.get_texture()
	_effect_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_effect_sprite.pixel_size = 0.00285
	_effect_sprite.position = Vector3(0.0, 1.505, 0.03)
	_effect_sprite.visible = false
	add_child(_effect_sprite)


func _prevent_orphan_wrap(bbcode: String) -> String:
	return (
		bbcode
		.replace("+ ", "+\u00A0")
		.replace("- ", "-\u00A0")
		.replace("<= ", "<=\u00A0")
		.replace(">= ", ">=\u00A0")
	)


func _replace_stat_words(text: String) -> String:
	var result := text
	for entry in STAT_WORD_ICONS:
		result = result.replace(str(entry[0]), "[img=32x32]%s[/img]" % str(entry[1]))
	return _format_delta_text(result)


func _format_delta_text(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("([+-])([0-9]+)")
	var result := ""
	var last := 0
	for m in regex.search_all(text):
		var start := m.get_start()
		if start > 0:
			var previous := text.substr(start - 1, 1)
			if previous in ["<", ">", "=", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-"]:
				continue
		result += text.substr(last, start - last)
		var number := m.get_string(2)
		result += ("+ " if m.get_string(1) == "+" else "- ") + number
		last = m.get_end()
	result += text.substr(last)
	return result


func show_actions(accept_actions: Array, refuse_actions: Array) -> void:
	_ensure_actions()
	_action_root.visible = true
	_accept_area.input_ray_pickable = true
	_reject_area.input_ray_pickable = true
	_accept_label.text = _actions_bbcode(accept_actions)
	_reject_label.text = _actions_bbcode(refuse_actions)


func hide_actions() -> void:
	if _action_root != null:
		_action_root.visible = false
		_accept_area.input_ray_pickable = false
		_reject_area.input_ray_pickable = false


func _ensure_actions() -> void:
	if _action_root != null:
		return
	_action_root = Node3D.new()
	_action_root.name = "Actions"
	add_child(_action_root)
	_accept_label = _make_action_preview(Vector3(-0.44, -1.42, 0.03))
	_reject_label = _make_action_preview(Vector3(0.44, -1.42, 0.03))
	_accept_sprite = _make_action_button(ICON_TICK_WHITE, Vector3(-0.38, -1.73, 0.04), true)
	_reject_sprite = _make_action_button(ICON_CROSS_WHITE, Vector3(0.38, -1.73, 0.04), false)


func _make_action_preview(pos: Vector3) -> RichTextLabel:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(280, 64)
	viewport.transparent_bg = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = false
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFonts.apply_richtext_tier(label, UiFonts.SIZE_CARD_ACTION)
	viewport.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sprite := Sprite3D.new()
	sprite.texture = viewport.get_texture()
	sprite.pixel_size = 0.0030
	sprite.position = pos
	_action_root.add_child(sprite)
	return label


func _make_action_button(icon_path: String, pos: Vector3, accepted: bool) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = load(icon_path) as Texture2D
	sprite.pixel_size = 0.003
	sprite.position = pos
	sprite.modulate = C_MUTED
	_action_root.add_child(sprite)
	var area := Area3D.new()
	area.position = pos
	area.input_ray_pickable = true
	_action_root.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.45, 0.45, 0.14)
	shape.shape = box
	area.add_child(shape)
	area.input_event.connect(_on_action_input.bind(accepted))
	area.mouse_entered.connect(_on_action_hover.bind(accepted, true))
	area.mouse_exited.connect(_on_action_hover.bind(accepted, false))
	if accepted:
		_accept_area = area
	else:
		_reject_area = area
	return sprite


func _on_action_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, accepted: bool) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if accepted:
				accept_pressed.emit()
			else:
				refuse_pressed.emit()


func _on_action_hover(accepted: bool, entered: bool) -> void:
	var sprite := _accept_sprite if accepted else _reject_sprite
	if sprite == null:
		return
	var hover_color := C_READY if accepted else C_DANGER
	sprite.modulate = hover_color if entered else C_MUTED


func _actions_bbcode(actions: Array) -> String:
	var parts: Array[String] = []
	for action in actions:
		var kind := str(action.get("type", ""))
		var delta := int(action.get("delta", 0))
		if kind == "stat":
			var stat := str(action.get("stat", ""))
			if STAT_ICON_PATHS.has(stat):
				parts.append("[img=22x22]%s[/img]%s" % [STAT_ICON_PATHS[stat], _delta_bbcode(delta)])
		elif kind == "all":
			var all_parts := ""
			for stat in ["passion", "intuition", "curiosity", "comfort"]:
				all_parts += "[img=22x22]%s[/img]%s" % [STAT_ICON_PATHS[stat], _delta_bbcode(delta)]
			parts.append(all_parts)
	if parts.is_empty():
		return "[center]—[/center]"
	return "[center]" + " ".join(parts) + "[/center]"


func _delta_bbcode(delta: int) -> String:
	if delta < 0:
		return "[color=#AD383D]- %d[/color]" % absi(delta)
	return "[color=#3D854A]+ %d[/color]" % delta


func set_state(orientation: String, animate: bool = true) -> void:
	show_reversed(orientation.to_upper() == "REVERSED", animate)


func set_back_visible(value: bool) -> void:
	front.visible = not value
	back.visible = true
	if _effect_sprite != null:
		_effect_sprite.visible = not value and effect_text != ""


func set_world_display() -> void:
	show_reversed(false)


func set_selected(value: bool) -> void:
	selected = value
	_apply_visual(true)


func set_dimmed(value: bool) -> void:
	dimmed = value
	_apply_visual(true)


func show_reversed(value: bool, animate: bool = true) -> void:
	is_reversed = value
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	var target := PI if value else 0.0
	if not animate:
		front.rotation.z = target
		back.rotation.z = target
		return
	_flip_tween = create_tween()
	_flip_tween.set_parallel(true)
	_flip_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(front, "rotation:z", target, 0.32)
	_flip_tween.tween_property(back, "rotation:z", target, 0.32)


func refresh_language() -> void:
	pass


func _ensure_material() -> void:
	if _material != null:
		return
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color.WHITE
	_material.roughness = 1.0
	front.material_override = _material


func _apply_visual(animate: bool) -> void:
	if animation_locked or _material == null:
		return
	var tint := Color.WHITE if not dimmed else Color(0.82, 0.79, 0.82)
	_material.albedo_color = _base_color * tint
	var lift := 0.0
	if selected:
		lift = SELECT_LIFT
	elif hovered and not dimmed:
		lift = HOVER_LIFT
	var target_position := Vector3(base_position.x, base_position.y + lift, base_position.z)
	var scale_value := 1.0
	if selected:
		scale_value = SELECT_SCALE
	elif hovered and not dimmed:
		scale_value = 1.03
	var target_scale := Vector3.ONE * scale_value
	if animate:
		if _move_tween != null and _move_tween.is_valid():
			_move_tween.kill()
		_move_tween = create_tween()
		_move_tween.set_parallel(true)
		_move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_move_tween.tween_property(self, "position", target_position, 0.16)
		_move_tween.tween_property(self, "scale", target_scale, 0.16)
	else:
		position = target_position
		scale = target_scale


func _on_mouse_entered() -> void:
	hovered = true
	_apply_visual(true)
	if hover_effect_text != "":
		set_effect_text(hover_effect_text)


func _on_mouse_exited() -> void:
	hovered = false
	_apply_visual(true)
	if hover_effect_text != "":
		set_effect_text("")


func _on_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			clicked.emit(card_id)
