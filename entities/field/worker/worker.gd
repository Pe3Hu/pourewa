class_name Worker
extends CharacterBody2D


signal picked(worker_: WorkerData)

@export var hit: Area2D
@export var shape: CollisionShape2D
@export var avoid: Area2D
@export var nav: NavigationAgent2D

var data: WorkerData:
	set(value_):
		data = value_
		if data != null:
			position = data.position
			data.driven = true
			if not data.changed.is_connected(_on_changed):
				data.changed.connect(_on_changed)
		_on_changed()


var is_selected: bool = false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	slide_on_ceiling = false
	floor_max_angle = 0.0
	_apply_mask()
	_prepare_nav()
	z_index = 800
	if data != null:
		data.driven = true
		_on_changed()


func _physics_process(delta_: float) -> void:
	if data == null:
		return
	var speed := Catalog.WORKER_SPEED * Catalog.speed_mult(data.speed_level)
	Route.follow(self, nav, data.aim, speed, avoid, delta_)
	data.position = global_position
	data.facing = rotation
	_hold_carried()


func _on_nav_velocity(safe_: Vector2) -> void:
	Route.apply_safe(self, safe_)
	if data == null:
		return
	data.position = global_position
	data.facing = rotation
	_hold_carried()


func apply_selected(is_selected_: bool) -> void:
	is_selected = is_selected_
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var color: Color = Digest.kind_to_color[data.kind]
	if data.kind == Bozo.Kind.HUNTER:
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -16), Vector2(14, 0), Vector2(0, 16), Vector2(-14, 0),
		]), color)
	elif data.kind == Bozo.Kind.COLLECTOR:
		draw_circle(Vector2.ZERO, 13.0, color)
		draw_circle(Vector2(0, 6), 7.0, color.darkened(0.25))
	else:
		draw_circle(Vector2.ZERO, 13.0, color)
		if data.kind == Bozo.Kind.MINER:
			draw_line(Vector2(6, -2), Vector2(16, -14), Color(0.35, 0.28, 0.22), 3.0, true)
	if data.kind == Bozo.Kind.MINER and data.deposit_id >= 0:
		var arc := Color(0.85, 0.75, 0.4)
		if Digest.matter_to_color.has(data.dig_matter):
			arc = Digest.matter_to_color[data.dig_matter]
		draw_arc(Vector2.ZERO, Catalog.WORKER_ARC, 0.0, TAU, 28, Color(arc.r, arc.g, arc.b, 0.25), 2.0, true)
		if data.click_ratio > 0.0:
			draw_arc(Vector2.ZERO, Catalog.WORKER_ARC, 0.0, TAU * data.click_ratio, 28, arc, 3.0, true)
	if is_selected:
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color(0.95, 0.95, 0.9), 2.0, true)
	var mark := "M"
	if data.kind == Bozo.Kind.GARDENER:
		mark = "G"
	elif data.kind == Bozo.Kind.HUNTER:
		mark = "H"
	elif data.kind == Bozo.Kind.COLLECTOR:
		mark = "C"
	var font := ThemeDB.fallback_font
	var size := 14
	var width := font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(-width * 0.5, size * 0.35), mark, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.08, 0.08, 0.08))


func _hold_carried() -> void:
	for child in get_children():
		if child is Shard or child is Fruit:
			child.global_position = global_position + data.carried_offset
			child.global_rotation = data.carried_angle
			if child is Shard:
				(child as Shard).collision_layer = 0
			elif child is Fruit:
				(child as Fruit).collision_layer = 0
			var obstacle := child.get_node_or_null("Obstacle") as NavigationObstacle2D
			if obstacle != null:
				obstacle.avoidance_enabled = false


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


func _apply_mask() -> void:
	collision_layer = Catalog.LAYER_WORKER
	collision_mask = Catalog.LAYER_SHARD
	if data != null:
		collision_mask = Catalog.mask_for_kind(data.kind)
	if avoid != null:
		avoid.collision_mask = Catalog.LAYER_WORKER | Catalog.LAYER_PEST


func _on_changed() -> void:
	if data == null:
		return
	_apply_mask()
	if not data.driven:
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
