class_name Geometry
extends RefCounted


static func get_face_points(port_: int) -> PackedVector2Array:
	var w := Catalog.CARD_W
	var t := Catalog.CARD_TOP_H
	var b := Catalog.CARD_BODY_H
	match port_:
		Bozo.Port.ALPHA:
			return PackedVector2Array([
				Vector2(0, -b * 0.5 - t * 0.5),
				Vector2(w * 0.5, -b * 0.5),
				Vector2(0, -b * 0.5 + t * 0.5),
				Vector2(-w * 0.5, -b * 0.5),
			])
		Bozo.Port.BETA:
			return PackedVector2Array([
				Vector2(0, -b * 0.5 + t * 0.5),
				Vector2(w * 0.5, -b * 0.5),
				Vector2(w * 0.5, b * 0.5),
				Vector2(0, b * 0.5 + t * 0.5),
			])
		Bozo.Port.GAMMA:
			return PackedVector2Array([
				Vector2(-w * 0.5, -b * 0.5),
				Vector2(0, -b * 0.5 + t * 0.5),
				Vector2(0, b * 0.5 + t * 0.5),
				Vector2(-w * 0.5, b * 0.5),
			])
		_:
			return PackedVector2Array()


static func get_silhouette() -> PackedVector2Array:
	var w := Catalog.CARD_W
	var t := Catalog.CARD_TOP_H
	var b := Catalog.CARD_BODY_H
	return PackedVector2Array([
		Vector2(0, -b * 0.5 - t * 0.5),
		Vector2(w * 0.5, -b * 0.5),
		Vector2(w * 0.5, b * 0.5),
		Vector2(0, b * 0.5 + t * 0.5),
		Vector2(-w * 0.5, b * 0.5),
		Vector2(-w * 0.5, -b * 0.5),
	])


static func contains_point(polygon_: PackedVector2Array, point_: Vector2) -> bool:
	var inside := false
	var count := polygon_.size()
	var previous := count - 1
	for index in count:
		var current := polygon_[index]
		var prior := polygon_[previous]
		var crosses := (current.y > point_.y) != (prior.y > point_.y)
		if crosses:
			var x_at_y := (prior.x - current.x) * (point_.y - current.y) / (prior.y - current.y) + current.x
			if point_.x < x_at_y:
				inside = not inside
		previous = index
	return inside


static func get_face_center(port_: int) -> Vector2:
	var pts := get_face_points(port_)
	if pts.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in pts:
		sum += point
	return sum / float(pts.size())


static func get_offset(port_: int) -> Vector2:
	match port_:
		Bozo.Port.ALPHA:
			return Catalog.OFFSET_ALPHA
		Bozo.Port.BETA:
			return Catalog.OFFSET_BETA
		Bozo.Port.GAMMA:
			return Catalog.OFFSET_GAMMA
		_:
			return Vector2.ZERO


static func get_shard_aabb(center_: Vector2) -> Rect2:
	var half := Vector2(Catalog.CARD_W * 0.5, Catalog.CARD_HALF_H)
	return Rect2(center_ - half, half * 2.0)


static func get_matter_color(matter_: int, port_: int) -> Color:
	var base: Color = Digest.matter_to_color[matter_]
	var scale: float = Digest.port_to_brightness[port_]
	return Color(base.r * scale, base.g * scale, base.b * scale, 1.0)
