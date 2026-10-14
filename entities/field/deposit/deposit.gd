class_name Deposit
extends StaticBody2D


signal picked(deposit_: DepositData)

@export var hit: Area2D
@export var shape: CollisionShape2D

var data: DepositData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
			data.completed.connect(_on_completed)
		_on_changed()


var _flash: float = 0.0


func _ready() -> void:
	var circle := shape.shape as CircleShape2D
	if circle != null:
		circle.radius = Catalog.DEPOSIT_RADIUS
	collision_layer = Catalog.LAYER_DEPOSIT
	collision_mask = 0
	z_index = Catalog.DEPOSIT_Z
	set_process(false)
	if data != null:
		_on_changed()


func _process(delta_: float) -> void:
	_flash = maxf(_flash - delta_, 0.0)
	if _flash == 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var radius := Catalog.DEPOSIT_RADIUS
	var matter: Color = Digest.matter_to_color[data.matter]
	draw_circle(Vector2.ZERO, radius, Color(matter.r, matter.g, matter.b, 0.16))
	var track := Color(matter.r, matter.g, matter.b, 0.35)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, track, 2.5, true)
	var ratio := 0.0 if data.threshold == 0 else float(data.progress) / float(data.threshold)
	var shown := data.progress
	var arc := matter
	if _flash > 0.0:
		ratio = 1.0
		shown = data.threshold
		arc = matter.lerp(Color.WHITE, 0.7)
	if ratio > 0.0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU * ratio, 64, arc, 6.0, true)
	_draw_progress("%d/%d" % [shown, data.threshold])
	for index in data.crew:
		draw_circle(Vector2(-18.0 + float(index) * 9.0, radius + 14.0), 3.5, Color(0.9, 0.75, 0.35))
	if data.jammed:
		_draw_progress("!")


func _on_changed() -> void:
	if data == null:
		return
	position = data.position
	queue_redraw()


func _on_completed() -> void:
	_flash = Gear.deposit_flash[Gear.tempo]
	set_process(true)
	queue_redraw()


func _on_input_event(viewport_: Viewport, event_: InputEvent, _shape_idx: int) -> void:
	if event_ is InputEventMouseButton and event_.pressed and event_.button_index == MOUSE_BUTTON_LEFT:
		viewport_.set_input_as_handled()
		picked.emit(data)


func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _draw_progress(text_: String) -> void:
	var font := ThemeDB.fallback_font
	var size := 18
	var width := font.get_string_size(text_, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(-width * 0.5, size * 0.35)
	draw_string(font, pos + Vector2(1, 1), text_, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(1, 1, 1, 0.35))
	draw_string(font, pos, text_, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.08, 0.08, 0.08, 0.95))
