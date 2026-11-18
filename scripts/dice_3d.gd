class_name Dice3D
extends Node3D

signal roll_finished(value: int)
signal clicked

const ICON_FIRE := "res://assets/icons/fire_color.png"
const ICON_EYE := "res://assets/icons/eye_color.png"
const ICON_STAR := "res://assets/icons/star_color.png"
const ICON_LEAVES := "res://assets/icons/leaves_color.png"
const STAT_ICONS := {
	"passion": ICON_FIRE,
	"intuition": ICON_EYE,
	"curiosity": ICON_STAR,
	"comfort": ICON_LEAVES,
}

const FACE_NORMALS := {
	1: Vector3.UP,
	2: Vector3(0.0, 0.0, 1.0),
	3: Vector3(1.0, 0.0, 0.0),
	4: Vector3(-1.0, 0.0, 0.0),
	5: Vector3(0.0, 0.0, -1.0),
	6: Vector3.DOWN,
}

@onready var area: Area3D = $Area3D
@onready var pivot: Node3D = $Pivot

var _spin_tween: Tween
var _hop_tween: Tween
var _roll_id: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cost_sprite: Sprite3D
var _cost_label: RichTextLabel


func _ready() -> void:
	_rng.randomize()
	_set_face(1, 0.0)
	area.input_event.connect(_on_input_event)
	_create_cost_label()
	_update_cost_label(1)


func _create_cost_label() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 96)
	viewport.transparent_bg = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	_cost_label = RichTextLabel.new()
	_cost_label.bbcode_enabled = true
	_cost_label.fit_content = false
	_cost_label.scroll_active = false
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFonts.apply_richtext_tier(_cost_label, UiFonts.SIZE_DIE_COST)
	viewport.add_child(_cost_label)
	_cost_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cost_sprite = Sprite3D.new()
	_cost_sprite.texture = viewport.get_texture()
	_cost_sprite.pixel_size = 0.0030
	_cost_sprite.position = Vector3(0.36, -0.33, -1.0)
	_cost_sprite.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_cost_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_cost_sprite)


func _update_cost_label(value: int) -> void:
	if _cost_label == null:
		return
	var cost := GameManager.get_die_cost(value)
	var plus_stat := str(cost["plus"])
	var minus_stat := str(cost["minus"])
	_cost_label.text = "[center][img=34x34]%s[/img][color=#3D854A]+ 1[/color]  [img=34x34]%s[/img][color=#AD383D]- 1[/color][/center]" % [
		STAT_ICONS[plus_stat],
		STAT_ICONS[minus_stat],
	]


func roll_to(value: int) -> void:
	_roll_id += 1
	_update_cost_label(value)
	var current_id := _roll_id
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()
	if _hop_tween != null and _hop_tween.is_valid():
		_hop_tween.kill()
	pivot.position = Vector3.ZERO
	var yaw := _rng.randf_range(-PI, PI)
	var align := Quaternion(FACE_NORMALS.get(value, Vector3.UP) as Vector3, Vector3.UP)
	var target_rotation := (Quaternion(Vector3.UP, yaw) * align).get_euler()
	_spin_tween = create_tween()
	_spin_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spin_tween.tween_property(pivot, "rotation", target_rotation + Vector3(TAU * 2.0, TAU * 2.0, TAU * 2.0), 0.78)
	_hop_tween = create_tween()
	_hop_tween.set_trans(Tween.TRANS_QUAD)
	_hop_tween.tween_property(pivot, "position", Vector3(0.0, 0.38, 0.0), 0.30).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(pivot, "position", Vector3.ZERO, 0.48).set_ease(Tween.EASE_IN)
	_spin_tween.finished.connect(func() -> void:
		if current_id != _roll_id:
			return
		pivot.rotation = target_rotation
		pivot.position = Vector3.ZERO
		roll_finished.emit(value)
	)


func reset(value: int = 1) -> void:
	_roll_id += 1
	_update_cost_label(value)
	if _spin_tween != null and _spin_tween.is_valid():
		_spin_tween.kill()
	if _hop_tween != null and _hop_tween.is_valid():
		_hop_tween.kill()
	pivot.position = Vector3.ZERO
	_set_face(value, 0.0)


func current_face() -> int:
	var best_value := 1
	var best_dot := -2.0
	for value in FACE_NORMALS:
		var world_normal: Vector3 = pivot.global_transform.basis * (FACE_NORMALS[value] as Vector3)
		var dot: float = world_normal.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_value = value
	return best_value


func _set_face(value: int, yaw: float) -> void:
	var align := Quaternion(FACE_NORMALS.get(value, Vector3.UP) as Vector3, Vector3.UP)
	pivot.rotation = (Quaternion(Vector3.UP, yaw) * align).get_euler()


func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			clicked.emit()
