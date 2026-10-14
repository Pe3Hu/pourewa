class_name Focus
extends Node2D


signal move_picked(move_: Move)

const MARKER_SCENE := preload("res://entities/field/focus/port_marker/port_marker.tscn")
const FRAME_SCENE := preload("res://entities/field/focus/frame/frame.tscn")


func _ready() -> void:
	z_index = Catalog.FOCUS_Z


func show_moves(moves_: Array[Move]) -> void:
	clear_moves()
	var seen: Dictionary = {}
	for move in moves_:
		if not seen.has(move.target_id):
			seen[move.target_id] = true
			var frame := FRAME_SCENE.instantiate() as Line2D
			frame.position = move.target_pos
			%Markers.add_child(frame)
		var marker := MARKER_SCENE.instantiate() as PortMarker
		%Markers.add_child(marker)
		marker.data = move
		marker.picked.connect(_on_marker_picked)


func clear_moves() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	for child in %Markers.get_children():
		%Markers.remove_child(child)
		child.queue_free()


func _on_marker_picked(move_: Move) -> void:
	move_picked.emit(move_)
