class_name Route
extends RefCounted


static func follow(body_: CharacterBody2D, nav_: NavigationAgent2D, aim_: Vector2, speed_: float, sensor_: Area2D, delta_: float) -> void:
	if body_.global_position.distance_to(aim_) <= Catalog.ARRIVE_RADIUS:
		body_.velocity = Vector2.ZERO
		body_.move_and_slide()
		return
	var direct: float = float(body_.get_meta("route_direct", 0.0))
	var stuck: float = float(body_.get_meta("route_stuck", 0.0))
	var last: Vector2 = body_.get_meta("route_last", body_.global_position)
	var sent: Vector2 = body_.get_meta("route_sent", Vector2.INF)
	if nav_ != null and (sent == Vector2.INF or sent.distance_to(aim_) > 4.0):
		nav_.target_position = aim_
		sent = aim_
	var moved := body_.global_position.distance_to(last)
	if moved < 1.0 and body_.global_position.distance_to(aim_) > Catalog.ARRIVE_RADIUS:
		stuck += delta_
	else:
		stuck = 0.0
	if stuck >= Gear.route_stuck[Gear.tempo]:
		stuck = 0.0
		direct = Gear.route_direct[Gear.tempo]
		if nav_ != null:
			nav_.target_position = aim_
	if direct > 0.0:
		direct = maxf(direct - delta_, 0.0)
	body_.set_meta("route_direct", direct)
	body_.set_meta("route_stuck", stuck)
	body_.set_meta("route_last", body_.global_position)
	body_.set_meta("route_sent", sent)
	var next := aim_
	var straight := direct > 0.0 or nav_ == null or not _map_ready(body_)
	if not straight and nav_.is_navigation_finished():
		if body_.global_position.distance_to(aim_) > Catalog.ARRIVE_RADIUS:
			body_.set_meta("route_direct", Gear.route_direct[Gear.tempo])
			straight = true
	elif not straight:
		next = nav_.get_next_path_position()
	var desired := Steer.plan(body_, next, speed_, sensor_)
	if straight or nav_ == null:
		body_.velocity = desired
		if desired.length() > 4.0:
			body_.rotation = desired.angle()
		body_.move_and_slide()
		return
	nav_.avoidance_enabled = true
	nav_.velocity = desired


static func apply_safe(body_: CharacterBody2D, safe_: Vector2) -> void:
	if safe_.length() > 4.0:
		body_.rotation = safe_.angle()
	body_.velocity = safe_
	body_.move_and_slide()


static func _map_ready(body_: CharacterBody2D) -> bool:
	var map: RID = body_.get_world_2d().navigation_map
	return NavigationServer2D.map_get_iteration_id(map) > 0
