class_name Tower
extends StaticBody2D


var data: TowerData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
		_on_changed()


func _ready() -> void:
	collision_layer = Catalog.LAYER_TOWER
	collision_mask = 0
	z_index = 90
	if data != null:
		_on_changed()


func _draw() -> void:
	if data == null:
		return
	var ring := Color(0.9, 0.85, 0.55, 0.55 if data.durability > 0 else 0.2)
	draw_arc(Vector2.ZERO, data.radius(), 0.0, TAU, 64, ring, 1.5, true)
	draw_rect(Rect2(Vector2(-12, -8), Vector2(24, 26)), Color(0.38, 0.4, 0.44))
	draw_rect(Rect2(Vector2(-7, -22), Vector2(14, 16)), Color(0.55, 0.58, 0.62))
	var text := str(data.durability)
	var font := ThemeDB.fallback_font
	var size := 12
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(-width * 0.5, 6), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.95, 0.95, 0.9))


func _on_changed() -> void:
	if data == null:
		return
	position = data.position
	queue_redraw()
