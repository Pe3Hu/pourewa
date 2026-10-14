extends Node


var tempo: int = 0
var fly: Array[float] = [0.25]
var reject: Array[float] = [0.22]
var deposit_flash: Array[float] = [0.28]
var tree_interval: Array[float] = [2.4]
var tower_interval: Array[float] = [1.2]
var pest_interval: Array[float] = [8.0]
var eat_interval: Array[float] = [1.0]
var thief_interval: Array[float] = [20.0]
var pest_retarget: Array[float] = [0.5]
var autosave_interval: Array[float] = [30.0]
var route_stuck: Array[float] = [2.0]
var route_direct: Array[float] = [0.5]
var mine_interval: Dictionary = {
	Bozo.Quality.POOR: 6.0,
	Bozo.Quality.COMMON: 4.0,
	Bozo.Quality.RICH: 2.0,
}
