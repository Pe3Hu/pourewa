class_name FieldData
extends RefCounted


signal selection_changed
signal deposit_spawned(deposit_: DepositData)
signal shard_spawned(shard_: ShardData)
signal shard_removed(shard_: ShardData)
signal stack_spawned(stack_: StackData)
signal move_applied(move_: Move)
signal worker_spawned(worker_: WorkerData)
signal tree_spawned(tree_: TreeNodeData)
signal fruit_spawned(fruit_: FruitData)
signal fruit_removed(fruit_: FruitData)
signal pest_spawned(pest_: PestData)
signal pest_removed(pest_: PestData)
signal tower_spawned(tower_: TowerData)
signal arrow_spawned(arrow_: ArrowData)
signal arrow_removed(arrow_: ArrowData)
signal shard_lifted(shard_: ShardData, worker_: WorkerData)
signal fruit_lifted(fruit_: FruitData, worker_: WorkerData)
signal fruit_stolen(fruit_: FruitData, thief_: ThiefData)
signal thief_spawned(thief_: ThiefData)
signal thief_removed(thief_: ThiefData)
signal building_spawned(building_: BuildingData)
signal score_changed


var deposits: Array[DepositData] = []
var ground: Array[ShardData] = []
var stacks: Array[StackData] = []
var workers: Array[WorkerData] = []
var trees: Array[TreeNodeData] = []
var fruits: Array[FruitData] = []
var pests: Array[PestData] = []
var towers: Array[TowerData] = []
var arrows: Array[ArrowData] = []
var buildings: Array[BuildingData] = []
var thieves: Array[ThiefData] = []
var barn: BarnData
var id_to_shard: Dictionary[int, ShardData] = {}
var phase: int = Bozo.Phase.IDLE
var selected: ShardData = null
var selected_worker: WorkerData = null
var seasons_lost: int = 0
var is_won: bool = false
var pest_clock: float = 0.0
var thief_clock: float = 0.0
var elapsed: float = 0.0
var next_shard_id: int = 0
var next_stack_id: int = 0
var next_deposit_id: int = 0
var next_worker_id: int = 0
var next_tree_id: int = 0
var next_fruit_id: int = 0
var next_pest_id: int = 0
var next_tower_id: int = 0
var next_arrow_id: int = 0
var next_building_id: int = 0
var next_thief_id: int = 0


func build() -> void:
	deposits.clear()
	workers.clear()
	_place_edges(2, Bozo.Quality.POOR)
	_place_edges(4, Bozo.Quality.COMMON)
	_place_index(4, 4 / 2, Bozo.Quality.RICH)
	_spawn_barn()
	_spawn_houses()
	_spawn_roster()


func advance(delta_: float) -> void:
	elapsed += delta_
	_move_workers(delta_)
	_advance_mines(delta_)
	_advance_trees(delta_)
	_advance_pests(delta_)
	_advance_thieves(delta_)
	_advance_towers(delta_)
	_advance_arrows(delta_)


func mine(deposit_: DepositData) -> void:
	if deposit_ == null or phase != Bozo.Phase.IDLE:
		return
	phase = Bozo.Phase.CLICK_DEPOSIT
	_dig(deposit_)
	phase = Bozo.Phase.IDLE


func find_moves(shard_: ShardData) -> Array[Move]:
	var moves: Array[Move] = []
	if shard_ == null:
		return moves
	for stack in stacks:
		for port in [Bozo.Port.ALPHA, Bozo.Port.BETA]:
			if not Rules.can_place(stack, shard_, port):
				continue
			moves.append(_make_move(shard_, stack, port))
	return moves


func apply_move(move_: Move) -> void:
	if move_ == null or selected == null or selected.id != move_.shard_id:
		return
	if not id_to_shard.has(move_.target_id):
		return
	var stack := get_stack_data(move_.stack_id)
	var shard := id_to_shard[move_.shard_id]
	if not commit_move(shard, stack, move_.port, Bozo.Form.TREE):
		return
	move_.world_pos = shard.position
	clear_selection()
	move_applied.emit(move_)


func commit_move(shard_: ShardData, stack_: StackData, port_: int, beta_form_: int) -> bool:
	if shard_ == null or stack_ == null or not Rules.can_place(stack_, shard_, port_):
		return false
	if ground.has(shard_):
		ground.erase(shard_)
	shard_removed.emit(shard_)
	var from := shard_.position
	stack_.place(shard_, from, port_)
	if port_ == Bozo.Port.BETA and stack_.form == Bozo.Form.NONE:
		_form_stack(stack_, beta_form_)
	return true


func create_stack(at_: Vector2) -> void:
	if selected == null or not ground.has(selected):
		return
	raise_stack(selected, at_)
	clear_selection()


func raise_stack(shard_: ShardData, at_: Vector2) -> StackData:
	var from := shard_.position
	var spot := at_ if is_spot_free(at_, shard_) else from
	if ground.has(shard_):
		ground.erase(shard_)
	shard_removed.emit(shard_)
	shard_.claim_id = -1
	shard_.position = spot
	var stack := StackData.new()
	stack.id = _take_stack_id()
	stack.root_from = from
	stack.root_flies = from.distance_to(spot) > 1.0
	stack.add_root(shard_)
	stacks.append(stack)
	stack_spawned.emit(stack)
	return stack


func apply_selection(shard_: ShardData) -> void:
	if shard_ == null or not ground.has(shard_):
		return
	if selected == shard_:
		clear_selection()
		return
	_release_shard(shard_)
	selected_worker = null
	selected = shard_
	phase = Bozo.Phase.SELECT_SHARD
	selection_changed.emit()


func select_worker(worker_: WorkerData) -> void:
	if worker_ == null:
		return
	if selected_worker == worker_:
		clear_selection()
		return
	selected = null
	selected_worker = worker_
	phase = Bozo.Phase.ASSIGN_WORKER
	selection_changed.emit()


func assign_miner(worker_: WorkerData, deposit_: DepositData) -> void:
	if worker_ == null or deposit_ == null or worker_.kind != Bozo.Kind.MINER:
		return
	worker_.deposit_id = deposit_.id
	worker_.dig_matter = deposit_.matter
	worker_.click_clock = 0.0
	worker_.aim = deposit_.position + Catalog.POST_OFFSET
	worker_.changed.emit()
	_sync_crews()
	clear_selection()


func clear_selection() -> void:
	if selected == null and selected_worker == null and phase == Bozo.Phase.IDLE:
		return
	selected = null
	selected_worker = null
	phase = Bozo.Phase.IDLE
	selection_changed.emit()


func collect_fruit(fruit_: FruitData) -> void:
	if fruit_ == null or not fruits.has(fruit_) or fruit_.carried:
		return
	_bank_fruit(fruit_)


func max_pests() -> int:
	var nectar := 0
	if barn != null:
		nectar = barn.nectar
	if nectar <= 0:
		return 1
	return ceili(float(nectar) / 100.0)


func debug_add_nectar(amount_: int) -> void:
	_ensure_barn()
	barn.nectar += amount_
	if barn.nectar >= Catalog.WIN_NECTAR:
		is_won = true
	_emit_score()


func hire(building_: BuildingData) -> bool:
	if building_ == null or not buildings.has(building_):
		return false
	_ensure_barn()
	var cost := Catalog.hire_cost(building_.hire_count)
	if barn.nectar < cost:
		return false
	barn.nectar -= cost
	var kind: int = Digest.house_to_kind[building_.house]
	_hire_at(kind, building_)
	building_.hire_count += 1
	building_.changed.emit()
	_emit_score()
	return true


func boost(building_: BuildingData) -> bool:
	if building_ == null or not buildings.has(building_):
		return false
	_ensure_barn()
	var cost := Catalog.boost_cost(building_.speed_level)
	if barn.nectar < cost:
		return false
	barn.nectar -= cost
	building_.speed_level += 1
	for worker in workers:
		if worker.building_id == building_.id:
			worker.speed_level = building_.speed_level
			worker.changed.emit()
	building_.changed.emit()
	_emit_score()
	return true


func make_shard(matter_: int, volume_: int) -> ShardData:
	var shard := ShardData.new(next_shard_id, matter_, volume_)
	next_shard_id += 1
	id_to_shard[shard.id] = shard
	return shard


