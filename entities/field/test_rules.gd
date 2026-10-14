class_name TestRules
extends RefCounted


static func run() -> void:
	_test_volume_and_table()
	_test_alpha_table()
	_test_transitions()
	_test_alpha_and_beta()
	_test_only_tip_accepts()
	_test_hex_and_deposits()
	_test_crew()
	_test_crown_spawn_save()
	print("TestRules: ok")


static func _test_volume_and_table() -> void:
	assert(Rules.ALLOWED_VOLUMES.size() == 16)
	for matter in [Bozo.Matter.GAS, Bozo.Matter.LIQUID, Bozo.Matter.SOLID]:
		for quality in [Bozo.Quality.POOR, Bozo.Quality.COMMON, Bozo.Quality.RICH]:
			var rows: Array = Digest.deposit_rows[Digest.drop_key(matter, quality)]
			var sum := 0
			for row in rows:
				sum += int(row[1])
				assert(Rules.is_volume_valid(int(row[0])))
			assert(sum == 100)
	Helper.rng.seed = 3
	var rolled := Rules.roll_volume(Bozo.Matter.SOLID, Bozo.Quality.POOR)
	assert(rolled == 5 or rolled == 10 or rolled == 15)


static func _test_transitions() -> void:
	assert(Rules.is_matter_transition_valid(Bozo.Matter.GAS, Bozo.Matter.LIQUID))
	assert(Rules.transition_element(Bozo.Matter.GAS, Bozo.Matter.LIQUID) == Bozo.Element.CLOUD)
	assert(Rules.transition_element(Bozo.Matter.LIQUID, Bozo.Matter.GAS) == Bozo.Element.VAPOR)
	assert(Rules.transition_element(Bozo.Matter.GAS, Bozo.Matter.SOLID) == Bozo.Element.DUST)
	assert(Rules.transition_element(Bozo.Matter.SOLID, Bozo.Matter.GAS) == Bozo.Element.SAND)
	assert(Rules.transition_element(Bozo.Matter.LIQUID, Bozo.Matter.SOLID) == Bozo.Element.ICE)
	assert(Rules.transition_element(Bozo.Matter.SOLID, Bozo.Matter.LIQUID) == Bozo.Element.LAVA)
	assert(not Rules.is_matter_transition_valid(Bozo.Matter.GAS, Bozo.Matter.GAS))
	assert(not Rules.is_matter_transition_valid(Bozo.Matter.SOLID, Bozo.Matter.SOLID))


