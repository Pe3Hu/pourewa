class_name Field
extends Node2D


const DEPOSIT_SCENE := preload("res://entities/field/deposit/deposit.tscn")
const SHARD_SCENE := preload("res://entities/field/shard/shard.tscn")
const STACK_SCENE := preload("res://entities/field/stack/stack.tscn")
const WORKER_SCENE := preload("res://entities/field/worker/worker.tscn")
const TREE_SCENE := preload("res://entities/field/tree/tree_node.tscn")
const FRUIT_SCENE := preload("res://entities/field/fruit/fruit.tscn")
const PEST_SCENE := preload("res://entities/field/pest/pest.tscn")
const TOWER_SCENE := preload("res://entities/field/tower/tower.tscn")
const ARROW_SCENE := preload("res://entities/field/arrow/arrow.tscn")
const BARN_SCENE := preload("res://entities/field/barn/barn.tscn")
const BUILDING_SCENE := preload("res://entities/field/building/building.tscn")
const THIEF_SCENE := preload("res://entities/field/thief/thief.tscn")
const LABEL_STYLE := preload("res://labels/default_label.tres")

@export var debug_enabled: bool = true

var data: FieldData:
	set(value_):
		data = value_
		_connect_data()
		_init_views()


func _ready() -> void:
	var viewport := get_viewport()
	viewport.physics_object_picking = true
	viewport.physics_object_picking_sort = true
	viewport.physics_object_picking_first_only = true
	add_to_group("field")
	_build_nav()
	$Camera2D.make_current()
	%DebugNectar.visible = debug_enabled
	%DebugNectar.add_theme_font_size_override("font_size", LABEL_STYLE.font_size)
	%DebugNectar.add_theme_color_override("font_color", LABEL_STYLE.font_color)
	%Nectar.label_settings = LABEL_STYLE
	%Season.label_settings = LABEL_STYLE
	%PestLimit.label_settings = LABEL_STYLE
	TestRules.run()
	data = Mother.field as FieldData
	_refresh_hud()


func _physics_process(delta_: float) -> void:
	if data == null:
		return
	data.advance(delta_)
	_refresh_hud()


func _input(event_: InputEvent) -> void:
	if data == null:
		return
	var click := event_ as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var open := _open_building()
	if open == null:
		return
	if open.panel_rect().has_point(get_global_mouse_position()):
		return
	if _hits_building(get_global_mouse_position()):
		return
	open.open_panel(false)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	get_viewport().set_input_as_handled()
	%PauseMenu.open()


func _build_nav() -> void:
	var poly := NavigationPolygon.new()
	poly.vertices = PackedVector2Array([
		Vector2(-1400, -1000),
		Vector2(1400, -1000),
		Vector2(1400, 1000),
		Vector2(-1400, 1000),
	])
	poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	$Navigation.navigation_polygon = poly


func reload_world() -> void:
	if data == null:
		return
	_init_views()
	_refresh_hud()
	queue_redraw()


func restart_world() -> void:
	if data == null:
		return
	data.set_block_signals(true)
	data.restart()
	data.set_block_signals(false)
	reload_world()


