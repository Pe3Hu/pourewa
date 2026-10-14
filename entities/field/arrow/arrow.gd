class_name Arrow
extends CharacterBody2D


var data: ArrowData:
	set(value_):
		data = value_
		if data != null:
			position = data.position
			data.driven = true
			if not data.changed.is_connected(_on_changed):
				data.changed.connect(_on_changed)
		_on_changed()


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 0
	z_index = 1100
	if data != null:
		data.driven = true
		position = data.position


func _physics_process(_delta: float) -> void:
	if data == null:
		return
	Steer.slide(self, data.aim, Catalog.ARROW_SPEED, null)
	data.position = global_position
	data.angle = rotation


func _draw() -> void:
	if data == null:
		return
	var tail := Vector2(-12, 0).rotated(data.angle)
	draw_line(tail, Vector2.ZERO, Color(0.95, 0.9, 0.55), 2.5, true)


func _on_changed() -> void:
	if data == null:
		return
	if not data.driven:
		position = data.position
	queue_redraw()