static func _test_alpha_and_beta() -> void:
	var field := FieldData.new()
	var root := field.make_shard(Bozo.Matter.GAS, 2)
	root.position = Vector2.ZERO
	field.ground.append(root)
	field.selected = root
	field.create_stack(Vector2.ZERO)
	var stack := field.stacks[0]
	assert(stack.total == 2)
	assert(stack.get_tip().shown_total == -1)
	var bad := field.make_shard(Bozo.Matter.LIQUID, 9)
	assert(not Rules.can_place(stack, bad, Bozo.Port.ALPHA))
	var cross := field.make_shard(Bozo.Matter.LIQUID, 2)
	assert(not Rules.can_place(stack, cross, Bozo.Port.ALPHA))
	assert(Rules.can_place(stack, cross, Bozo.Port.BETA))
	var solid := field.make_shard(Bozo.Matter.SOLID, 2)
	assert(not Rules.can_place(stack, solid, Bozo.Port.ALPHA))
	var same_beta := field.make_shard(Bozo.Matter.GAS, 3)
	assert(not Rules.can_place(stack, same_beta, Bozo.Port.BETA))
	var good := field.make_shard(Bozo.Matter.GAS, 3)
	field.ground.append(good)
	field.selected = good
	var moves := field.find_moves(good)
	assert(moves.size() == 1)
	var alpha: Move = null
	for move in moves:
		if move.port == Bozo.Port.ALPHA:
			alpha = move
	assert(alpha != null)
	field.apply_move(alpha)
	assert(stack.total == 5)
	assert(stack.shards.size() == 2)
	assert(stack.get_tip().shown_total == 5)
	assert(not stack.shards[0].is_port_open(Bozo.Port.ALPHA))
	assert(stack.get_tip() == good)
	var same := field.make_shard(Bozo.Matter.GAS, 2)
	assert(not Rules.can_place(stack, same, Bozo.Port.BETA))
	var liquid := field.make_shard(Bozo.Matter.LIQUID, 6)
	field.ground.append(liquid)
	field.selected = liquid
	var beta: Move = null
	for move in field.find_moves(liquid):
		if move.port == Bozo.Port.BETA:
			beta = move
	assert(beta != null)
	assert(beta.target_id == good.id)
	field.apply_move(beta)
	assert(stack.is_locked)
	assert(stack.beta_used)
	assert(stack.total == 15)
	assert(stack.multiplier == 3)
	assert(stack.alpha_sum == 5)
	assert(stack.beta_multiplier == 3)
	assert(stack.crown == 15)
	assert(stack.matter == Bozo.Matter.LIQUID)
	assert(stack.element == Bozo.Element.CLOUD)
	assert(liquid.multiplier == 3)
	assert(stack.get_tip().shown_total == 15)
	assert(not Rules.can_place(stack, field.make_shard(Bozo.Matter.SOLID, 5), Bozo.Port.ALPHA))
	assert(not Rules.can_place(stack, field.make_shard(Bozo.Matter.SOLID, 5), Bozo.Port.BETA))
	assert(stack.form == Bozo.Form.TREE)
	assert(field.trees.size() == 1)
	assert(field.trees[0].value == 15)
	assert(field.trees[0].crown == 15)
	assert(field.trees[0].alpha_sum == 5)
	assert(field.trees[0].beta_multiplier == 3)
	assert(field.towers.is_empty())


static func _test_only_tip_accepts() -> void:
	var field := FieldData.new()
	var root := field.make_shard(Bozo.Matter.SOLID, 5)
	root.position = Vector2(40, 40)
	field.ground.append(root)
	field.selected = root
	field.create_stack(root.position)
	var stack := field.stacks[0]
	var extra := field.make_shard(Bozo.Matter.SOLID, 5)
	field.ground.append(extra)
	field.selected = extra
	var move: Move = field.find_moves(extra)[0]
	assert(move.port == Bozo.Port.ALPHA)
	field.apply_move(move)
	var onto_root := field.make_shard(Bozo.Matter.GAS, 2)
	var found_moves := field.find_moves(onto_root)
	assert(not found_moves.is_empty())
	for found in found_moves:
		assert(found.target_id == extra.id)


