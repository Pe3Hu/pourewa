class_name Pest
extends CharacterBody2D


@export var avoid: Area2D
@export var nav: NavigationAgent2D

var data: PestData:
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
	collision_mask = Catalog.mask_for_pest()
	if avoid != null:
		avoid.collision_mask = Catalog.LAYER_WORKER | Catalog.LAYER_PEST
	_prepare_nav()
	z_index = 860
	if data != null:
		data.driven = true
		position = data.position


func _physics_process(delta_: float) -> void:
	if data == null:
		return
	if data.state == Bozo.PestState.IDLE:
		velocity = Vector2.ZERO
		return
	Route.follow(self, nav, data.aim, Catalog.PEST_SPEED, avoid, delta_)
	data.position = global_position


func _on_nav_velocity(safe_: Vector2) -> void:
	Route.apply_safe(self, safe_)
	if data != null:
		data.position = global_position


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
	draw_circle(Vector2.ZERO, Catalog.PEST_RADIUS, Color(0.16, 0.12, 0.14))
	draw_circle(Vector2(-4, -3), 2.0, Color(0.9, 0.25, 0.2))
	draw_circle(Vector2(4, -3), 2.0, Color(0.9, 0.25, 0.2))
	var text := str(data.hp)
	var font := ThemeDB.fallback_font
	var size := 11
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(-width * 0.5, 12), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.95, 0.9, 0.9))


func _on_changed() -> void:
	if data == null:
		return
	if not data.driven:
		position = data.position
	queue_redraw()
