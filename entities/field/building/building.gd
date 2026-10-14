class_name Building
extends StaticBody2D


const LABEL_STYLE := preload("res://labels/default_label.tres")

signal hire_pressed(building_: BuildingData)
signal boost_pressed(building_: BuildingData)
signal panel_toggled(is_open_: bool)

@export var hit: Area2D
@export var title: Label
@export var hire: Button
@export var boost: Button
@export var close: Button

var data: BuildingData:
	set(value_):
		data = value_
		if data != null and not data.changed.is_connected(_on_changed):
			data.changed.connect(_on_changed)
		_on_changed()


var nectar: int = 0


func _ready() -> void:
	collision_mask = 0
	z_index = 65
	_style_controls()
	if data != null:
		_on_changed()


func apply_nectar(nectar_: int) -> void:
	nectar = nectar_
	_refresh()


func open_panel(is_open_: bool) -> void:
	$Panel.visible = is_open_


func is_open() -> bool:
	return $Panel.visible


func panel_rect() -> Rect2:
	return ($Panel as Control).get_global_rect()


func place_panel(obstacles_: Array[Rect2]) -> void:
	var panel := $Panel as Control
	var size := panel.size
	if size.x < 8.0 or size.y < 8.0:
		size = Vector2(240, 168)
	var spot := _free_spot(global_position, size, obstacles_)
	panel.global_position = spot - size * 0.5


func _draw() -> void:
	var color := Color(0.35, 0.38, 0.42)
	if data != null:
		match data.house:
			Bozo.House.MINE:
				color = Color(0.45, 0.4, 0.32)
			Bozo.House.GREENHOUSE:
				color = Color(0.28, 0.48, 0.36)
			Bozo.House.BARRACKS:
				color = Color(0.42, 0.3, 0.32)
			Bozo.House.WAREHOUSE:
				color = Color(0.4, 0.38, 0.28)
	draw_rect(Rect2(Vector2(-18, -16), Vector2(36, 32)), color)
	draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 16)), color.lightened(0.2))


func _on_changed() -> void:
	if data == null:
		return
	position = data.position
	collision_layer = Catalog.layer_for_house(data.house)
	_refresh()
	queue_redraw()


func _refresh() -> void:
	if data == null or title == null:
		return
	title.text = str(Digest.house_to_name[data.house])
	var hire_price := Catalog.hire_cost(data.hire_count)
	hire.text = "Нанять (%d)" % hire_price
	hire.disabled = nectar < hire_price
	var boost_price := Catalog.boost_cost(data.speed_level)
	boost.text = "Ускорить (уровень %d, %d)" % [data.speed_level, boost_price]
	boost.disabled = nectar < boost_price


func _on_input_event(viewport_: Viewport, event_: InputEvent, _shape_idx: int) -> void:
	if event_ is InputEventMouseButton and event_.pressed and event_.button_index == MOUSE_BUTTON_LEFT:
		viewport_.set_input_as_handled()
		var opening: bool = not $Panel.visible
		open_panel(opening)
		panel_toggled.emit(opening)


func _on_close() -> void:
	open_panel(false)


func _on_hire() -> void:
	if data != null:
		hire_pressed.emit(data)


func _on_boost() -> void:
	if data != null:
		boost_pressed.emit(data)


func _style_controls() -> void:
	if title != null:
		title.label_settings = LABEL_STYLE
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for button in [hire, boost, close]:
		if button == null:
			continue
		button.add_theme_font_size_override("font_size", LABEL_STYLE.font_size)
		button.add_theme_color_override("font_color", LABEL_STYLE.font_color)
		button.add_theme_color_override("font_disabled_color", Color(0.7, 0.25, 0.22))


func _free_spot(anchor_: Vector2, size_: Vector2, obstacles_: Array[Rect2]) -> Vector2:
	var candidates: Array[Vector2] = [
		anchor_ + Vector2(size_.x * 0.75, 0),
		anchor_ - Vector2(size_.x * 0.75, 0),
		anchor_ - Vector2(0, size_.y * 0.75),
		anchor_ + Vector2(0, size_.y * 0.75),
	]
	var near := maxf(size_.x, size_.y) * 0.9
	for step in 8:
		var angle := deg_to_rad(float(step) * 45.0)
		candidates.append(anchor_ + Vector2(cos(angle), sin(angle)) * near)
	var far := maxf(size_.x, size_.y) * 1.8
	for step in 12:
		var angle := deg_to_rad(float(step) * 30.0)
		candidates.append(anchor_ + Vector2(cos(angle), sin(angle)) * far)
	for spot in candidates:
		var rect := Rect2(spot - size_ * 0.5, size_).grow(8.0)
		var blocked := false
		for obstacle in obstacles_:
			if rect.intersects(obstacle):
				blocked = true
				break
		if not blocked:
			return _clamp_to_screen(spot, size_)
	return _clamp_to_screen(anchor_, size_)


func _clamp_to_screen(spot_: Vector2, size_: Vector2) -> Vector2:
	var screen := get_viewport().get_visible_rect()
	var to_world := get_viewport().get_canvas_transform().affine_inverse()
	var origin := to_world * screen.position
	var extent := to_world * screen.end
	var half := size_ * 0.5
	var x := clampf(spot_.x, origin.x + half.x, extent.x - half.x)
	var y := clampf(spot_.y, origin.y + half.y, extent.y - half.y)
	return Vector2(x, y)