static func _test_hex_and_deposits() -> void:
	assert(Digest.matter_to_mult[Bozo.Matter.GAS] == 2)
	assert(Digest.matter_to_mult[Bozo.Matter.LIQUID] == 3)
	assert(Digest.matter_to_mult[Bozo.Matter.SOLID] == 5)
	assert(Catalog.CARD_W == 48.0)
	assert(Catalog.SHARD_CIRCUMRADIUS == 24.0)
	assert(Catalog.DEPOSIT_RADIUS == 48.0)
	assert(Catalog.SPAWN_MIN > Catalog.DEPOSIT_RADIUS + Catalog.SHARD_CIRCUMRADIUS)
	var sizes: Array[int] = [6, 12, 18, 24, 30]
	for layer in range(1, HexGrid.MAX_LAYER + 1):
		var hexes := HexGrid.hexes_in_layer(layer)
		assert(hexes.size() == sizes[layer - 1])
		var borders := 0
		var per_sector := {Bozo.Sector.SWAMP: 0, Bozo.Sector.JUNGLE: 0, Bozo.Sector.MOUNTAIN: 0}
		for hex in hexes:
			var back := HexGrid.world_to_axial(HexGrid.axial_to_world(hex.x, hex.y))
			assert(back == hex)
			var sector := HexGrid.sector_of(hex, layer)
			if sector == -1:
				borders += 1
				assert(HexGrid.index_in_sector(hex, layer) == -1)
			else:
				var index := HexGrid.index_in_sector(hex, layer)
				assert(index >= 0 and index <= layer)
				per_sector[sector] += 1
		assert(borders == 3 * (layer - 1))
		for sector in per_sector:
			assert(per_sector[sector] == layer + 1)
	var field := FieldData.new()
	field.build()
	assert(field.deposits.size() == 15)
	var counts := {Bozo.Sector.SWAMP: 0, Bozo.Sector.JUNGLE: 0, Bozo.Sector.MOUNTAIN: 0}
	var poor := 0
	var common := 0
	var rich := 0
	var seen: Array[Vector2i] = []
	for deposit in field.deposits:
		assert(not seen.has(deposit.axial))
		seen.append(deposit.axial)
		var layer := _radius(deposit.axial)
		counts[deposit.sector] += 1
		assert(deposit.matter == Digest.sector_to_matter[deposit.sector])
		assert(HexGrid.sector_of(deposit.axial, layer) == deposit.sector)
		var index := HexGrid.index_in_sector(deposit.axial, layer)
		if deposit.quality == Bozo.Quality.POOR:
			poor += 1
			assert(layer == 2)
			assert(index == 0 or index == layer)
			assert(deposit.threshold == 3)
		elif deposit.quality == Bozo.Quality.COMMON:
			common += 1
			assert(layer == 4)
			assert(index == 0 or index == layer)
			assert(deposit.threshold == 6)
		else:
			rich += 1
			assert(layer == 4)
			assert(index == layer / 2)
			assert(deposit.threshold == 9)
	assert(counts[Bozo.Sector.SWAMP] == 5)
	assert(counts[Bozo.Sector.JUNGLE] == 5)
	assert(counts[Bozo.Sector.MOUNTAIN] == 5)
	assert(poor == 6 and common == 6 and rich == 3)
	for left in field.deposits:
		for right in field.deposits:
			if left == right:
				continue
			assert(left.position.distance_to(right.position) > Catalog.DEPOSIT_RADIUS * 2.0)


static func _radius(hex_: Vector2i) -> int:
	var s := -hex_.x - hex_.y
	return maxi(absi(hex_.x), maxi(absi(hex_.y), absi(s)))


static func _test_alpha_table() -> void:
	var valid_pairs := [
		[2, 2, 4], [2, 3, 5],
		[3, 2, 5], [3, 3, 6], [3, 5, 8],
		[4, 2, 6], [4, 5, 9],
		[5, 3, 8], [5, 5, 10],
		[6, 2, 8], [6, 3, 9],
		[8, 2, 10],
		[9, 3, 12],
		[10, 2, 12], [10, 5, 15],
		[12, 3, 15],
		[15, 3, 18], [15, 5, 20],
		[18, 2, 20],
		[20, 5, 25],
		[25, 2, 27], [25, 5, 30],
		[27, 3, 30], [27, 5, 32],
		[30, 2, 32],
	]
	assert(valid_pairs.size() == 25)
	for pair in valid_pairs:
		var left := int(pair[0])
		var right := int(pair[1])
		var expected := int(pair[2])
		assert(Rules.can_stack_alpha(left, right))
		assert(left + right == expected)
	var invalid_pairs := [
		[2, 5], [6, 5], [8, 3], [8, 5], [9, 2], [9, 5], [10, 3],
		[12, 2], [12, 5], [15, 2], [18, 3], [18, 5], [20, 2], [20, 3],
		[25, 3], [27, 2], [30, 3], [30, 5], [32, 2],
	]
	assert(invalid_pairs.size() == 19)
	for pair in invalid_pairs:
		var left := int(pair[0])
		var right := int(pair[1])
		assert(not Rules.can_stack_alpha(left, right))
	for volume in Rules.ALLOWED_VOLUMES:
		assert(Rules.is_volume_valid(volume))
	for volume in [0, 1, 7, 11, 13, 14, 16, 17, 19, 21, 22, 23, 24, 26, 28, 29, 31, 33]:
		assert(not Rules.is_volume_valid(volume))


