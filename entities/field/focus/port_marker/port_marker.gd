class_name PortMarker
extends Node2D


signal picked(move_: Move)

@export var fill: Polygon2D
@export var line: Line2D
@export var hit: Area2D
@export var shape: CollisionPolygon2D

var data: Move:
	set(value_):
		data = value_
		_apply_move()


var is_hot: bool = false


func _ready() -> void:
	if data != null:
		_apply_move()


func _process(_delta: float) -> void:
	if fill == null or data == null:
		return
	var wave := sin(float(Time.get_ticks_msec()) / 180.0)
	var pulse := 0.5 + 0.5 * wave
	var alpha := lerpf(0.22, 0.5, pulse)
	if is_hot:
		alpha = minf(alpha + 0.3, 0.85)
		line.width = 4.5
	else:
		line.width = 3.0
	var color := fill.color
	color.a = alpha
	fill.color = color


func _apply_move() -> void:
	if fill == null or data == null:
		return
	position = data.target_pos
	z_index = 1
	var pts := Geometry.get_face_points(data.port)
	fill.polygon = pts
	line.points = pts
	shape.polygon = pts
	var edge: Color = Digest.port_to_highlight[data.port]
	fill.color = Color(edge.r, edge.g, edge.b, 0.35)
	line.default_color = edge


func _on_mouse_entered() -> void:
	is_hot = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	is_hot = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_input_event(viewport_: Viewport, event_: InputEvent, _shape_idx: int) -> void:
	if event_ is InputEventMouseButton and event_.pressed and event_.button_index == MOUSE_BUTTON_LEFT:
		viewport_.set_input_as_handled()
		picked.emit(data)