func spawn_worker(kind_: int, at_: Vector2) -> WorkerData:
	var worker := WorkerData.new()
	worker.id = next_worker_id
	next_worker_id += 1
	worker.kind = kind_
	worker.position = at_
	worker.home = at_
	worker.aim = at_
	worker.duty = Bozo.Duty.IDLE
	workers.append(worker)
	worker_spawned.emit(worker)
	return worker


func get_stack_data(id_: int) -> StackData:
	for stack in stacks:
		if stack.id == id_:
			return stack
	return null


func is_spot_free(point_: Vector2, ignore_: ShardData = null) -> bool:
	var spot := Geometry.get_shard_aabb(point_)
	for deposit in deposits:
		var reach := Vector2.ONE * Catalog.DEPOSIT_RADIUS
		var deposit_box := Rect2(deposit.position - reach, reach * 2.0)
		if spot.intersects(deposit_box.grow(Catalog.STACK_CLEARANCE)):
			return false
	for stack in stacks:
		if spot.intersects(stack.get_aabb().grow(Catalog.STACK_CLEARANCE)):
			return false
	for shard in ground:
		if shard == selected or shard == ignore_:
			continue
		if spot.intersects(Geometry.get_shard_aabb(shard.position)):
			return false
	return true


func _spawn_roster() -> void:
	var mine := _house(Bozo.House.MINE)
	var greenhouse := _house(Bozo.House.GREENHOUSE)
	var barracks := _house(Bozo.House.BARRACKS)
	var warehouse := _house(Bozo.House.WAREHOUSE)
	for sector in [Bozo.Sector.SWAMP, Bozo.Sector.JUNGLE, Bozo.Sector.MOUNTAIN]:
		var miner := _hire_at(Bozo.Kind.MINER, mine)
		var deposit := _poorest(sector)
		if deposit != null:
			miner.deposit_id = deposit.id
			miner.dig_matter = deposit.matter
			miner.aim = deposit.position + Catalog.POST_OFFSET
	_hire_at(Bozo.Kind.GARDENER, greenhouse)
	_hire_at(Bozo.Kind.HUNTER, barracks)
	_hire_at(Bozo.Kind.COLLECTOR, warehouse)
	_sync_crews()


func _dig(deposit_: DepositData) -> void:
	if deposit_.jammed:
		_release_shard_spawn(deposit_)
		return
	if not deposit_.add_progress():
		return
	_release_shard_spawn(deposit_)


func _release_shard_spawn(deposit_: DepositData) -> void:
	var spot := _find_shard_spawn(deposit_)
	if spot == Vector2.INF:
		deposit_.progress = deposit_.threshold
		deposit_.jammed = true
		deposit_.changed.emit()
		return
	deposit_.jammed = false
	deposit_.progress = 0
	deposit_.changed.emit()
	var volume := Rules.roll_volume(deposit_.matter, deposit_.quality)
	var shard := make_shard(deposit_.matter, volume)
	shard.position = spot
	ground.append(shard)
	shard_spawned.emit(shard)


func _find_shard_spawn(deposit_: DepositData) -> Vector2:
	for _attempt in Catalog.SPAWN_ATTEMPTS:
		var angle := Helper.rng.randf_range(0.0, TAU)
		var distance := Helper.rng.randf_range(Catalog.SPAWN_MIN, Catalog.SPAWN_MAX)
		var spot := deposit_.position + Vector2.from_angle(angle) * distance
		if _is_spawn_free(spot):
			return spot
	return Vector2.INF


func _is_spawn_free(spot_: Vector2) -> bool:
	var shard_gap := Catalog.SHARD_CIRCUMRADIUS * 2.0 + Catalog.SHARD_GAP
	for shard in ground:
		if spot_.distance_to(shard.position) < shard_gap:
			return false
	for fruit in fruits:
		if fruit.carried:
			continue
		if spot_.distance_to(fruit.position) < Catalog.SHARD_CIRCUMRADIUS + Catalog.FRUIT_RADIUS + 4.0:
			return false
	for stack in stacks:
		if _hits_stack_buffer(spot_, stack):
			return false
		if stack.get_aabb().grow(Catalog.SHARD_CIRCUMRADIUS + 4.0).has_point(spot_):
			return false
	for tree in trees:
		if spot_.distance_to(tree.position) < Catalog.SHARD_CIRCUMRADIUS + 22.0 + 4.0:
			return false
	for tower in towers:
		if spot_.distance_to(tower.position) < Catalog.SHARD_CIRCUMRADIUS + 16.0 + 4.0:
			return false
	for building in buildings:
		if spot_.distance_to(building.position) < Catalog.SHARD_CIRCUMRADIUS + Catalog.HOUSE_RADIUS + 4.0:
			return false
	if barn != null and spot_.distance_to(barn.position) < Catalog.SHARD_CIRCUMRADIUS + Catalog.BARN_RADIUS + 4.0:
		return false
	for deposit in deposits:
		if spot_.distance_to(deposit.position) < Catalog.SHARD_CIRCUMRADIUS + Catalog.DEPOSIT_RADIUS + 4.0:
			return false
	return true


func _hits_stack_buffer(spot_: Vector2, stack_: StackData) -> bool:
	var tip := stack_.get_tip()
	if tip == null:
		return false
	var width := Catalog.CARD_W * 2.0
	var height := Catalog.STACK_TOP_BUFFER
	var rect := Rect2(tip.position.x - width * 0.5, tip.position.y - height, width, height)
	return rect.grow(Catalog.SHARD_CIRCUMRADIUS).has_point(spot_)


func _move_workers(delta_: float) -> void:
	for worker in workers:
		_sync_pace(worker)
		if worker.kind == Bozo.Kind.MINER:
			_move_miner(worker, delta_)
		elif worker.kind == Bozo.Kind.COLLECTOR:
			_move_actor(worker, delta_, _plan_collector, _finish_collector)
		else:
			_move_actor(worker, delta_, _plan_hauler, _finish_hauler)


func _move_miner(worker_: WorkerData, delta_: float) -> void:
	var deposit := _deposit_by_id(worker_.deposit_id)
	if deposit == null:
		worker_.deposit_id = -1
		worker_.aim = worker_.home
	else:
		worker_.aim = deposit.position + Catalog.POST_OFFSET
	_step(worker_, delta_)


func _move_actor(worker_: WorkerData, delta_: float, plan_: Callable, finish_: Callable) -> void:
	if worker_.duty == Bozo.Duty.IDLE:
		plan_.call(worker_)
	var budget := delta_
	for _hop in 4:
		if worker_.position.distance_to(worker_.aim) > _reach(worker_):
			if not _step(worker_, budget):
				return
			budget = 0.0
		if worker_.duty == Bozo.Duty.IDLE:
			return
		finish_.call(worker_)
		plan_.call(worker_)


func _step(worker_: WorkerData, delta_: float) -> bool:
	var reach := _reach(worker_)
	if worker_.driven:
		return worker_.position.distance_to(worker_.aim) <= reach
	var offset := worker_.aim - worker_.position
	var dist := offset.length()
	if dist <= reach:
		worker_.position = worker_.aim
		worker_.changed.emit()
		return true
	var step := _pace(worker_) * delta_
	if step <= 0.0:
		return false
	if step >= dist:
		worker_.position = worker_.aim
	else:
		worker_.position += offset * (step / dist)
	worker_.changed.emit()
	return worker_.position.distance_to(worker_.aim) <= Catalog.ARRIVE


func _plan_hauler(worker_: WorkerData) -> void:
	if worker_.carry_id >= 0:
		var carried_stack := get_stack_data(worker_.intent_stack_id)
		if carried_stack == null or carried_stack.get_tip() == null:
			_drop_carry(worker_)
			_clear_job(worker_)
			worker_.aim = worker_.home
			return
		worker_.duty = Bozo.Duty.TO_STACK
		worker_.aim = carried_stack.get_tip().position + Geometry.get_offset(worker_.intent_port)
		return
	_clear_job(worker_)
	var opening := _find_beta(worker_)
	if opening.size() == 2:
		_send_for_shard(worker_, opening[0] as ShardData, opening[1] as StackData, Bozo.Port.BETA)
		return
	var shard := _nearest_free_shard(worker_)
	if shard == null:
		worker_.aim = worker_.home
		return
	var stack := _nearest_alpha_stack(worker_, shard)
	if stack == null:
		_send_for_shard(worker_, shard, null, Bozo.Port.NONE)
	else:
		_send_for_shard(worker_, shard, stack, Bozo.Port.ALPHA)