static func _test_crew() -> void:
	var roster := FieldData.new()
	roster.build()
	var miners := 0
	var gardeners := 0
	var hunters := 0
	var collectors := 0
	for worker in roster.workers:
		if worker.kind == Bozo.Kind.MINER:
			miners += 1
		elif worker.kind == Bozo.Kind.GARDENER:
			gardeners += 1
		elif worker.kind == Bozo.Kind.HUNTER:
			hunters += 1
		elif worker.kind == Bozo.Kind.COLLECTOR:
			collectors += 1
	assert(miners == 3 and gardeners == 1 and hunters == 1 and collectors == 1)
	assert(roster.buildings.size() == 4)
	assert(roster.barn != null)
	var mine := FieldData.new()
	var deposit := DepositData.new(0, Vector2i(2, 0), Bozo.Sector.SWAMP, Bozo.Quality.POOR)
	mine.deposits.append(deposit)
	var idle := mine.spawn_worker(Bozo.Kind.MINER, deposit.position)
	mine.advance(Gear.mine_interval[Bozo.Quality.POOR])
	assert(deposit.progress == 0)
	mine.assign_miner(idle, deposit)
	mine.advance(Gear.mine_interval[Bozo.Quality.POOR])
	assert(deposit.progress == 1)
	var pair := FieldData.new()
	var vein := DepositData.new(1, Vector2i(2, 0), Bozo.Sector.SWAMP, Bozo.Quality.POOR)
	pair.deposits.append(vein)
	var left := pair.spawn_worker(Bozo.Kind.MINER, vein.position)
	var right := pair.spawn_worker(Bozo.Kind.MINER, vein.position)
	pair.assign_miner(left, vein)
	pair.assign_miner(right, vein)
	assert(left.deposit_id == vein.id and right.deposit_id == vein.id)
	pair.advance(Gear.mine_interval[Bozo.Quality.POOR])
	assert(vein.progress == 2)
	var fresh := FieldData.new()
	var lone := fresh.make_shard(Bozo.Matter.GAS, 2)
	lone.position = Vector2(200, 200)
	fresh.ground.append(lone)
	fresh.spawn_worker(Bozo.Kind.GARDENER, lone.position)
	fresh.advance(0.05)
	assert(fresh.stacks.size() == 1)
	assert(fresh.stacks[0].total == 2)
	assert(fresh.ground.is_empty())
	assert(fresh.trees.is_empty())
	var alpha := FieldData.new()
	var root := alpha.make_shard(Bozo.Matter.GAS, 2)
	root.position = Vector2.ZERO
	alpha.ground.append(root)
	alpha.selected = root
	alpha.create_stack(Vector2.ZERO)
	var extra := alpha.make_shard(Bozo.Matter.GAS, 2)
	var drop := Vector2(0, -Catalog.CARD_BODY_H)
	extra.position = drop
	alpha.ground.append(extra)
	alpha.spawn_worker(Bozo.Kind.GARDENER, drop)
	alpha.advance(0.05)
	assert(alpha.stacks[0].total == 4)
	assert(alpha.ground.is_empty())
	assert(alpha.trees.is_empty())
	var beta := _beta_field(Bozo.Kind.GARDENER)
	assert(beta.trees.size() == 1)
	assert(beta.trees[0].value == 96)
	assert(beta.stacks[0].form == Bozo.Form.TREE)
	assert(beta.stacks[0].is_locked)
	assert(beta.towers.is_empty())
	var hunt := _beta_field(Bozo.Kind.HUNTER)
	assert(hunt.towers.size() == 1)
	assert(hunt.towers[0].value == 96)
	assert(hunt.towers[0].durability == 96)
	assert(hunt.stacks[0].form == Bozo.Form.TOWER)
	assert(hunt.trees.size() == 1)
	assert(hunt.trees[0].value == 4)
	var dry := _beta_field(Bozo.Kind.HUNTER, false)
	assert(dry.towers.is_empty())
	var grove := FieldData.new()
	var tree := TreeNodeData.new()
	tree.value = 9
	tree.clock = Gear.tree_interval[Gear.tempo]
	grove.trees.append(tree)
	grove.advance(0.0)
	assert(tree.value == 6)
	assert(grove.fruits.size() == 1)
	assert(grove.fruits[0].hp == 3)
	var picker := FieldData.new()
	var fruit := FruitData.new()
	fruit.position = Vector2.ZERO
	fruit.hp = 3
	fruit.value = 3
	picker.fruits.append(fruit)
	fruit.id = 7
	picker.barn = BarnData.new()
	picker.spawn_worker(Bozo.Kind.COLLECTOR, fruit.position)
	picker.advance(0.05)
	assert(picker.fruits.is_empty())
	assert(picker.barn.nectar == 3)
	picker.barn.nectar = Catalog.WIN_NECTAR - 1
	var last := FruitData.new()
	last.id = 4
	last.hp = 1
	last.value = 1
	last.position = Vector2(10, 10)
	picker.fruits.append(last)
	picker.collect_fruit(last)
	assert(picker.barn.nectar == Catalog.WIN_NECTAR)
	assert(picker.is_won)
	var blight := FieldData.new()
	blight.trees.append(TreeNodeData.new())
	var meal := FruitData.new()
	meal.id = 1
	meal.hp = 2
	meal.position = Vector2.ZERO
	blight.fruits.append(meal)
	var pest := PestData.new()
	pest.id = 1
	pest.hp = Catalog.PEST_HP
	pest.position = meal.position
	blight.pests.append(pest)
	blight.advance(Gear.eat_interval[Gear.tempo])
	assert(meal.hp == 1)
	assert(blight.seasons_lost == 0)
	blight.advance(Gear.eat_interval[Gear.tempo])
	assert(blight.fruits.is_empty())
	assert(blight.seasons_lost == 1)
	var watch := FieldData.new()
	watch.trees.append(TreeNodeData.new())
	var bait := FruitData.new()
	bait.id = 9
	bait.hp = 40
	bait.value = 1
	bait.position = Vector2.ZERO
	watch.fruits.append(bait)
	var tower := TowerData.new()
	tower.value = 4
	tower.durability = 1
	tower.position = Vector2.ZERO
	watch.towers.append(tower)
	var target := PestData.new()
	target.id = 3
	target.hp = Catalog.PEST_HP
	target.position = tower.position
	watch.pests.append(target)
	watch.advance(Gear.tower_interval[Gear.tempo])
	assert(tower.durability == 0)
	assert(target.hp == Catalog.PEST_HP - 1)
	assert(watch.arrows.is_empty())
	watch.advance(Gear.tower_interval[Gear.tempo])
	assert(target.hp == Catalog.PEST_HP - 1)
	var nest := FieldData.new()
	nest.pest_clock = Gear.pest_interval[Gear.tempo]
	nest.advance(0.0)
	assert(nest.pests.is_empty())
	nest.trees.append(TreeNodeData.new())
	nest.pest_clock = Gear.pest_interval[Gear.tempo]
	nest.advance(0.0)
	assert(nest.pests.size() == 1)
	assert(nest.pests[0].hp == Catalog.PEST_HP)
	assert(Catalog.hire_cost(0) == 10)
	assert(Catalog.hire_cost(1) == 20)
	assert(Catalog.hire_cost(3) == 50)
	assert(Catalog.boost_cost(0) == 100)
	assert(Catalog.boost_cost(1) == 121)
	var den := FieldData.new()
	den.barn = BarnData.new()
	den.barn.nectar = 500
	var thief := ThiefData.new()
	thief.id = 1
	thief.position = Vector2.ZERO
	thief.state = Bozo.ThiefState.TO_BARN
	den.thieves.append(thief)
	den.advance(0.05)
	assert(den.barn.nectar == 477)
	assert(den.fruits.size() == 1)
	assert(den.fruits[0].value == 23)
	assert(den.fruits[0].carried)
	assert(thief.state == Bozo.ThiefState.FLEE)
	var ring := FieldData.new()
	var trunk := TreeNodeData.new()
	trunk.position = Vector2.ZERO
	ring.trees.append(trunk)
	var glutton := PestData.new()
	glutton.id = 2
	glutton.position = Vector2.ZERO
	ring.pests.append(glutton)
	var stayed := glutton.position
	ring.advance(0.2)
	assert(glutton.state == Bozo.PestState.IDLE)
	assert(glutton.position == stayed)
	assert(Catalog.mask_for_kind(Bozo.Kind.MINER) & Catalog.LAYER_MINE != 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.MINER) & Catalog.LAYER_BARN == 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.GARDENER) & Catalog.LAYER_GREENHOUSE != 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.GARDENER) & Catalog.LAYER_MINE == 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.HUNTER) & Catalog.LAYER_BARRACKS != 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.COLLECTOR) & Catalog.LAYER_BARN != 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.COLLECTOR) & Catalog.LAYER_WAREHOUSE != 0)
	assert(Catalog.mask_for_kind(Bozo.Kind.COLLECTOR) & Catalog.LAYER_TREE == 0)
	assert(Catalog.mask_for_pest() & Catalog.LAYER_FRUIT == 0)
	assert(Catalog.mask_for_thief() & Catalog.LAYER_BARN != 0)
	assert(Catalog.mask_for_thief() & Catalog.LAYER_FRUIT == 0)
	var cap := FieldData.new()
	assert(cap.max_pests() == 1)
	cap.barn = BarnData.new()
	cap.barn.nectar = 100
	assert(cap.max_pests() == 1)
	cap.barn.nectar = 101
	assert(cap.max_pests() == 2)
	cap.barn.nectar = 1000
	assert(cap.max_pests() == 10)
	cap.debug_add_nectar(250)
	assert(cap.barn.nectar == 1250)
	nest.pest_clock = Gear.pest_interval[Gear.tempo] * 2.0
	nest.advance(0.0)
	assert(nest.pests.size() == 1)


