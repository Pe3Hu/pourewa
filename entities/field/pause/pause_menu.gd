class_name PauseMenu
extends CanvasLayer


const LABEL_STYLE := preload("res://labels/default_label.tres")

@onready var _slots: Control = $Panel/Box/Slots


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_style($Panel/Box/Title as Label)
	for index in 4:
		var row := _row(index)
		_style(row.get_node("Text") as Label)
		row.get_node("Save").pressed.connect(_on_slot_save.bind(index))
		row.get_node("Load").pressed.connect(_on_slot_load.bind(index))
		row.get_node("Delete").pressed.connect(_on_slot_delete.bind(index))
	if _row(3).get_node("Save") != null:
		_row(3).get_node("Save").visible = false
		_row(3).get_node("Delete").visible = false


func open() -> void:
	_slots.visible = false
	visible = true
	get_tree().paused = true
	_refresh()


func resume() -> void:
	_slots.visible = false
	visible = false
	get_tree().paused = false


func _unhandled_input(event_: InputEvent) -> void:
	if not visible:
		return
	var key := event_ as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	get_viewport().set_input_as_handled()
	if _slots.visible:
		_slots.visible = false
		return
	resume()


func _on_continue() -> void:
	resume()


func _on_save_menu() -> void:
	_slots.visible = not _slots.visible
	_refresh()


func _on_restart() -> void:
	var field := get_tree().get_first_node_in_group("field")
	if field != null and field.has_method("restart_world"):
		field.restart_world()
	resume()


func _on_quit() -> void:
	get_tree().quit()


func _on_slot_save(slot_: int) -> void:
	SaveManager.save_to_slot(slot_)
	_refresh()


func _on_slot_load(slot_: int) -> void:
	if not SaveManager.load_from_slot(slot_):
		return
	resume()


func _on_slot_delete(slot_: int) -> void:
	SaveManager.delete_slot(slot_)
	_refresh()


func _refresh() -> void:
	for index in 4:
		var meta := SaveManager.slot_meta(index)
		var text: String = "пусто"
		if not bool(meta.get("empty", true)):
			var title := "AUTO" if index == SaveManager.AUTOSAVE_SLOT else "Слот %d" % (index + 1)
			text = "%s  %s | Нектар: %d  %s" % [
				title,
				_clock(float(meta.get("elapsed_time", 0.0))),
				int(meta.get("nectar_total", 0)),
				str(meta.get("timestamp", "")),
			]
		elif index == SaveManager.AUTOSAVE_SLOT:
			text = "AUTO  пусто"
		else:
			text = "Слот %d  пусто" % (index + 1)
		var row := _row(index)
		(row.get_node("Text") as Label).text = text
		var filled: bool = not bool(meta.get("empty", true))
		(row.get_node("Load") as Button).disabled = not filled
		(row.get_node("Delete") as Button).disabled = not filled or index == SaveManager.AUTOSAVE_SLOT


func _clock(seconds_: float) -> String:
	var total := int(seconds_)
	return "%02d:%02d" % [int(total / 60.0), total % 60]


func _row(index_: int) -> Node:
	return _slots.get_node("Slot%d" % index_)


func _style(label_: Label) -> void:
	if label_ == null:
		return
	label_.label_settings = LABEL_STYLE
	label_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