func _finish_hauler(worker_: WorkerData) -> void:
	if worker_.duty == Bozo.Duty.TO_SHARD:
		var shard := _shard(worker_.target_shard_id)
		if shard == null or not ground.has(shard):
			_clear_job(worker_)
			return
		_pickup(worker_, shard)
		if worker_.intent_port == Bozo.Port.NONE:
			var spot := _stack_spot(worker_, shard)
			if worker_.position.distance_to(spot) > Catalog.ARRIVE:
				worker_.duty = Bozo.Duty.TO_STACK
				worker_.aim = spot
				return
			raise_stack(shard, spot)
			worker_.carry_id = -1
			_clear_job(worker_)
			return
		var stack := get_stack_data(worker_.intent_stack_id)
		if stack == null or stack.get_tip() == null:
			_drop_carry(worker_)
			_clear_job(worker_)
			return
		worker_.duty = Bozo.Duty.TO_STACK
		worker_.aim = stack.get_tip().position + Geometry.get_offset(worker_.intent_port)
		return
	if worker_.duty != Bozo.Duty.TO_STACK:
		return
	if worker_.intent_port == Bozo.Port.NONE:
		var founding := _shard(worker_.carry_id)
		if founding != null:
			raise_stack(founding, worker_.position)
			worker_.carry_id = -1
		_clear_job(worker_)
		return
	var carried := _shard(worker_.carry_id)
	var target := get_stack_data(worker_.intent_stack_id)
	var form := Bozo.Form.TREE
	if worker_.kind == Bozo.Kind.HUNTER:
		form = Bozo.Form.TOWER
	if carried != null:
		carried.position = worker_.position
	if carried == null or target == null or not commit_move(carried, target, worker_.intent_port, form):
		if carried != null and worker_.carry_id == carried.id:
			_drop_carry(worker_)
	else:
		worker_.carry_id = -1
	_clear_job(worker_)


func _plan_collector(worker_: WorkerData) -> void:
	if worker_.carry_fruit_id >= 0:
		worker_.duty = Bozo.Duty.TO_BARN
		worker_.aim = _barn_point()
		return
	var old := _fruit_by_id(worker_.target_fruit_id)
	if old != null and old.claim_id == worker_.id:
		old.claim_id = -1
	worker_.target_fruit_id = -1
	worker_.duty = Bozo.Duty.IDLE
	var fruit := _nearest_free_fruit(worker_)
	if fruit == null:
		worker_.aim = worker_.home
		return
	fruit.claim_id = worker_.id
	worker_.target_fruit_id = fruit.id
	worker_.duty = Bozo.Duty.TO_FRUIT
	worker_.aim = fruit.position


func _finish_collector(worker_: WorkerData) -> void:
	if worker_.duty == Bozo.Duty.TO_FRUIT:
		var fruit := _fruit_by_id(worker_.target_fruit_id)
		worker_.target_fruit_id = -1
		if fruit == null or not fruits.has(fruit) or fruit.carried:
			worker_.duty = Bozo.Duty.IDLE
			return
		_lift_fruit(worker_, fruit)
		worker_.duty = Bozo.Duty.TO_BARN
		worker_.aim = _barn_point()
		return
	if worker_.duty != Bozo.Duty.TO_BARN:
		return
	if worker_.position.distance_to(_barn_point()) > _reach(worker_):
		return
	var carried := _fruit_by_id(worker_.carry_fruit_id)
	worker_.carry_fruit_id = -1
	worker_.duty = Bozo.Duty.IDLE
	if carried == null or not fruits.has(carried):
		return
	carried.carried = false
	_bank_fruit(carried)


func _send_for_shard(worker_: WorkerData, shard_: ShardData, stack_: StackData, port_: int) -> void:
	shard_.claim_id = worker_.id
	worker_.target_shard_id = shard_.id
	worker_.intent_port = port_
	worker_.intent_stack_id = -1 if stack_ == null else stack_.id
	if stack_ != null:
		stack_.claim_id = worker_.id
	worker_.duty = Bozo.Duty.TO_SHARD
	worker_.aim = shard_.position
	worker_.changed.emit()


func _find_beta(worker_: WorkerData) -> Array:
	var best_shard: ShardData = null
	var best_stack: StackData = null
	var best_dist := INF
	var best_score := 0.0
	for stack in stacks:
		if stack.is_locked or stack.form != Bozo.Form.NONE:
			continue
		if stack.claim_id >= 0 and stack.claim_id != worker_.id:
			continue
		if _has_alpha_fit(stack, worker_):
			continue
		for shard in ground:
			if not _shard_free(shard, worker_):
				continue
			if not Rules.can_place(stack, shard, Bozo.Port.BETA):
				continue
			var dist := worker_.position.distance_to(shard.position)
			if worker_.kind == Bozo.Kind.HUNTER:
				var predicted := stack.total * shard.volume
				var score := _tower_score(stack.origin, predicted)
				if score <= 0.0:
					continue
				if score < best_score:
					continue
				if is_equal_approx(score, best_score) and dist >= best_dist:
					continue
				best_score = score
				best_dist = dist
			else:
				if dist >= best_dist:
					continue
				best_dist = dist
			best_shard = shard
			best_stack = stack
	if best_shard == null:
		return []
	return [best_shard, best_stack]


func _has_alpha_fit(stack_: StackData, worker_: WorkerData) -> bool:
	for shard in ground:
		if not _shard_free(shard, worker_):
			continue
		if Rules.can_place(stack_, shard, Bozo.Port.ALPHA):
			return true
	return false


func _nearest_free_shard(worker_: WorkerData) -> ShardData:
	var best: ShardData = null
	var dist := INF
	for shard in ground:
		if not _shard_free(shard, worker_):
			continue
		var gap := worker_.position.distance_to(shard.position)
		if gap >= dist:
			continue
		dist = gap
		best = shard
	return best


func _nearest_alpha_stack(worker_: WorkerData, shard_: ShardData) -> StackData:
	var best: StackData = null
	var dist := INF
	for stack in stacks:
		if stack.claim_id >= 0 and stack.claim_id != worker_.id:
			continue
		if not Rules.can_place(stack, shard_, Bozo.Port.ALPHA):
			continue
		var gap := shard_.position.distance_to(stack.origin)
		if gap >= dist:
			continue
		dist = gap
		best = stack
	return best


func _nearest_free_fruit(worker_: WorkerData) -> FruitData:
	var best: FruitData = null
	var dist := INF
	for fruit in fruits:
		if fruit.carried:
			continue
		if fruit.claim_id >= 0 and fruit.claim_id != worker_.id:
			continue
		var gap := worker_.position.distance_to(fruit.position)
		if gap >= dist:
			continue
		dist = gap
		best = fruit
	return best


func _shard_free(shard_: ShardData, worker_: WorkerData) -> bool:
	if shard_ == selected:
		return false
	if shard_.claim_id >= 0 and shard_.claim_id != worker_.id:
		return false
	return true


func _pickup(worker_: WorkerData, shard_: ShardData) -> void:
	ground.erase(shard_)
	worker_.carry_id = shard_.id
	shard_.claim_id = worker_.id
	worker_.carried_offset = shard_.position - worker_.position
	worker_.carried_angle = 0.0
	shard_lifted.emit(shard_, worker_)
	worker_.changed.emit()


func _drop_carry(worker_: WorkerData) -> void:
	var shard := _shard(worker_.carry_id)
	worker_.carry_id = -1
	if shard == null:
		return
	shard.claim_id = -1
	shard.position = worker_.position
	shard_removed.emit(shard)
	ground.append(shard)
	shard_spawned.emit(shard)


