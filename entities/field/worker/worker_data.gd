class_name WorkerData
extends RefCounted


signal changed


var id: int = -1
var kind: int = Bozo.Kind.NONE
var position: Vector2 = Vector2.ZERO
var home: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO
var duty: int = Bozo.Duty.IDLE
var deposit_id: int = -1
var target_shard_id: int = -1
var target_fruit_id: int = -1
var intent_stack_id: int = -1
var intent_port: int = Bozo.Port.NONE
var carry_id: int = -1
var carry_fruit_id: int = -1
var carried_offset: Vector2 = Vector2.ZERO
var carried_angle: float = 0.0
var facing: float = 0.0
var building_id: int = -1
var speed_level: int = 0
var click_clock: float = 0.0
var click_ratio: float = 0.0
var dig_matter: int = Bozo.Matter.NONE
var driven: bool = false
