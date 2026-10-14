class_name ShardData
extends RefCounted


signal changed


var id: int = -1
var matter: int = Bozo.Matter.NONE
var volume: int = 0
var multiplier: int = 0
var is_in_stack: bool = false
var stack_id: int = -1
var parent_id: int = -1
var attached_port: int = Bozo.Port.NONE
var position: Vector2 = Vector2.ZERO
var open_ports: Array[int] = []
var depth_bias: int = 0
var shown_total: int = -1
var claim_id: int = -1


func _init(id_: int, matter_: int, volume_: int) -> void:
	id = id_
	matter = matter_
	volume = volume_


func is_port_open(port_: int) -> bool:
	return open_ports.has(port_)


func close_port(port_: int) -> void:
	var index := open_ports.find(port_)
	if index < 0:
		return
	open_ports.remove_at(index)
	changed.emit()


func apply_total(total_: int) -> void:
	if shown_total == total_:
		return
	shown_total = total_
	changed.emit()