func _clear_job(worker_: WorkerData) -> void:
	if worker_.target_shard_id >= 0:
		var shard := _shard(worker_.target_shard_id)
		if shard != null and shard.claim_id == worker_.id and worker_.carry_id != shard.id:
			shard.claim_id = -1
	worker_.target_shard_id = -1
	if worker_.intent_stack_id >= 0:
		var stack := get_stack_data(worker_.intent_stack_id)
		if stack != null and stack.claim_id == worker_.id:
			stack.claim_id = -1
	worker_.intent_stack_id = -1
	worker_.intent_port = Bozo.Port.NONE
	worker_.duty = Bozo.Duty.IDLE
	worker_.changed.emit()


func _release_shard(shard_: ShardData) -> void:
	shard_.claim_id = -1
	for worker in workers:
		if worker.carry_id == shard_.id:
			continue
		if worker.target_shard_id != shard_.id:
			continue
		if worker.intent_stack_id >= 0:
			var stack := get_stack_data(worker.intent_stack_id)
			if stack != null and stack.claim_id == worker.id:
				stack.claim_id = -1
		worker.target_shard_id = -1
		worker.intent_stack_id = -1
		worker.intent_port = Bozo.Port.NONE
		worker.duty = Bozo.Duty.IDLE
		worker.aim = worker.home
		worker.changed.emit()


func _advance_mines(delta_: float) -> void:
	var reach := Catalog.DEPOSIT_RADIUS + Catalog.BODY_RADIUS + 16.0
	for worker in workers:
		if worker.kind != Bozo.Kind.MINER or worker.deposit_id < 0:
			continue
		var deposit := _deposit_by_id(worker.deposit_id)
		if deposit == null:
			continue
		if worker.position.distance_to(deposit.position) > reach:
			worker.click_ratio = 0.0
			continue
		var pace := Catalog.speed_mult(worker.speed_level)
		var span: float = Gear.mine_interval[deposit.quality] / pace
		worker.click_clock += delta_
		while worker.click_clock >= span:
			worker.click_clock -= span
			_dig(deposit)
		worker.click_ratio = 0.0 if span <= 0.0 else clampf(worker.click_clock / span, 0.0, 1.0)
		worker.changed.emit()


func _advance_trees(delta_: float) -> void:
	var span: float = Gear.tree_interval[Gear.tempo]
	for tree in trees:
		if tree.value <= 0:
			continue
		tree.clock += delta_
		while tree.clock >= span and tree.value > 0:
			tree.clock -= span
			var bite := mini(ceili(sqrt(float(tree.value))), tree.value)
			if bite <= 0:
				break
			tree.value -= bite
			_spawn_fruit(tree.position, bite)
			tree.changed.emit()


func _spawn_fruit(at_: Vector2, hp_: int) -> void:
	var fruit := FruitData.new()
	fruit.id = next_fruit_id
	next_fruit_id += 1
	fruit.hp = hp_
	fruit.max_hp = hp_
	fruit.value = hp_
	var angle := Helper.rng.randf_range(0.0, TAU)
	var distance := Helper.rng.randf_range(Catalog.FRUIT_MIN, Catalog.FRUIT_MAX)
	fruit.position = at_ + Vector2.from_angle(angle) * distance
	fruits.append(fruit)
	fruit_spawned.emit(fruit)


func _advance_pests(delta_: float) -> void:
	pest_clock += delta_
	var span: float = Gear.pest_interval[Gear.tempo]
	if trees.is_empty():
		if pest_clock > span:
			pest_clock = span
		var doomed: Array[PestData] = []
		for pest in pests:
			doomed.append(pest)
		for pest in doomed:
			_remove_pest(pest)
		return
	while pests.size() < max_pests() and pest_clock >= span:
		pest_clock -= span
		_spawn_pest()
	for pest in pests:
		_tick_pest(pest, delta_)


func _spawn_pest() -> void:
	var pest := PestData.new()
	pest.id = next_pest_id
	next_pest_id += 1
	pest.hp = Catalog.PEST_HP
	var angle := Helper.rng.randf_range(0.0, TAU)
	pest.position = Vector2.from_angle(angle) * Catalog.PEST_RING
	pests.append(pest)
	pest_spawned.emit(pest)


func _tick_pest(pest_: PestData, delta_: float) -> void:
	pest_.patrol_clock += delta_
	var span: float = Gear.pest_retarget[Gear.tempo]
	var fruit := _fruit_by_id(pest_.fruit_id)
	if fruit == null or fruit.carried or not fruits.has(fruit):
		fruit = null
	if pest_.patrol_clock >= span or fruit == null:
		pest_.patrol_clock = 0.0
		fruit = _nearest_ground_fruit(pest_.position)
	if fruit == null:
		pest_.state = Bozo.PestState.IDLE
		pest_.fruit_id = -1
		pest_.aim = pest_.position
		pest_.changed.emit()
		return
	pest_.state = Bozo.PestState.CHASE
	pest_.fruit_id = fruit.id
	pest_.aim = fruit.position
	_eat_fruit(pest_, fruit, delta_)


func _eat_fruit(pest_: PestData, fruit_: FruitData, delta_: float) -> void:
	var offset := fruit_.position - pest_.position
	if offset.length() > _bite_reach():
		pest_.eat_clock = 0.0
		if not pest_.driven:
			pest_.position = _nudge(pest_.position, fruit_.position, delta_, Catalog.PEST_SPEED)
		pest_.changed.emit()
		return
	pest_.eat_clock += delta_
	var span: float = Gear.eat_interval[Gear.tempo]
	while pest_.eat_clock >= span and fruits.has(fruit_):
		pest_.eat_clock -= span
		fruit_.hp -= 1
		fruit_.changed.emit()
		if fruit_.hp <= 0:
			_lose_fruit(fruit_)
			pest_.eat_clock = 0.0
			break
	pest_.changed.emit()


func _nearest_ground_fruit(at_: Vector2) -> FruitData:
	var best: FruitData = null
	var dist := INF
	for fruit in fruits:
		if fruit.carried:
			continue
		var gap := at_.distance_to(fruit.position)
		if gap >= dist:
			continue
		dist = gap
		best = fruit
	return best


func _lose_fruit(fruit_: FruitData) -> void:
	_drop_fruit(fruit_, true)
	seasons_lost += 1
	score_changed.emit()


func _drop_fruit(fruit_: FruitData, _eaten_: bool) -> void:
	for worker in workers:
		if worker.target_fruit_id != fruit_.id:
			continue
		worker.target_fruit_id = -1
		worker.duty = Bozo.Duty.IDLE
		worker.changed.emit()
	for pest in pests:
		if pest.fruit_id == fruit_.id:
			pest.fruit_id = -1
	fruits.erase(fruit_)
	fruit_removed.emit(fruit_)


func _advance_towers(delta_: float) -> void:
	var span: float = Gear.tower_interval[Gear.tempo]
	for tower in towers:
		if tower.durability <= 0:
			continue
		tower.clock += delta_
		var foe := _foe_in(tower)
		if foe.is_empty():
			if tower.clock > span:
				tower.clock = span
			continue
		while tower.clock >= span and tower.durability > 0:
			foe = _foe_in(tower)
			if foe.is_empty():
				break
			tower.clock -= span
			tower.durability -= 1
			_spawn_arrow(tower, foe)
			tower.changed.emit()


func _foe_in(tower_: TowerData) -> Array:
	var reach := tower_.radius()
	var dist := reach
	var pest_hit: PestData = null
	var thief_hit: ThiefData = null
	for pest in pests:
		if pest.hp <= 0:
			continue
		var gap := tower_.position.distance_to(pest.position)
		if gap > reach or gap > dist:
			continue
		dist = gap
		pest_hit = pest
		thief_hit = null
	for thief in thieves:
		if thief.hp <= 0:
			continue
		var gap := tower_.position.distance_to(thief.position)
		if gap > reach or gap > dist:
			continue
		dist = gap
		pest_hit = null
		thief_hit = thief
	if pest_hit != null:
		return [pest_hit]
	if thief_hit != null:
		return [thief_hit]
	return []


