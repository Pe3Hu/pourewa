class_name Barn
extends StaticBody2D


signal entered_door

@export var door: Area2D

var data: BarnData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
		_on_changed()


func _ready() -> void:
	collision_layer = Catalog.LAYER_BARN
	collision_mask = 0
	z_index = 60
	if data != null:
		_on_changed()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-24, -20), Vector2(48, 36)), Color(0.42, 0.28, 0.18))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28, -18), Vector2(0, -36), Vector2(28, -18),
	]), Color(0.55, 0.22, 0.18))
	if data == null:
		return
	var text := str(data.nectar)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, Vector2(-width * 0.5, 4), text, HORIZONTAL_ALIGNMENT_CENTER, width, 14, Color(0.95, 0.9, 0.7))


func _on_changed() -> void:
	if data == null:
		return
	position = data.position
	queue_redraw()
