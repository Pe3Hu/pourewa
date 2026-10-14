class_name Thief
extends CharacterBody2D


@export var avoid: Area2D
@export var nav: NavigationAgent2D

var data: ThiefData:
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
	slide_on_ceiling = false
	floor_max_angle = 0.0
	collision_layer = Catalog.LAYER_PEST
	collision_mask = Catalog.mask_for_thief()
	if avoid != null:
		avoid.collision_mask = Catalog.LAYER_WORKER | Catalog.LAYER_PEST
	_prepare_nav()
	z_index = 880
	if data != null:
		data.driven = true
		position = data.position


func _physics_process(delta_: float) -> void:
	if data == null:
		return
	Route.follow(self, nav, data.aim, Catalog.PEST_SPEED, avoid, delta_)
	data.position = global_position
	data.facing = rotation
	for child in get_children():
		if child is Fruit:
			child.global_position = global_position + data.carried_offset
			child.global_rotation = 0.0
			(child as Fruit).collision_layer = 0
			var obstacle := child.get_node_or_null("Obstacle") as NavigationObstacle2D
			if obstacle != null:
				obstacle.avoidance_enabled = false


func _on_nav_velocity(safe_: Vector2) -> void:
	Route.apply_safe(self, safe_)
	if data == null:
		return
	data.position = global_position
	data.facing = rotation
	for child in get_children():
		if child is Fruit:
			child.global_position = global_position + data.carried_offset
			child.global_rotation = 0.0


func _prepare_nav() -> void:
	if nav == null:
		return
	nav.path_desired_distance = 8.0
	nav.target_desired_distance = 16.0
	nav.avoidance_enabled = true
	nav.radius = Catalog.BODY_RADIUS
	nav.neighbor_distance = 80.0
	nav.max_neighbors = 8
	nav.time_horizon_agents = 1.0
	nav.time_horizon_obstacles = 1.0
	if not nav.velocity_computed.is_connected(_on_nav_velocity):
		nav.velocity_computed.connect(_on_nav_velocity)


func _draw() -> void:
	if data == null:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -14), Vector2(12, 8), Vector2(-12, 8),
	]), Color(0.45, 0.18, 0.55))
	var text := str(data.hp)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11).x
	draw_string(font, Vector2(-width * 0.5, 4), text, HORIZONTAL_ALIGNMENT_CENTER, width, 11, Color(0.95, 0.9, 0.95))


func _on_changed() -> void:
	if data == null:
		return
	if not data.driven:
		position = data.position
	queue_redraw()