func _spawn_arrow(tower_: TowerData, foe_: Array) -> void:
	var arrow := ArrowData.new()
	arrow.id = next_arrow_id
	next_arrow_id += 1
	arrow.position = tower_.position
	var at := tower_.position
	if foe_[0] is PestData:
		arrow.pest_id = (foe_[0] as PestData).id
		at = (foe_[0] as PestData).position
	elif foe_[0] is ThiefData:
		arrow.thief_id = (foe_[0] as ThiefData).id
		at = (foe_[0] as ThiefData).position
	arrow.aim = at
	arrow.angle = (at - tower_.position).angle()
	arrows.append(arrow)
	arrow_spawned.emit(arrow)


func _advance_arrows(delta_: float) -> void:
	var spent: Array[ArrowData] = []
	for arrow in arrows:
		var target := _arrow_target(arrow)
		if target == Vector2.INF:
			spent.append(arrow)
			continue
		arrow.aim = target
		var offset := target - arrow.position
		var dist := offset.length()
		var step := Catalog.ARROW_SPEED * delta_
		if not arrow.driven:
			if dist <= step + Catalog.ARROW_HIT:
				arrow.position = target
			elif dist > 0.0:
				arrow.position += offset * (step / dist)
				arrow.angle = offset.angle()
			arrow.changed.emit()
		if arrow.position.distance_to(target) > Catalog.ARROW_HIT:
			continue
		_hit_arrow(arrow)
		spent.append(arrow)
	for arrow in spent:
		if not arrows.has(arrow):
			continue
		arrows.erase(arrow)
		arrow_removed.emit(arrow)


func _remove_pest(pest_: PestData) -> void:
	if not pests.has(pest_):
		return
	pests.erase(pest_)
	pest_removed.emit(pest_)


func _arrow_target(arrow_: ArrowData) -> Vector2:
	var pest := _pest_by_id(arrow_.pest_id)
	if pest != null and pest.hp > 0:
		return pest.position
	var thief := _thief_by_id(arrow_.thief_id)
	if thief != null and thief.hp > 0:
		return thief.position
	return Vector2.INF


func _hit_arrow(arrow_: ArrowData) -> void:
	var pest := _pest_by_id(arrow_.pest_id)
	if pest != null and pest.hp > 0:
		pest.hp -= 1
		pest.changed.emit()
		if pest.hp <= 0:
			_remove_pest(pest)
		return
	var thief := _thief_by_id(arrow_.thief_id)
	if thief == null or thief.hp <= 0:
		return
	thief.hp -= 1
	thief.changed.emit()
	if thief.hp <= 0:
		_drop_thief(thief)


func _advance_thieves(delta_: float) -> void:
	_ensure_barn()
	thief_clock += delta_
	var span: float = Gear.thief_interval[Gear.tempo]
	var gate := int(Catalog.WIN_NECTAR * 0.5)
	if barn.nectar < gate:
		if thief_clock > span:
			thief_clock = span
	else:
		while thieves.size() < Catalog.THIEF_CAP and thief_clock >= span:
			thief_clock -= span
			_spawn_thief()
	var living: Array[ThiefData] = []
	for thief in thieves:
		living.append(thief)
	for thief in living:
		_tick_thief(thief, delta_)


func _spawn_thief() -> void:
	var thief := ThiefData.new()
	thief.id = next_thief_id
	next_thief_id += 1
	thief.hp = Catalog.THIEF_HP
	var angle := Helper.rng.randf_range(0.0, TAU)
	thief.position = Vector2.from_angle(angle) * Catalog.PEST_RING
	thief.aim = _barn_point()
	thief.state = Bozo.ThiefState.TO_BARN
	thieves.append(thief)
	thief_spawned.emit(thief)


func _tick_thief(thief_: ThiefData, delta_: float) -> void:
	if thief_.state == Bozo.ThiefState.FLEE:
		var away := thief_.position
		if away.length() < 1.0:
			away = Vector2.RIGHT
		thief_.aim = away.normalized() * Catalog.PEST_RING
		if not thief_.driven:
			thief_.position = _nudge(thief_.position, thief_.aim, delta_, Catalog.PEST_SPEED)
			thief_.changed.emit()
		if thief_.position.length() >= Catalog.PEST_RING - 4.0:
			_escape_thief(thief_)
		return
	thief_.aim = _barn_point()
	if not thief_.driven:
		thief_.position = _nudge(thief_.position, thief_.aim, delta_, Catalog.PEST_SPEED)
		thief_.changed.emit()
	if thief_.position.distance_to(_barn_point()) <= Catalog.BARN_RADIUS + Catalog.BODY_RADIUS + 6.0:
		_steal(thief_)


func _steal(thief_: ThiefData) -> void:
	_ensure_barn()
	if barn.nectar <= 0:
		thief_.state = Bozo.ThiefState.FLEE
		return
	var bite := mini(ceili(sqrt(float(barn.nectar))), barn.nectar)
	barn.nectar -= bite
	var fruit := FruitData.new()
	fruit.id = next_fruit_id
	next_fruit_id += 1
	fruit.value = bite
	fruit.hp = bite
	fruit.max_hp = bite
	fruit.carried = true
	fruit.position = thief_.position
	fruits.append(fruit)
	fruit_spawned.emit(fruit)
	thief_.carry_fruit_id = fruit.id
	thief_.carried_offset = Vector2(14, 0)
	thief_.state = Bozo.ThiefState.FLEE
	fruit_stolen.emit(fruit, thief_)
	_emit_score()


func _escape_thief(thief_: ThiefData) -> void:
	var fruit := _fruit_by_id(thief_.carry_fruit_id)
	thief_.carry_fruit_id = -1
	if fruit != null and fruits.has(fruit):
		fruits.erase(fruit)
		fruit_removed.emit(fruit)
	_remove_thief(thief_)


func _drop_thief(thief_: ThiefData) -> void:
	var fruit := _fruit_by_id(thief_.carry_fruit_id)
	thief_.carry_fruit_id = -1
	if fruit != null:
		fruit.carried = false
		fruit.position = thief_.position
		fruit.changed.emit()
	_remove_thief(thief_)


func _remove_thief(thief_: ThiefData) -> void:
	if not thieves.has(thief_):
		return
	thieves.erase(thief_)
	thief_removed.emit(thief_)


func _spawn_barn() -> void:
	barn = BarnData.new()
	barn.position = Vector2.ZERO


func _spawn_houses() -> void:
	_add_house(Bozo.House.MINE, _hex_world(Bozo.Sector.SWAMP, 1, 0))
	_add_house(Bozo.House.GREENHOUSE, _hex_world(Bozo.Sector.JUNGLE, 1, 0))
	_add_house(Bozo.House.BARRACKS, _hex_world(Bozo.Sector.MOUNTAIN, 1, 0))
	_add_house(Bozo.House.WAREHOUSE, _hex_world(Bozo.Sector.SWAMP, 1, 1))


func _add_house(house_: int, at_: Vector2) -> void:
	var building := BuildingData.new()
	building.id = next_building_id
	next_building_id += 1
	building.house = house_
	building.position = at_
	buildings.append(building)
	building_spawned.emit(building)


func _hire_at(kind_: int, building_: BuildingData) -> WorkerData:
	var door := Vector2.ZERO
	if building_ != null:
		door = _scatter(building_)
	var worker := spawn_worker(kind_, door)
	if building_ != null:
		worker.building_id = building_.id
		worker.speed_level = building_.speed_level
	return worker


func _scatter(building_: BuildingData) -> Vector2:
	var door := building_.position + Vector2(0, Catalog.HOUSE_RADIUS + Catalog.BODY_RADIUS + 6.0)
	var shell := Catalog.HOUSE_RADIUS + Catalog.BODY_RADIUS + 4.0
	for _try in 20:
		var point := door + Vector2.from_angle(Helper.rng.randf_range(0.0, TAU)) * Helper.rng.randf_range(0.0, Catalog.SPAWN_SCATTER)
		if point.distance_to(building_.position) < shell:
			continue
		if _workers_clear(point):
			return point
	return door + Vector2.from_angle(TAU * float(workers.size()) / 10.0) * Catalog.SPAWN_SCATTER


