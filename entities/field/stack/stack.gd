class_name Stack
extends Node2D


signal target_picked(shard_: ShardData, local_: Vector2)

const SHARD_SCENE := preload("res://entities/field/shard/shard.tscn")

var data: StackData:
	set(value_):
		data = value_
		position = data.origin
		if not data.shard_added.is_connected(_on_shard_added):
			data.shard_added.connect(_on_shard_added)
		if not data.changed.is_connected(_on_stack_changed):
			data.changed.connect(_on_stack_changed)
		_on_stack_changed()
		_init_shards()


func _on_stack_changed() -> void:
	visible = data != null and data.form == Bozo.Form.NONE


func apply_targets(moves_: Array[Move]) -> void:
	var ids: Dictionary = {}
	for move in moves_:
		if move.stack_id == data.id:
			ids[move.target_id] = true
	for child in %Shards.get_children():
		var view := child as Shard
		if view == null or view.data == null:
			continue
		view.apply_target(ids.has(view.data.id))


func _init_shards() -> void:
	Helper.clear_children(%Shards)
	for shard in data.shards:
		var from := data.root_from if data.root_flies and shard == data.shards[0] else shard.position
		_spawn(shard, from, from != shard.position)


func _on_shard_added(shard_: ShardData, from_: Vector2) -> void:
	_spawn(shard_, from_, true)


func _on_clicked(view_: Shard) -> void:
	if view_.data == null or not view_.is_target:
		return
	target_picked.emit(view_.data, view_.to_local(view_.get_global_mouse_position()))


func _spawn(shard_: ShardData, from_: Vector2, is_flying_: bool) -> void:
	var view := SHARD_SCENE.instantiate() as Shard
	view.anchor = data.origin
	%Shards.add_child(view)
	view.data = shard_
	view.clicked.connect(_on_clicked.bind(view))
	view.position = from_ - data.origin
	if is_flying_:
		view.fly_to(shard_.position)
		return
	view.position = shard_.position - data.origin
	view._apply_depth()
