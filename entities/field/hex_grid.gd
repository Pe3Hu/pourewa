class_name HexGrid
extends RefCounted


const MAX_LAYER := 5

const _SECTORS: Array[int] = [Bozo.Sector.SWAMP, Bozo.Sector.JUNGLE, Bozo.Sector.MOUNTAIN]


static func axial_to_world(q_: int, r_: int) -> Vector2:
	var size := Catalog.HEX_SIZE
	var x := size * (sqrt(3.0) * q_ + sqrt(3.0) * 0.5 * r_)
	var y := size * (1.5 * r_)
	return Vector2(x, y)


static func world_to_axial(pos_: Vector2) -> Vector2i:
	var size := Catalog.HEX_SIZE
	var q := (sqrt(3.0) / 3.0 * pos_.x - 1.0 / 3.0 * pos_.y) / size
	var r := (2.0 / 3.0 * pos_.y) / size
	return _cube_round(q, r)


static func hexes_in_layer(layer_: int) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	if layer_ <= 0:
		return hexes
	var dirs := _dirs()
	var hex := dirs[4] * layer_
	for side in 6:
		for _step in layer_:
			hexes.append(hex)
			hex += dirs[side]
	return hexes


static func sector_of(hex_: Vector2i, layer_: int) -> int:
	var index := _ring_index(hex_, layer_)
	if index < 0 or _is_border(index, layer_):
		return -1
	return _SECTORS[index / _block(layer_)]


static func index_in_sector(hex_: Vector2i, layer_: int) -> int:
	var index := _ring_index(hex_, layer_)
	if index < 0 or _is_border(index, layer_):
		return -1
	return index % _block(layer_)


static func _ring_index(hex_: Vector2i, layer_: int) -> int:
	if layer_ <= 0:
		return -1
	return hexes_in_layer(layer_).find(hex_)


static func _is_border(index_: int, layer_: int) -> bool:
	return index_ % _block(layer_) >= layer_ + 1


static func _block(layer_: int) -> int:
	return (layer_ + 1) + (layer_ - 1)


static func _dirs() -> Array[Vector2i]:
	return [
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
	]


static func _cube_round(q_: float, r_: float) -> Vector2i:
	var s_ := -q_ - r_
	var rq := roundi(q_)
	var rr := roundi(r_)
	var rs := roundi(s_)
	var dq := absf(rq - q_)
	var dr := absf(rr - r_)
	var ds := absf(rs - s_)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(rq, rr)
