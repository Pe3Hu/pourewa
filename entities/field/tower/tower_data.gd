class_name TowerData
extends RefCounted


signal changed


var id: int = -1
var stack_id: int = -1
var position: Vector2 = Vector2.ZERO
var value: int = 0
var durability: int = 0
var clock: float = 0.0


func radius() -> float:
	return float(value) * Catalog.RADIUS_PER_VALUE
