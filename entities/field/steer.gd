class_name Steer
extends RefCounted


static func slide(body_: CharacterBody2D, aim_: Vector2, speed_: float, sensor_: Area2D) -> void:
	var velocity := plan(body_, aim_, speed_, sensor_)
	body_.velocity = velocity
	if velocity.length() > 4.0:
		body_.rotation = velocity.angle()
	body_.move_and_slide()


static func plan(body_: CharacterBody2D, aim_: Vector2, speed_: float, sensor_: Area2D) -> Vector2:
	var offset := aim_ - body_.global_position
	if offset.length() <= 0.01:
		return Vector2.ZERO
	var push := _push(body_, sensor_)
	if body_.velocity.length() < 8.0:
		push *= 0.2
	if offset.length() < Catalog.NEAR_AIM:
		push *= 0.3
	var mixed := offset.normalized() + push * Catalog.AVOID_WEIGHT
	if mixed.length_squared() <= 0.0001:
		return Vector2.ZERO
	return mixed.normalized() * speed_


static func _push(body_: CharacterBody2D, sensor_: Area2D) -> Vector2:
	var push := Vector2.ZERO
	if sensor_ == null:
		return push
	var span := Catalog.AVOID_OUTER - Catalog.AVOID_INNER
	for other in sensor_.get_overlapping_bodies():
		if other == body_:
			continue
		var away: Vector2 = body_.global_position - other.global_position
		var dist := away.length()
		if dist >= Catalog.AVOID_OUTER:
			continue
		if dist < 0.01:
			push += Vector2.RIGHT
			continue
		var weight := clampf((Catalog.AVOID_OUTER - dist) / span, 0.0, 1.0)
		push += away.normalized() * weight
	return push