func _workers_clear(point_: Vector2) -> bool:
	var gap := Catalog.BODY_RADIUS * 2.0
	for worker in workers:
		if worker.position.distance_to(point_) < gap:
			return false
	return true


func _house(house_: int) -> BuildingData:
	for building in buildings:
		if building.house == house_:
			return building
	return null


func _poorest(sector_: int) -> DepositData:
	var best: DepositData = null
	var dist := INF
	for deposit in deposits:
		if deposit.sector != sector_ or deposit.quality != Bozo.Quality.POOR:
			continue
		var gap := deposit.position.length()
		if gap >= dist:
			continue
		dist = gap
		best = deposit
	return best


func _hex_world(sector_: int, layer_: int, index_: int) -> Vector2:
	for hex in HexGrid.hexes_in_layer(layer_):
		if HexGrid.sector_of(hex, layer_) != sector_:
			continue
		if HexGrid.index_in_sector(hex, layer_) != index_:
			continue
		return HexGrid.axial_to_world(hex.x, hex.y)
	return Vector2(80, 80)


func _sync_crews() -> void:
	for deposit in deposits:
		var count := 0
		for worker in workers:
			if worker.kind == Bozo.Kind.MINER and worker.deposit_id == deposit.id:
				count += 1
		if deposit.crew == count:
			continue
		deposit.crew = count
		deposit.changed.emit()


func _sync_pace(worker_: WorkerData) -> void:
	var building := _building_by_id(worker_.building_id)
	if building == null:
		return
	worker_.speed_level = building.speed_level


func _pace(worker_: WorkerData) -> float:
	return Catalog.WORKER_SPEED * Catalog.speed_mult(worker_.speed_level)


func _reach(worker_: WorkerData) -> float:
	var touch := Catalog.BODY_RADIUS + 6.0
	match worker_.duty:
		Bozo.Duty.TO_FRUIT:
			return Catalog.FRUIT_RADIUS + touch
		Bozo.Duty.TO_BARN:
			return Catalog.BARN_RADIUS + touch
		Bozo.Duty.TO_SHARD, Bozo.Duty.TO_STACK:
			return Catalog.SHARD_CIRCUMRADIUS + touch
		_:
			return Catalog.ARRIVE


func _bite_reach() -> float:
	return Catalog.FRUIT_RADIUS + Catalog.BODY_RADIUS + 6.0


func _stack_spot(worker_: WorkerData, shard_: ShardData) -> Vector2:
	if worker_.kind != Bozo.Kind.HUNTER or trees.is_empty():
		return worker_.position
	var radius := float(shard_.volume) * Catalog.RADIUS_PER_VALUE
	var nearest: TreeNodeData = null
	var dist := INF
	for tree in trees:
		var gap := worker_.position.distance_to(tree.position)
		if gap >= dist:
			continue
		dist = gap
		nearest = tree
	if nearest == null or dist <= radius:
		return worker_.position
	var toward := worker_.position - nearest.position
	if toward.length() < 1.0:
		toward = Vector2.RIGHT
	return nearest.position + toward.normalized() * minf(radius * 0.6, dist)


func _tower_score(at_: Vector2, value_: int) -> float:
	var radius := float(value_) * Catalog.RADIUS_PER_VALUE
	if radius <= 0.0:
		return 0.0
	var score := 0.0
	for tree in trees:
		var gap := at_.distance_to(tree.position)
		if gap > radius:
			continue
		score += 1.0 + (1.0 - gap / radius)
	return score


func _lift_fruit(worker_: WorkerData, fruit_: FruitData) -> void:
	fruit_.carried = true
	fruit_.claim_id = worker_.id
	worker_.carry_fruit_id = fruit_.id
	worker_.carried_offset = fruit_.position - worker_.position
	worker_.carried_angle = 0.0
	fruit_lifted.emit(fruit_, worker_)
	worker_.changed.emit()


func _bank_fruit(fruit_: FruitData) -> void:
	if fruits.has(fruit_):
		fruits.erase(fruit_)
	fruit_removed.emit(fruit_)
	_ensure_barn()
	barn.nectar += fruit_.value
	if barn.nectar >= Catalog.WIN_NECTAR:
		is_won = true
	_emit_score()


func _barn_point() -> Vector2:
	_ensure_barn()
	return barn.position


func _ensure_barn() -> void:
	if barn != null:
		return
	barn = BarnData.new()


func _emit_score() -> void:
	if barn != null:
		barn.changed.emit()
	score_changed.emit()


func _nudge(from_: Vector2, to_: Vector2, delta_: float, speed_: float) -> Vector2:
	var offset := to_ - from_
	var dist := offset.length()
	if dist <= Catalog.ARRIVE:
		return to_
	var step := speed_ * delta_
	if step >= dist:
		return to_
	return from_ + offset * (step / dist)


func _building_by_id(id_: int) -> BuildingData:
	if id_ < 0:
		return null
	for building in buildings:
		if building.id == id_:
			return building
	return null


func _thief_by_id(id_: int) -> ThiefData:
	if id_ < 0:
		return null
	for thief in thieves:
		if thief.id == id_:
			return thief
	return null


func _form_stack(stack_: StackData, form_: int) -> void:
	stack_.form = form_
	stack_.changed.emit()
	if form_ == Bozo.Form.TOWER:
		var tower := TowerData.new()
		tower.id = next_tower_id
		next_tower_id += 1
		tower.stack_id = stack_.id
		tower.position = stack_.origin
		tower.value = stack_.total
		tower.durability = stack_.total
		towers.append(tower)
		tower_spawned.emit(tower)
		return
	var tree := TreeNodeData.new()
	tree.id = next_tree_id
	next_tree_id += 1
	tree.stack_id = stack_.id
	tree.position = stack_.origin
	tree.alpha_sum = stack_.alpha_sum
	tree.beta_multiplier = stack_.beta_multiplier
	tree.crown = stack_.crown
	tree.value = stack_.crown
	trees.append(tree)
	tree_spawned.emit(tree)


func _add_deposit(axial_: Vector2i, sector_: int, quality_: int) -> void:
	var deposit := DepositData.new(next_deposit_id, axial_, sector_, quality_)
	next_deposit_id += 1
	deposits.append(deposit)
	deposit_spawned.emit(deposit)


func _place_edges(layer_: int, quality_: int) -> void:
	for hex in HexGrid.hexes_in_layer(layer_):
		var index := HexGrid.index_in_sector(hex, layer_)
		if index == 0 or index == layer_:
			_add_deposit(hex, HexGrid.sector_of(hex, layer_), quality_)


func _place_index(layer_: int, index_: int, quality_: int) -> void:
	for hex in HexGrid.hexes_in_layer(layer_):
		if HexGrid.index_in_sector(hex, layer_) != index_:
			continue
		_add_deposit(hex, HexGrid.sector_of(hex, layer_), quality_)


func _make_move(shard_: ShardData, stack_: StackData, port_: int) -> Move:
	var tip := stack_.get_tip()
	var move := Move.new()
	move.shard_id = shard_.id
	move.stack_id = stack_.id
	move.target_id = tip.id
	move.port = port_
	move.target_pos = tip.position
	move.world_pos = tip.position + Geometry.get_offset(port_)
	return move


func _take_stack_id() -> int:
	var id := next_stack_id
	next_stack_id += 1
	return id


func _shard(id_: int) -> ShardData:
	if id_ < 0 or not id_to_shard.has(id_):
		return null
	return id_to_shard[id_]


func _deposit_by_id(id_: int) -> DepositData:
	if id_ < 0:
		return null
	for deposit in deposits:
		if deposit.id == id_:
			return deposit
	return null


func _fruit_by_id(id_: int) -> FruitData:
	if id_ < 0:
		return null
	for fruit in fruits:
		if fruit.id == id_:
			return fruit
	return null


func _pest_by_id(id_: int) -> PestData:
	if id_ < 0:
		return null
	for pest in pests:
		if pest.id == id_:
			return pest
	return null


func restart() -> void:
	_wipe()
	build()