func _draw() -> void:
	draw_rect(Rect2(-4000, -3000, 8000, 6000), Color(0.50, 0.49, 0.46))
	draw_circle(Vector2.ZERO, 920.0, Color(0.56, 0.55, 0.52, 0.55))
	if data == null or not data.is_won:
		return
	var font := ThemeDB.fallback_font
	var banner := "WIN"
	var width := font.get_string_size(banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	draw_string(font, Vector2(-width * 0.5, -80), banner, HORIZONTAL_ALIGNMENT_CENTER, width, 64, Color(0.95, 0.9, 0.55))


func _connect_data() -> void:
	if data.shard_spawned.is_connected(_on_shard_spawned):
		return
	data.shard_spawned.connect(_on_shard_spawned)
	data.shard_removed.connect(_on_shard_removed)
	data.stack_spawned.connect(_on_stack_spawned)
	data.selection_changed.connect(_on_selection_changed)
	data.worker_spawned.connect(_on_worker_spawned)
	data.tree_spawned.connect(_on_tree_spawned)
	data.fruit_spawned.connect(_on_fruit_spawned)
	data.fruit_removed.connect(_on_fruit_removed)
	data.pest_spawned.connect(_on_pest_spawned)
	data.pest_removed.connect(_on_pest_removed)
	data.tower_spawned.connect(_on_tower_spawned)
	data.arrow_spawned.connect(_on_arrow_spawned)
	data.arrow_removed.connect(_on_arrow_removed)
	data.shard_lifted.connect(_on_shard_lifted)
	data.fruit_lifted.connect(_on_fruit_lifted)
	data.fruit_stolen.connect(_on_fruit_stolen)
	data.thief_spawned.connect(_on_thief_spawned)
	data.thief_removed.connect(_on_thief_removed)
	data.building_spawned.connect(_on_building_spawned)
	data.score_changed.connect(_on_score_changed)
	%Focus.move_picked.connect(_on_move_picked)


func _init_views() -> void:
	Helper.clear_children(%Deposits)
	Helper.clear_children(%Ground)
	Helper.clear_children(%Stacks)
	Helper.clear_children(%Workers)
	Helper.clear_children(%Trees)
	Helper.clear_children(%Towers)
	Helper.clear_children(%Fruits)
	Helper.clear_children(%Pests)
	Helper.clear_children(%Arrows)
	Helper.clear_children(%Barn)
	Helper.clear_children(%Buildings)
	Helper.clear_children(%Thieves)
	if data.barn != null:
		_add_barn(data.barn)
	for deposit in data.deposits:
		_add_deposit(deposit)
	for shard in data.ground:
		_add_ground(shard)
	for stack in data.stacks:
		_add_stack(stack)
	for worker in data.workers:
		_add_worker(worker)
	for tree in data.trees:
		_add_tree(tree)
	for tower in data.towers:
		_add_tower(tower)
	for fruit in data.fruits:
		_add_fruit(fruit)
	for pest in data.pests:
		_add_pest(pest)
	for arrow in data.arrows:
		_add_arrow(arrow)
	for building in data.buildings:
		_add_building(building)
	for thief in data.thieves:
		_add_thief(thief)
	_on_selection_changed()
	queue_redraw()


func _add_deposit(deposit_: DepositData) -> void:
	var view := DEPOSIT_SCENE.instantiate() as Deposit
	%Deposits.add_child(view)
	view.data = deposit_
	view.picked.connect(_on_deposit_picked)


func _add_ground(shard_: ShardData) -> void:
	var view := SHARD_SCENE.instantiate() as Shard
	%Ground.add_child(view)
	view.data = shard_
	view.clicked.connect(_on_ground_clicked.bind(shard_))


func _add_stack(stack_: StackData) -> void:
	var view := STACK_SCENE.instantiate() as Stack
	%Stacks.add_child(view)
	view.target_picked.connect(_on_target_picked)
	view.data = stack_


func _add_worker(worker_: WorkerData) -> void:
	var view := WORKER_SCENE.instantiate() as Worker
	%Workers.add_child(view)
	view.picked.connect(_on_worker_picked)
	view.data = worker_


func _add_tree(tree_: TreeNodeData) -> void:
	var view := TREE_SCENE.instantiate() as TreeNode
	%Trees.add_child(view)
	view.data = tree_


func _add_tower(tower_: TowerData) -> void:
	var view := TOWER_SCENE.instantiate() as Tower
	%Towers.add_child(view)
	view.data = tower_


func _add_fruit(fruit_: FruitData) -> void:
	var view := FRUIT_SCENE.instantiate() as Fruit
	%Fruits.add_child(view)
	view.picked.connect(_on_fruit_picked)
	view.data = fruit_


func _add_pest(pest_: PestData) -> void:
	var view := PEST_SCENE.instantiate() as Pest
	%Pests.add_child(view)
	view.data = pest_


func _add_arrow(arrow_: ArrowData) -> void:
	var view := ARROW_SCENE.instantiate() as Arrow
	%Arrows.add_child(view)
	view.data = arrow_


func _on_deposit_picked(deposit_: DepositData) -> void:
	if data.phase == Bozo.Phase.ASSIGN_WORKER and data.selected_worker != null and data.selected_worker.kind == Bozo.Kind.MINER:
		data.assign_miner(data.selected_worker, deposit_)
		return
	data.mine(deposit_)


func _on_ground_clicked(shard_: ShardData) -> void:
	data.apply_selection(shard_)


func _on_worker_picked(worker_: WorkerData) -> void:
	data.select_worker(worker_)


func _on_fruit_picked(fruit_: FruitData) -> void:
	data.collect_fruit(fruit_)


func _on_shard_spawned(shard_: ShardData) -> void:
	_add_ground(shard_)


func _on_shard_removed(shard_: ShardData) -> void:
	var view := _find_shard(shard_)
	if view == null:
		return
	view.visible = false
	if view.hit != null:
		view.hit.input_pickable = false
	view.queue_free()


func _on_stack_spawned(stack_: StackData) -> void:
	_add_stack(stack_)


func _on_worker_spawned(worker_: WorkerData) -> void:
	_add_worker(worker_)


func _on_tree_spawned(tree_: TreeNodeData) -> void:
	_add_tree(tree_)


func _on_fruit_spawned(fruit_: FruitData) -> void:
	_add_fruit(fruit_)


func _on_fruit_removed(fruit_: FruitData) -> void:
	var view := _find_fruit(fruit_)
	if view != null:
		view.queue_free()


func _on_pest_spawned(pest_: PestData) -> void:
	_add_pest(pest_)


func _on_pest_removed(pest_: PestData) -> void:
	_free_data(%Pests, pest_)


func _on_tower_spawned(tower_: TowerData) -> void:
	_add_tower(tower_)


func _on_arrow_spawned(arrow_: ArrowData) -> void:
	_add_arrow(arrow_)


func _on_arrow_removed(arrow_: ArrowData) -> void:
	_free_data(%Arrows, arrow_)


func _on_score_changed() -> void:
	var nectar := 0 if data == null or data.barn == null else data.barn.nectar
	for child in %Buildings.get_children():
		var house := child as Building
		if house != null:
			house.apply_nectar(nectar)
	_refresh_hud()
	queue_redraw()


func _refresh_hud() -> void:
	if data == null:
		return
	var nectar := 0 if data.barn == null else data.barn.nectar
	%Nectar.text = "Нектар: %d / %d" % [nectar, Catalog.WIN_NECTAR]
	%Season.text = "Сезон: %d" % data.seasons_lost
	%PestLimit.text = "Обжоры: %d / %d" % [data.pests.size(), data.max_pests()]


func _on_debug_nectar() -> void:
	if data != null:
		data.debug_add_nectar(250)


func _open_building() -> Building:
	for child in %Buildings.get_children():
		var house := child as Building
		if house != null and house.is_open():
			return house
	return null


func _hits_building(point_: Vector2) -> bool:
	for building in data.buildings:
		if point_.distance_to(building.position) <= Catalog.HOUSE_RADIUS:
			return true
	return false


func _obstacle_rects(except_: BuildingData) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for building in data.buildings:
		if except_ != null and building.id == except_.id:
			continue
		rects.append(Rect2(building.position - Vector2(22, 20), Vector2(44, 40)))
	if data.barn != null:
		rects.append(Rect2(data.barn.position - Vector2(28, 36), Vector2(56, 72)))
	for deposit in data.deposits:
		var reach := Catalog.DEPOSIT_RADIUS
		rects.append(Rect2(deposit.position - Vector2(reach, reach), Vector2(reach, reach) * 2.0))
	for tree in data.trees:
		rects.append(Rect2(tree.position - Vector2(22, 30), Vector2(44, 60)))
	for tower in data.towers:
		rects.append(Rect2(tower.position - Vector2(16, 24), Vector2(32, 48)))
	return rects


func _add_barn(barn_: BarnData) -> void:
	var view := BARN_SCENE.instantiate() as Barn
	%Barn.add_child(view)
	view.data = barn_


func _add_building(building_: BuildingData) -> void:
	var view := BUILDING_SCENE.instantiate() as Building
	%Buildings.add_child(view)
	view.hire_pressed.connect(_on_hire_pressed)
	view.boost_pressed.connect(_on_boost_pressed)
	view.panel_toggled.connect(_on_panel_toggled.bind(view))
	view.data = building_
	view.apply_nectar(0 if data.barn == null else data.barn.nectar)


func _add_thief(thief_: ThiefData) -> void:
	var view := THIEF_SCENE.instantiate() as Thief
	%Thieves.add_child(view)
	view.data = thief_


func _on_building_spawned(building_: BuildingData) -> void:
	_add_building(building_)


func _on_thief_spawned(thief_: ThiefData) -> void:
	_add_thief(thief_)


func _on_thief_removed(thief_: ThiefData) -> void:
	var view := _holder(%Thieves, thief_)
	if view == null:
		return
	_release_fruit(view)
	view.queue_free()


func _on_hire_pressed(building_: BuildingData) -> void:
	if data != null:
		data.hire(building_)


func _on_boost_pressed(building_: BuildingData) -> void:
	if data != null:
		data.boost(building_)


func _on_panel_toggled(is_open_: bool, view_: Building) -> void:
	if not is_open_:
		return
	for child in %Buildings.get_children():
		if child == view_:
			continue
		var house := child as Building
		if house != null:
			house.open_panel(false)
	view_.place_panel(_obstacle_rects(view_.data))


func _on_shard_lifted(shard_: ShardData, worker_: WorkerData) -> void:
	var view := _find_shard(shard_)
	var holder := _holder(%Workers, worker_)
	if view == null or holder == null:
		return
	view.reparent(holder)
	view.collision_layer = 0
	if view.hit != null:
		view.hit.input_pickable = false
	view.global_position = holder.global_position + worker_.carried_offset
	view.global_rotation = worker_.carried_angle


func _on_fruit_lifted(fruit_: FruitData, worker_: WorkerData) -> void:
	var view := _find_fruit(fruit_)
	var holder := _holder(%Workers, worker_)
	if view == null or holder == null:
		return
	view.reparent(holder)
	view.collision_layer = 0
	if view.hit != null:
		view.hit.input_pickable = false
	view.global_position = holder.global_position + worker_.carried_offset
	view.global_rotation = worker_.carried_angle


func _on_fruit_stolen(fruit_: FruitData, thief_: ThiefData) -> void:
	var view := _find_fruit(fruit_)
	var holder := _holder(%Thieves, thief_)
	if view == null or holder == null:
		return
	view.reparent(holder)
	view.collision_layer = 0
	if view.hit != null:
		view.hit.input_pickable = false
	view.global_position = holder.global_position + thief_.carried_offset
	view.global_rotation = 0.0


func _find_shard(shard_: ShardData) -> Shard:
	var loose := _holder(%Ground, shard_) as Shard
	if loose != null:
		return loose
	for worker in %Workers.get_children():
		for child in worker.get_children():
			var view := child as Shard
			if view != null and view.data == shard_:
				return view
	return null


func _find_fruit(fruit_: FruitData) -> Fruit:
	for parent in [%Fruits, %Workers, %Thieves]:
		for child in parent.get_children():
			var view := child as Fruit
			if view != null and view.data == fruit_:
				return view
			for nested in child.get_children():
				var carried := nested as Fruit
				if carried != null and carried.data == fruit_:
					return carried
	return null


func _holder(parent_: Node, data_: Variant) -> Node:
	for child in parent_.get_children():
		if child.get("data") == data_:
			return child
	return null


func _release_fruit(holder_: Node) -> void:
	var carried: Array[Fruit] = []
	for child in holder_.get_children():
		var view := child as Fruit
		if view != null:
			carried.append(view)
	for view in carried:
		view.reparent(%Fruits)
		view.collision_layer = Catalog.LAYER_FRUIT
		view.rotation = 0.0
		if view.hit != null:
			view.hit.input_pickable = true
		var obstacle := view.get_node_or_null("Obstacle") as NavigationObstacle2D
		if obstacle != null:
			obstacle.avoidance_enabled = true
		if view.data != null:
			view.position = view.data.position


func _free_data(parent_: Node, data_: Variant) -> void:
	for child in parent_.get_children():
		if child.get("data") != data_:
			continue
		child.queue_free()
		return


func _on_move_picked(move_: Move) -> void:
	call_deferred("_apply_move", move_)


func _on_target_picked(shard_: ShardData, local_: Vector2) -> void:
	call_deferred("_place_on_tip", shard_, local_)


func _apply_move(move_: Move) -> void:
	if data == null:
		return
	data.apply_move(move_)


func _place_on_tip(shard_: ShardData, local_: Vector2) -> void:
	if data == null or data.selected == null or shard_ == null:
		return
	var matches: Array[Move] = []
	for move in data.find_moves(data.selected):
		if move.target_id == shard_.id:
			matches.append(move)
	if matches.is_empty():
		return
	if matches.size() == 1:
		data.apply_move(matches[0])
		return
	for move in matches:
		if Geometry.contains_point(Geometry.get_face_points(move.port), local_):
			data.apply_move(move)
			return


func _on_selection_changed() -> void:
	for child in %Ground.get_children():
		var view := child as Shard
		if view != null and view.data != null:
			view.apply_selected(view.data == data.selected)
	for child in %Workers.get_children():
		var worker := child as Worker
		if worker != null and worker.data != null:
			worker.apply_selected(worker.data == data.selected_worker)
	var moves: Array[Move] = []
	if data.selected == null:
		%Focus.clear_moves()
	else:
		moves = data.find_moves(data.selected)
		%Focus.show_moves(moves)
	for child in %Stacks.get_children():
		var stack := child as Stack
		if stack != null:
			stack.apply_targets(moves)


func _on_felt_input(viewport_: Viewport, event_: InputEvent, _shape_idx: int) -> void:
	if data == null:
		return
	if event_ is InputEventMouseButton and event_.pressed and event_.button_index == MOUSE_BUTTON_LEFT:
		if data.phase == Bozo.Phase.SELECT_SHARD:
			viewport_.set_input_as_handled()
			data.create_stack(get_global_mouse_position())
		elif data.phase == Bozo.Phase.ASSIGN_WORKER:
			viewport_.set_input_as_handled()
			data.clear_selection()
