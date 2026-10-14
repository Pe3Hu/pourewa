extends Node


const _FIELD := preload("res://entities/field/field_data.gd")

var field


func _ready() -> void:
	field = _FIELD.new()
	field.build()