func to_save() -> Dictionary:
	var shard_rows: Array[Dictionary] = []
	for id in id_to_shard.keys():
		shard_rows.append(_save_shard(id_to_shard[id]))
	var stack_rows: Array[Dictionary] = []
	for stack in stacks:
		var ids: Array[int] = []
		for shard in stack.shards:
			ids.append(shard.id)
		stack_rows.append({
			"id": stack.id,
			"origin": _xy(stack.origin),
			"total": stack.total,
			"matter": stack.matter,
			"multiplier": stack.multiplier,
			"alpha_sum": stack.alpha_sum,
			"beta_multiplier": stack.beta_multiplier,
			"crown": stack.crown,
			"locked": stack.is_locked,
			"beta_used": stack.beta_used,
			"element": stack.element,
			"form": stack.form,
			"claim_id": stack.claim_id,
			"root_from": _xy(stack.root_from),
			"shard_ids": ids,
		})
	return {
		"version": 1,
		"elapsed": elapsed,
		"seasons_lost": seasons_lost,
		"is_won": is_won,
		"win_nectar": Catalog.WIN_NECTAR,
		"rng_seed": Helper.rng.seed,
		"rng_state": Helper.rng.state,
		"pest_clock": pest_clock,
		"thief_clock": thief_clock,
		"nectar": 0 if barn == null else barn.nectar,
		"next": {
			"shard": next_shard_id,
			"stack": next_stack_id,
			"deposit": next_deposit_id,
			"worker": next_worker_id,
			"tree": next_tree_id,
			"fruit": next_fruit_id,
			"pest": next_pest_id,
			"tower": next_tower_id,
			"arrow": next_arrow_id,
			"building": next_building_id,
			"thief": next_thief_id,
		},
		"shards": shard_rows,
		"ground_ids": _ids_of_ground(),
		"stacks": stack_rows,
		"deposits": _save_deposits(),
		"buildings": _save_buildings(),
		"trees": _save_trees(),
		"towers": _save_towers(),
		"fruits": _save_fruits(),
		"workers": _save_workers(),
		"pests": _save_pests(),
		"thieves": _save_thieves(),
	}


func restore(payload_: Dictionary) -> bool:
	if int(payload_.get("version", 0)) != 1:
		return false
	_wipe()
	var next: Dictionary = payload_.get("next", {})
	next_shard_id = _num(next.get("shard", 0))
	next_stack_id = _num(next.get("stack", 0))
	next_deposit_id = _num(next.get("deposit", 0))
	next_worker_id = _num(next.get("worker", 0))
	next_tree_id = _num(next.get("tree", 0))
	next_fruit_id = _num(next.get("fruit", 0))
	next_pest_id = _num(next.get("pest", 0))
	next_tower_id = _num(next.get("tower", 0))
	next_arrow_id = _num(next.get("arrow", 0))
	next_building_id = _num(next.get("building", 0))
	next_thief_id = _num(next.get("thief", 0))
	for row in payload_.get("shards", []):
		var shard := _load_shard(row)
		id_to_shard[shard.id] = shard
	for raw_id in payload_.get("ground_ids", []):
		var shard := _shard(_num(raw_id))
		if shard != null:
			ground.append(shard)
	for row in payload_.get("stacks", []):
		stacks.append(_load_stack(row))
	for row in payload_.get("deposits", []):
		deposits.append(_load_deposit(row))
	for row in payload_.get("buildings", []):
		buildings.append(_load_building(row))
	for row in payload_.get("trees", []):
		trees.append(_load_tree(row))
	for row in payload_.get("towers", []):
		towers.append(_load_tower(row))
	for row in payload_.get("fruits", []):
		fruits.append(_load_fruit(row))
	for row in payload_.get("workers", []):
		workers.append(_load_worker(row))
	for row in payload_.get("pests", []):
		pests.append(_load_pest(row))
	for row in payload_.get("thieves", []):
		thieves.append(_load_thief(row))
	barn = BarnData.new()
	barn.position = Vector2.ZERO
	barn.nectar = _num(payload_.get("nectar", 0))
	elapsed = float(payload_.get("elapsed", 0.0))
	seasons_lost = _num(payload_.get("seasons_lost", 0))
	is_won = bool(payload_.get("is_won", false))
	pest_clock = float(payload_.get("pest_clock", 0.0))
	thief_clock = float(payload_.get("thief_clock", 0.0))
	Helper.rng.seed = _num(payload_.get("rng_seed", 0))
	Helper.rng.state = _num(payload_.get("rng_state", 0))
	phase = Bozo.Phase.IDLE
	selected = null
	selected_worker = null
	return true


func _wipe() -> void:
	deposits.clear()
	ground.clear()
	stacks.clear()
	workers.clear()
	trees.clear()
	fruits.clear()
	pests.clear()
	towers.clear()
	arrows.clear()
	buildings.clear()
	thieves.clear()
	id_to_shard.clear()
	barn = null
	selected = null
	selected_worker = null
	phase = Bozo.Phase.IDLE
	seasons_lost = 0
	is_won = false
	pest_clock = 0.0
	thief_clock = 0.0
	elapsed = 0.0
	next_shard_id = 0
	next_stack_id = 0
	next_deposit_id = 0
	next_worker_id = 0
	next_tree_id = 0
	next_fruit_id = 0
	next_pest_id = 0
	next_tower_id = 0
	next_arrow_id = 0
	next_building_id = 0
	next_thief_id = 0


func _save_shard(shard_: ShardData) -> Dictionary:
	return {
		"id": shard_.id,
		"matter": shard_.matter,
		"volume": shard_.volume,
		"multiplier": shard_.multiplier,
		"in_stack": shard_.is_in_stack,
		"stack_id": shard_.stack_id,
		"parent_id": shard_.parent_id,
		"port": shard_.attached_port,
		"position": _xy(shard_.position),
		"ports": shard_.open_ports.duplicate(),
		"bias": shard_.depth_bias,
		"shown": shard_.shown_total,
		"claim_id": shard_.claim_id,
	}


func _load_shard(row_: Dictionary) -> ShardData:
	var shard := ShardData.new(_num(row_.get("id", 0)), _num(row_.get("matter", 0)), _num(row_.get("volume", 0)))
	shard.multiplier = _num(row_.get("multiplier", 0))
	shard.is_in_stack = bool(row_.get("in_stack", false))
	shard.stack_id = _num(row_.get("stack_id", -1))
	shard.parent_id = _num(row_.get("parent_id", -1))
	shard.attached_port = _num(row_.get("port", 0))
	shard.position = _vec(row_.get("position", [0, 0]))
	shard.open_ports.clear()
	for port in row_.get("ports", []):
		shard.open_ports.append(_num(port))
	shard.depth_bias = _num(row_.get("bias", 0))
	shard.shown_total = _num(row_.get("shown", -1))
	shard.claim_id = _num(row_.get("claim_id", -1))
	return shard


func _load_stack(row_: Dictionary) -> StackData:
	var stack := StackData.new()
	stack.id = _num(row_.get("id", 0))
	stack.origin = _vec(row_.get("origin", [0, 0]))
	stack.total = _num(row_.get("total", 0))
	stack.matter = _num(row_.get("matter", 0))
	stack.multiplier = _num(row_.get("multiplier", 0))
	stack.alpha_sum = _num(row_.get("alpha_sum", 0))
	stack.beta_multiplier = _num(row_.get("beta_multiplier", 0))
	stack.crown = _num(row_.get("crown", 0))
	stack.is_locked = bool(row_.get("locked", false))
	stack.beta_used = bool(row_.get("beta_used", false))
	stack.element = _num(row_.get("element", 0))
	stack.form = _num(row_.get("form", 0))
	stack.claim_id = _num(row_.get("claim_id", -1))
	stack.root_from = _vec(row_.get("root_from", [0, 0]))
	for raw_id in row_.get("shard_ids", []):
		var shard := _shard(_num(raw_id))
		if shard != null:
			stack.shards.append(shard)
	return stack


func _save_deposits() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for deposit in deposits:
		rows.append({
			"id": deposit.id,
			"axial": [deposit.axial.x, deposit.axial.y],
			"sector": deposit.sector,
			"quality": deposit.quality,
			"progress": deposit.progress,
			"jammed": deposit.jammed,
			"crew": deposit.crew,
		})
	return rows