static func _test_crown_spawn_save() -> void:
	assert(_crown_of([2, 3, 5], Bozo.Matter.LIQUID) == 30)
	assert(_crown_of([5, 5], Bozo.Matter.SOLID) == 50)
	assert(_crown_of([2, 2, 2, 2], Bozo.Matter.GAS) == 16)
	var crowd := FieldData.new()
	var house := BuildingData.new()
	house.position = Vector2(400, 400)
	crowd.buildings.append(house)
	for _index in 10:
		crowd._hire_at(Bozo.Kind.MINER, house)
	assert(crowd.workers.size() == 10)
	var door := house.position + Vector2(0, Catalog.HOUSE_RADIUS + Catalog.BODY_RADIUS + 6.0)
	for worker in crowd.workers:
		assert(worker.position.distance_to(door) <= Catalog.SPAWN_SCATTER + 0.1)
		for other in crowd.workers:
			if other == worker:
				continue
			assert(worker.position.distance_to(other.position) >= Catalog.BODY_RADIUS * 2.0 - 0.1)
	var blocked := FieldData.new()
	var deposit := DepositData.new(0, Vector2i.ZERO, Bozo.Sector.SWAMP, Bozo.Quality.POOR)
	blocked.deposits.append(deposit)
	for radius in [Catalog.SPAWN_MIN, (Catalog.SPAWN_MIN + Catalog.SPAWN_MAX) * 0.5, Catalog.SPAWN_MAX]:
		var steps := int(TAU * radius / 28.0) + 1
		for step in steps:
			var shard := blocked.make_shard(Bozo.Matter.GAS, 2)
			shard.position = deposit.position + Vector2.from_angle(TAU * float(step) / float(steps)) * radius
			blocked.ground.append(shard)
	var before := blocked.ground.size()
	deposit.progress = deposit.threshold - 1
	blocked._dig(deposit)
	assert(blocked.ground.size() == before)
	assert(deposit.jammed)
	assert(deposit.progress == deposit.threshold)
	var spot := deposit.position + Vector2(0, -Catalog.CARD_W)
	var pile := FieldData.new()
	var root := pile.make_shard(Bozo.Matter.GAS, 2)
	root.position = Vector2.ZERO
	pile.ground.append(root)
	pile.selected = root
	pile.create_stack(Vector2.ZERO)
	assert(not pile._is_spawn_free(spot))
	var saved := FieldData.new()
	saved.build()
	saved.barn.nectar = 40
	saved.elapsed = 75.0
	var text := JSON.stringify(saved.to_save())
	var parsed: Variant = JSON.parse_string(text)
	var copy := FieldData.new()
	assert(copy.restore(parsed))
	assert(copy.barn.nectar == 40)
	assert(is_equal_approx(copy.elapsed, 75.0))
	assert(copy.workers.size() == saved.workers.size())
	assert(copy.deposits.size() == saved.deposits.size())
	assert(copy.buildings.size() == 4)
	assert(not copy.restore({"version": 2}))


