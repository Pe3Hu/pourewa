class_name PestData
extends RefCounted


signal changed


var id: int = -1
var position: Vector2 = Vector2.ZERO
var hp: int = 10
var fruit_id: int = -1
var eat_clock: float = 0.0
var state: int = Bozo.PestState.CHASE
var patrol_clock: float = 0.0
var orbit_angle: float = 0.0
var orbit_radius: float = 70.0
var aim: Vector2 = Vector2.ZERO
var patrol_from: Vector2 = Vector2.ZERO
var patrol_to: Vector2 = Vector2.ZERO
var driven: bool = false