func _load_deposit(row_: Dictionary) -> DepositData:
	var axial: Array = row_.get("axial", [0, 0])
	var deposit := DepositData.new(_num(row_.get("id", 0)), Vector2i(_num(axial[0]), _num(axial[1])), _num(row_.get("sector", 0)), _num(row_.get("quality", 0)))
	deposit.progress = _num(row_.get("progress", 0))
	deposit.jammed = bool(row_.get("jammed", false))
	deposit.crew = _num(row_.get("crew", 0))
	return deposit


func _save_buildings() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for building in buildings:
		rows.append({
			"id": building.id,
			"house": building.house,
			"position": _xy(building.position),
			"hire_count": building.hire_count,
			"speed_level": building.speed_level,
		})
	return rows


func _load_building(row_: Dictionary) -> BuildingData:
	var building := BuildingData.new()
	building.id = _num(row_.get("id", 0))
	building.house = _num(row_.get("house", 0))
	building.position = _vec(row_.get("position", [0, 0]))
	building.hire_count = _num(row_.get("hire_count", 0))
	building.speed_level = _num(row_.get("speed_level", 0))
	return building


func _save_trees() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for tree in trees:
		rows.append({
			"id": tree.id,
			"stack_id": tree.stack_id,
			"position": _xy(tree.position),
			"value": tree.value,
			"alpha_sum": tree.alpha_sum,
			"beta_multiplier": tree.beta_multiplier,
			"crown": tree.crown,
			"clock": tree.clock,
		})
	return rows


func _load_tree(row_: Dictionary) -> TreeNodeData:
	var tree := TreeNodeData.new()
	tree.id = _num(row_.get("id", 0))
	tree.stack_id = _num(row_.get("stack_id", -1))
	tree.position = _vec(row_.get("position", [0, 0]))
	tree.value = _num(row_.get("value", 0))
	tree.alpha_sum = _num(row_.get("alpha_sum", 0))
	tree.beta_multiplier = _num(row_.get("beta_multiplier", 0))
	tree.crown = _num(row_.get("crown", 0))
	tree.clock = float(row_.get("clock", 0.0))
	return tree


func _save_towers() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for tower in towers:
		rows.append({
			"id": tower.id,
			"stack_id": tower.stack_id,
			"position": _xy(tower.position),
			"value": tower.value,
			"durability": tower.durability,
		})
	return rows


func _load_tower(row_: Dictionary) -> TowerData:
	var tower := TowerData.new()
	tower.id = _num(row_.get("id", 0))
	tower.stack_id = _num(row_.get("stack_id", -1))
	tower.position = _vec(row_.get("position", [0, 0]))
	tower.value = _num(row_.get("value", 0))
	tower.durability = _num(row_.get("durability", 0))
	return tower


func _save_fruits() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for fruit in fruits:
		rows.append({
			"id": fruit.id,
			"position": _xy(fruit.position),
			"hp": fruit.hp,
			"max_hp": fruit.max_hp,
			"value": fruit.value,
			"carried": fruit.carried,
			"claim_id": fruit.claim_id,
		})
	return rows


func _load_fruit(row_: Dictionary) -> FruitData:
	var fruit := FruitData.new()
	fruit.id = _num(row_.get("id", 0))
	fruit.position = _vec(row_.get("position", [0, 0]))
	fruit.hp = _num(row_.get("hp", 1))
	fruit.max_hp = _num(row_.get("max_hp", 1))
	fruit.value = _num(row_.get("value", 1))
	fruit.carried = bool(row_.get("carried", false))
	fruit.claim_id = _num(row_.get("claim_id", -1))
	return fruit


func _save_workers() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for worker in workers:
		rows.append({
			"id": worker.id,
			"kind": worker.kind,
			"position": _xy(worker.position),
			"home": _xy(worker.home),
			"aim": _xy(worker.aim),
			"duty": worker.duty,
			"deposit_id": worker.deposit_id,
			"target_shard_id": worker.target_shard_id,
			"target_fruit_id": worker.target_fruit_id,
			"intent_stack_id": worker.intent_stack_id,
			"intent_port": worker.intent_port,
			"carry_id": worker.carry_id,
			"carry_fruit_id": worker.carry_fruit_id,
			"carried_offset": _xy(worker.carried_offset),
			"carried_angle": worker.carried_angle,
			"facing": worker.facing,
			"building_id": worker.building_id,
			"speed_level": worker.speed_level,
			"click_clock": worker.click_clock,
			"click_ratio": worker.click_ratio,
			"dig_matter": worker.dig_matter,
		})
	return rows


func _load_worker(row_: Dictionary) -> WorkerData:
	var worker := WorkerData.new()
	worker.id = _num(row_.get("id", 0))
	worker.kind = _num(row_.get("kind", 0))
	worker.position = _vec(row_.get("position", [0, 0]))
	worker.home = _vec(row_.get("home", [0, 0]))
	worker.aim = _vec(row_.get("aim", [0, 0]))
	worker.duty = _num(row_.get("duty", 0))
	worker.deposit_id = _num(row_.get("deposit_id", -1))
	worker.target_shard_id = _num(row_.get("target_shard_id", -1))
	worker.target_fruit_id = _num(row_.get("target_fruit_id", -1))
	worker.intent_stack_id = _num(row_.get("intent_stack_id", -1))
	worker.intent_port = _num(row_.get("intent_port", 0))
	worker.carry_id = _num(row_.get("carry_id", -1))
	worker.carry_fruit_id = _num(row_.get("carry_fruit_id", -1))
	worker.carried_offset = _vec(row_.get("carried_offset", [0, 0]))
	worker.carried_angle = float(row_.get("carried_angle", 0.0))
	worker.facing = float(row_.get("facing", 0.0))
	worker.building_id = _num(row_.get("building_id", -1))
	worker.speed_level = _num(row_.get("speed_level", 0))
	worker.click_clock = float(row_.get("click_clock", 0.0))
	worker.click_ratio = float(row_.get("click_ratio", 0.0))
	worker.dig_matter = _num(row_.get("dig_matter", 0))
	return worker


func _save_pests() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for pest in pests:
		rows.append({
			"id": pest.id,
			"position": _xy(pest.position),
			"hp": pest.hp,
			"state": pest.state,
			"aim": _xy(pest.aim),
			"fruit_id": pest.fruit_id,
		})
	return rows


func _load_pest(row_: Dictionary) -> PestData:
	var pest := PestData.new()
	pest.id = _num(row_.get("id", 0))
	pest.position = _vec(row_.get("position", [0, 0]))
	pest.hp = _num(row_.get("hp", Catalog.PEST_HP))
	pest.state = _num(row_.get("state", Bozo.PestState.IDLE))
	pest.aim = _vec(row_.get("aim", [0, 0]))
	pest.fruit_id = _num(row_.get("fruit_id", -1))
	return pest


func _save_thieves() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for thief in thieves:
		rows.append({
			"id": thief.id,
			"position": _xy(thief.position),
			"aim": _xy(thief.aim),
			"hp": thief.hp,
			"state": thief.state,
			"carry_fruit_id": thief.carry_fruit_id,
			"carried_offset": _xy(thief.carried_offset),
		})
	return rows


func _load_thief(row_: Dictionary) -> ThiefData:
	var thief := ThiefData.new()
	thief.id = _num(row_.get("id", 0))
	thief.position = _vec(row_.get("position", [0, 0]))
	thief.aim = _vec(row_.get("aim", [0, 0]))
	thief.hp = _num(row_.get("hp", Catalog.THIEF_HP))
	thief.state = _num(row_.get("state", Bozo.ThiefState.TO_BARN))
	thief.carry_fruit_id = _num(row_.get("carry_fruit_id", -1))
	thief.carried_offset = _vec(row_.get("carried_offset", [0, 0]))
	return thief


func _ids_of_ground() -> Array[int]:
	var ids: Array[int] = []
	for shard in ground:
		ids.append(shard.id)
	return ids


func _xy(point_: Vector2) -> Array:
	return [point_.x, point_.y]


func _vec(raw_: Variant) -> Vector2:
	var pair: Array = raw_
	return Vector2(float(pair[0]), float(pair[1]))


func _num(raw_: Variant) -> int:
	return int(raw_)