static func _crown_of(volumes_: Array, beta_matter_: int) -> int:
	var field := FieldData.new()
	var matter := Bozo.Matter.GAS if beta_matter_ != Bozo.Matter.GAS else Bozo.Matter.LIQUID
	var root := field.make_shard(matter, int(volumes_[0]))
	root.position = Vector2.ZERO
	field.ground.append(root)
	field.selected = root
	field.create_stack(Vector2.ZERO)
	for index in range(1, volumes_.size()):
		var shard := field.make_shard(matter, int(volumes_[index]))
		shard.position = Vector2(0, -40)
		field.ground.append(shard)
		field.selected = shard
		var move: Move = null
		for found in field.find_moves(shard):
			if found.port == Bozo.Port.ALPHA:
				move = found
		assert(move != null)
		field.apply_move(move)
	var beta := field.make_shard(beta_matter_, 3)
	beta.position = Vector2(40, 0)
	field.ground.append(beta)
	field.selected = beta
	var placed: Move = null
	for found in field.find_moves(beta):
		if found.port == Bozo.Port.BETA:
			placed = found
	assert(placed != null)
	field.apply_move(placed)
	return field.stacks[0].crown


static func _beta_field(kind_: int, with_tree_: bool = true) -> FieldData:
	var field := FieldData.new()
	var root := field.make_shard(Bozo.Matter.GAS, 32)
	root.position = Vector2.ZERO
	field.ground.append(root)
	field.selected = root
	field.create_stack(Vector2.ZERO)
	var shard := field.make_shard(Bozo.Matter.LIQUID, 3)
	var drop: Vector2 = Geometry.get_offset(Bozo.Port.BETA)
	shard.position = drop
	field.ground.append(shard)
	if kind_ == Bozo.Kind.HUNTER and with_tree_:
		var bait := TreeNodeData.new()
		bait.position = Vector2.ZERO
		bait.value = 4
		field.trees.append(bait)
	field.spawn_worker(kind_, drop)
	field.advance(0.05)
	return field
