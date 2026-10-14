class_name Fruit
extends StaticBody2D


signal picked(fruit_: FruitData)

@export var hit: Area2D
@export var shape: CollisionShape2D

var data: FruitData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
		_on_changed()


func _ready() -> void:
	var circle := shape.shape as CircleShape2D
	if circle != null:
		circle.radius = Catalog.FRUIT_RADIUS
	collision_layer = Catalog.LAYER_FRUIT
	collision_mask = 0
	z_index = 760
	if data != null:
		_on_changed()


func _draw() -> void:
	if data == null:
		return
	draw_circle(Vector2.ZERO, Catalog.FRUIT_RADIUS, Color(0.86, 0.28, 0.32))
	var text := str(data.hp)
	var font := ThemeDB.fallback_font
	var size := 12
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(-width * 0.5, size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.1, 0.05, 0.05))


func _on_changed() -> void:
	if data == null:
		return
	if get_parent() is Worker or get_parent() is Thief:
		queue_redraw()
		return
	position = data.position
	queue_redraw()


func _on_input_event(viewport_: Viewport, event_: InputEvent, _shape_idx: int) -> void:
	if event_ is InputEventMouseButton and event_.pressed and event_.button_index == MOUSE_BUTTON_LEFT:
		viewport_.set_input_as_handled()
		picked.emit(data)


func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
