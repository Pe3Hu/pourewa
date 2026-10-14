class_name DepositData
extends RefCounted


signal changed
signal completed


var id: int = -1
var axial: Vector2i = Vector2i.ZERO
var position: Vector2 = Vector2.ZERO
var sector: int = Bozo.Sector.NONE
var matter: int = Bozo.Matter.NONE
var quality: int = Bozo.Quality.NONE
var progress: int = 0
var threshold: int = 1
var clock: float = 0.0
var crew: int = 0
var jammed: bool = false


func _init(id_: int, axial_: Vector2i, sector_: int, quality_: int) -> void:
	id = id_
	axial = axial_
	sector = sector_
	quality = quality_
	matter = Digest.sector_to_matter[sector_]
	threshold = Digest.quality_to_clicks[quality_]
	position = HexGrid.axial_to_world(axial_.x, axial_.y)


func add_progress() -> bool:
	progress += 1
	var filled := progress >= threshold
	if filled:
		progress = 0
	changed.emit()
	if filled:
		completed.emit()
	return filled
