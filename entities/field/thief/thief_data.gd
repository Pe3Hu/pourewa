class_name ThiefData
extends RefCounted


signal changed


var id: int = -1
var position: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO
var hp: int = 15
var state: int = Bozo.ThiefState.TO_BARN
var carry_fruit_id: int = -1
var carried_offset: Vector2 = Vector2.ZERO
var facing: float = 0.0
var driven: bool = false
