class_name Rules
extends RefCounted


const ALLOWED_VOLUMES: Array[int] = [
	2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 18, 20, 25, 27, 30, 32,
]


static func is_volume_valid(volume_: int) -> bool:
	return ALLOWED_VOLUMES.has(volume_)


static func can_stack_alpha(stack_total_: int, shard_volume_: int) -> bool:
	return is_volume_valid(stack_total_ + shard_volume_)


static func is_matter_transition_valid(from_: int, to_: int) -> bool:
	return Digest.transition_to_element.has(Digest.transition_key(from_, to_))


static func transition_element(from_: int, to_: int) -> int:
	var key := Digest.transition_key(from_, to_)
	if not Digest.transition_to_element.has(key):
		return Bozo.Element.NONE
	return Digest.transition_to_element[key]


static func can_place(stack_: StackData, shard_: ShardData, port_: int) -> bool:
	if stack_ == null or shard_ == null or stack_.is_locked:
		return false
	var tip := stack_.get_tip()
	if tip == null or not tip.is_port_open(port_):
		return false
	match port_:
		Bozo.Port.ALPHA:
			if not tip.is_port_open(Bozo.Port.ALPHA):
				return false
			if shard_.matter != stack_.matter:
				return false
			return can_stack_alpha(stack_.total, shard_.volume)
		Bozo.Port.BETA:
			if stack_.beta_used or shard_.matter == stack_.matter:
				return false
			return is_matter_transition_valid(stack_.matter, shard_.matter)
		_:
			return false


static func roll_volume(matter_: int, quality_: int) -> int:
	var rows: Array = Digest.deposit_rows[Digest.drop_key(matter_, quality_)]
	var roll := Helper.rng.randi_range(1, 100)
	var cursor := 0
	for row in rows:
		cursor += int(row[1])
		if roll <= cursor:
			return int(row[0])
	return int(rows[rows.size() - 1][0])


static func root_ports() -> Array[int]:
	return [Bozo.Port.ALPHA, Bozo.Port.BETA]


static func ports_after(port_: int) -> Array[int]:
	if port_ == Bozo.Port.ALPHA:
		return [Bozo.Port.ALPHA, Bozo.Port.BETA]
	return []
