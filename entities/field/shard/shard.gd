class_name Shard
extends StaticBody2D


signal clicked

@export var alpha: Polygon2D
@export var beta: Polygon2D
@export var gamma: Polygon2D
@export var hit: Area2D
@export var shape: CollisionPolygon2D

var data: ShardData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
		_on_changed()


var anchor: Vector2 = Vector2.ZERO
var is_selected: bool = false
var is_target: bool = false
var is_flying: bool = false
var flight: Tween


func _ready() -> void:
	alpha.polygon = Geometry.get_face_points(Bozo.Port.ALPHA)
	beta.polygon = Geometry.get_face_points(Bozo.Port.BETA)
	gamma.polygon = Geometry.get_face_points(Bozo.Port.GAMMA)
	shape.polygon = Geometry.get_silhouette()
	collision_layer = Catalog.LAYER_SHARD
	collision_mask = 0
	var body := get_node_or_null("Body") as CollisionShape2D
	if body != null and body.shape is CircleShape2D:
		(body.shape as CircleShape2D).radius = Catalog.SHARD_CIRCUMRADIUS
	if data != null:
		_on_changed()


func fly_to(target_world_: Vector2) -> void:
	is_flying = true
	z_index = Catalog.SELECT_Z - 1
	flight = create_tween()
	flight.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flight.tween_property(self, "position", target_world_ - anchor, Gear.fly[Gear.tempo])
	flight.finished.connect(_on_landed)


func apply_selected(is_selected_: bool) -> void:
	is_selected = is_selected_
	if is_flying:
		queue_redraw()
		return
	_place()


func apply_target(is_target_: bool) -> void:
	is_target = is_target_
	_sync_pick()


func _process(_delta: float) -> void:
	if data == null or is_flying or is_selected or not data.is_in_stack:
		return
	_apply_depth()


func _draw() -> void:
	if data == null:
		return
	if is_selected:
		var pts := Geometry.get_silhouette()
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(0.9, 1.0, 0.95, 0.95), 3.0, true)
	if data.shown_total >= 0:
		_draw_label(Bozo.Port.ALPHA, "=%d" % data.shown_total)
	_draw_label(Bozo.Port.BETA, "x%d" % int(Digest.matter_to_mult[data.matter]))
	_draw_label(Bozo.Port.GAMMA, "+%d" % data.volume)


func _exit_tree() -> void:
	if flight != null and flight.is_valid() and flight.is_running():
		flight.kill()


func _on_changed() -> void:
	if alpha == null or data == null:
		return
	if get_parent() is Worker or get_parent() is Thief:
		queue_redraw()
		return
	_paint(alpha, Bozo.Port.ALPHA)
	_paint(beta, Bozo.Port.BETA)
	_paint(gamma, Bozo.Port.GAMMA)
	_sync_pick()
	if not is_flying:
		_place()
	queue_redraw()


func _on_landed() -> void:
	is_flying = false
	flight = null
	_place()


func _on_input_event(viewport_: Viewport, event_: InputEvent, _shape_idx: int) -> void:
	if not hit.input_pickable:
		return
	if event_ is InputEventMouseButton and event_.pressed and event_.button_index == MOUSE_BUTTON_LEFT:
		viewport_.set_input_as_handled()
		clicked.emit()


func _on_mouse_entered() -> void:
	if hit.input_pickable:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	if hit.input_pickable:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _sync_pick() -> void:
	if hit == null or data == null:
		return
	var pick := not data.is_in_stack or is_target
	hit.input_pickable = pick
	hit.collision_layer = 1 if pick else 0


func _place() -> void:
	if data == null:
		return
	var lift := Catalog.SELECT_LIFT if is_selected else 0.0
	position = data.position - anchor - Vector2(0, lift)
	_apply_depth()
	queue_redraw()


func _apply_depth() -> void:
	if data == null:
		return
	if is_selected:
		z_index = Catalog.SELECT_Z
		return
	if is_flying or not data.is_in_stack:
		z_index = Catalog.WORLD_Z + 400
		return
	var depth := Catalog.WORLD_Z + int(global_position.y) + data.depth_bias
	z_index = clampi(depth, 1, Catalog.FOCUS_Z - 1)


func _paint(poly_: Polygon2D, port_: int) -> void:
	poly_.visible = true
	poly_.color = Geometry.get_matter_color(data.matter, port_)


func _draw_label(port_: int, text_: String) -> void:
	var font := ThemeDB.fallback_font
	var size := Catalog.LABEL_FONT_SIZE
	if text_.length() >= 4:
		size = 9
	var width := font.get_string_size(text_, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Geometry.get_face_center(port_) - Vector2(width * 0.5, -size * 0.35)
	draw_string(font, pos + Vector2(1, 1), text_, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(1, 1, 1, 0.45))
	draw_string(font, pos, text_, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.08, 0.08, 0.08, 0.95))
