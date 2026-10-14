extends Node


const SLOT_COUNT := 3
const AUTOSAVE_SLOT := 3

var _clock: float = 0.0


func _process(delta_: float) -> void:
	if get_tree().paused:
		return
	_clock += delta_
	if _clock < Gear.autosave_interval[Gear.tempo]:
		return
	_clock = 0.0
	call_deferred("_write", AUTOSAVE_SLOT)


func save_to_slot(slot_: int) -> void:
	_write(slot_)


func load_from_slot(slot_: int) -> bool:
	if not has_slot(slot_):
		return false
	var text := FileAccess.get_file_as_string(_path(slot_))
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return false
	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) != 1:
		push_warning("Слот %d записан другой версией." % slot_)
		return false
	if not Mother.field.restore(payload):
		return false
	var field := get_tree().get_first_node_in_group("field")
	if field != null and field.has_method("reload_world"):
		field.reload_world()
	return true


func slot_meta(slot_: int) -> Dictionary:
	var empty := {
		"elapsed_time": 0.0,
		"nectar_total": 0,
		"timestamp": "",
		"empty": true,
	}
	if not FileAccess.file_exists(_meta_path(slot_)):
		return empty
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_meta_path(slot_)))
	if parsed == null or not (parsed is Dictionary):
		return empty
	var meta: Dictionary = parsed
	meta["empty"] = false
	return meta


func has_slot(slot_: int) -> bool:
	return FileAccess.file_exists(_path(slot_))


func delete_slot(slot_: int) -> void:
	if FileAccess.file_exists(_path(slot_)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(slot_)))
	if FileAccess.file_exists(_meta_path(slot_)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_meta_path(slot_)))


func _write(slot_: int) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var payload: Dictionary = Mother.field.to_save()
	var file := FileAccess.open(_path(slot_), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()
	var meta := {
		"elapsed_time": float(payload.get("elapsed", 0.0)),
		"nectar_total": int(payload.get("nectar", 0)),
		"timestamp": Time.get_datetime_string_from_system(),
	}
	var side := FileAccess.open(_meta_path(slot_), FileAccess.WRITE)
	if side == null:
		return
	side.store_string(JSON.stringify(meta))
	side.close()


func _path(slot_: int) -> String:
	return "user://saves/slot_%d.json" % slot_


func _meta_path(slot_: int) -> String:
	return "user://saves/slot_%d.meta.json" % slot_
