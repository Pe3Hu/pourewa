class_name StackData
extends RefCounted


signal shard_added(shard_: ShardData, from_: Vector2)
signal changed


var id: int = -1
var origin: Vector2 = Vector2.ZERO
var shards: Array[ShardData] = []
var total: int = 0
var matter: int = Bozo.Matter.NONE
var multiplier: int = 0
var alpha_sum: int = 0
var beta_multiplier: int = 0
var crown: int = 0
var is_locked: bool = false
var beta_used: bool = false
var element: int = Bozo.Element.NONE
var root_from: Vector2 = Vector2.ZERO
var root_flies: bool = false
var form: int = Bozo.Form.NONE
var claim_id: int = -1


func add_root(shard_: ShardData) -> void:
	origin = shard_.position
	matter = shard_.matter
	total = shard_.volume
	_bind(shard_, -1, Bozo.Port.NONE, Rules.root_ports(), 0)
	shards.append(shard_)
	_refresh_totals()


func place(shard_: ShardData, from_: Vector2, port_: int) -> void:
	var tip := get_tip()
	var bias := tip.depth_bias
	tip.close_port(port_)
	if port_ == Bozo.Port.ALPHA:
		bias += int(Catalog.CARD_BODY_H) + 1
		total += shard_.volume
		_bind(shard_, tip.id, port_, Rules.ports_after(port_), bias)
	else:
		alpha_sum = total
		var mult := int(Digest.matter_to_mult[shard_.matter])
		beta_multiplier = mult
		crown = alpha_sum * mult
		shard_.multiplier = mult
		total = crown
		multiplier = mult
		beta_used = true
		is_locked = true
		element = Rules.transition_element(matter, shard_.matter)
		matter = shard_.matter
		_bind(shard_, tip.id, port_, [], bias)
	shard_.position = tip.position + Geometry.get_offset(port_)
	add_shard(shard_, from_)


func add_shard(shard_: ShardData, from_: Vector2) -> void:
	shards.append(shard_)
	_refresh_totals()
	shard_added.emit(shard_, from_)
	changed.emit()


func get_tip() -> ShardData:
	if shards.is_empty():
		return null
	return shards[shards.size() - 1]


func get_aabb() -> Rect2:
	if shards.is_empty():
		return Geometry.get_shard_aabb(origin)
	var box := Geometry.get_shard_aabb(shards[0].position)
	for index in range(1, shards.size()):
		box = box.merge(Geometry.get_shard_aabb(shards[index].position))
	return box


func _bind(shard_: ShardData, parent_id_: int, port_: int, ports_: Array[int], bias_: int) -> void:
	shard_.is_in_stack = true
	shard_.stack_id = id
	shard_.parent_id = parent_id_
	shard_.attached_port = port_
	shard_.open_ports = ports_.duplicate()
	shard_.depth_bias = bias_
	shard_.changed.emit()


func _refresh_totals() -> void:
	var label := -1
	if shards.size() > 1 or is_locked:
		label = total
	for shard in shards:
		shard.apply_total(label)
