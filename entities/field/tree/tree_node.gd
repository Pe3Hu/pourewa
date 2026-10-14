class_name TreeNode
extends StaticBody2D


var data: TreeNodeData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
		_on_changed()


func _ready() -> void:
	collision_layer = Catalog.LAYER_TREE
	collision_mask = 0
	z_index = 70
	if data != null:
		_on_changed()


func _draw() -> void:
	if data == null:
		return
	draw_rect(Rect2(Vector2(-4, -2), Vector2(8, 28)), Color(0.38, 0.24, 0.14))
	var canopy := Color(0.2, 0.55, 0.28)
	if data.value <= 0:
		canopy = Color(0.35, 0.38, 0.3)
	draw_circle(Vector2(0, -16), 22.0, canopy)
	var text := str(data.value)
	var font := ThemeDB.fallback_font
	var size := 14
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(-width * 0.5, -10), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.95, 0.95, 0.9))


func _on_changed() -> void:
	if data == null:
		return
	position = data.position
	queue_redraw()
