extends Node


var matter_to_mult: Dictionary = {
	Bozo.Matter.GAS: 2,
	Bozo.Matter.LIQUID: 3,
	Bozo.Matter.SOLID: 5,
}

var matter_to_color: Dictionary = {
	Bozo.Matter.GAS: Color("#4FB4E0"),
	Bozo.Matter.LIQUID: Color("#3FBF7F"),
	Bozo.Matter.SOLID: Color("#9AA0A6"),
}

var sector_to_color: Dictionary = {
	Bozo.Sector.SWAMP: Color("#1E4D45"),
	Bozo.Sector.JUNGLE: Color("#1F6B3A"),
	Bozo.Sector.MOUNTAIN: Color("#5C564E"),
}

var sector_to_matter: Dictionary = {
	Bozo.Sector.SWAMP: Bozo.Matter.GAS,
	Bozo.Sector.JUNGLE: Bozo.Matter.LIQUID,
	Bozo.Sector.MOUNTAIN: Bozo.Matter.SOLID,
}

var port_to_brightness: Dictionary = {
	Bozo.Port.ALPHA: Catalog.ALPHA_BRIGHTNESS,
	Bozo.Port.BETA: Catalog.BETA_BRIGHTNESS,
	Bozo.Port.GAMMA: Catalog.GAMMA_BRIGHTNESS,
}

var port_to_highlight: Dictionary = {
	Bozo.Port.ALPHA: Color(0.45, 1.0, 0.55, 0.95),
	Bozo.Port.BETA: Color(1.0, 0.62, 0.2, 0.95),
}

var kind_to_color: Dictionary = {
	Bozo.Kind.MINER: Color(0.76, 0.48, 0.2),
	Bozo.Kind.GARDENER: Color(0.25, 0.48, 0.78),
	Bozo.Kind.HUNTER: Color(0.62, 0.24, 0.28),
	Bozo.Kind.COLLECTOR: Color(0.78, 0.66, 0.22),
}

var house_to_name: Dictionary = {
	Bozo.House.MINE: "Шахта",
	Bozo.House.GREENHOUSE: "Оранжерея",
	Bozo.House.BARRACKS: "Казарма",
	Bozo.House.WAREHOUSE: "Склад",
}

var house_to_kind: Dictionary = {
	Bozo.House.MINE: Bozo.Kind.MINER,
	Bozo.House.GREENHOUSE: Bozo.Kind.GARDENER,
	Bozo.House.BARRACKS: Bozo.Kind.HUNTER,
	Bozo.House.WAREHOUSE: Bozo.Kind.COLLECTOR,
}

var quality_to_clicks: Dictionary = {
	Bozo.Quality.POOR: Catalog.CLICKS_POOR,
	Bozo.Quality.COMMON: Catalog.CLICKS_COMMON,
	Bozo.Quality.RICH: Catalog.CLICKS_RICH,
}

var transition_to_element: Dictionary = {}
var deposit_rows: Dictionary = {}


func _ready() -> void:
	_fill_transitions()
	_fill_deposits()


func transition_key(from_: int, to_: int) -> int:
	return from_ * 32 + to_


func drop_key(matter_: int, quality_: int) -> int:
	return matter_ * 32 + quality_


func _fill_transitions() -> void:
	transition_to_element = {
		transition_key(Bozo.Matter.GAS, Bozo.Matter.LIQUID): Bozo.Element.CLOUD,
		transition_key(Bozo.Matter.LIQUID, Bozo.Matter.GAS): Bozo.Element.VAPOR,
		transition_key(Bozo.Matter.GAS, Bozo.Matter.SOLID): Bozo.Element.DUST,
		transition_key(Bozo.Matter.SOLID, Bozo.Matter.GAS): Bozo.Element.SAND,
		transition_key(Bozo.Matter.LIQUID, Bozo.Matter.SOLID): Bozo.Element.ICE,
		transition_key(Bozo.Matter.SOLID, Bozo.Matter.LIQUID): Bozo.Element.LAVA,
	}


func _fill_deposits() -> void:
	deposit_rows = {
		drop_key(Bozo.Matter.GAS, Bozo.Quality.POOR): [[2, 30], [4, 20], [6, 20], [18, 30]],
		drop_key(Bozo.Matter.GAS, Bozo.Quality.COMMON): [[2, 15], [8, 15], [10, 25], [20, 45]],
		drop_key(Bozo.Matter.GAS, Bozo.Quality.RICH): [[2, 25], [12, 20], [30, 25], [32, 30]],
		drop_key(Bozo.Matter.LIQUID, Bozo.Quality.POOR): [[3, 35], [6, 25], [12, 20], [15, 20]],
		drop_key(Bozo.Matter.LIQUID, Bozo.Quality.COMMON): [[3, 15], [9, 15], [15, 45], [18, 25]],
		drop_key(Bozo.Matter.LIQUID, Bozo.Quality.RICH): [[3, 25], [18, 20], [27, 30], [30, 25]],
		drop_key(Bozo.Matter.SOLID, Bozo.Quality.POOR): [[5, 55], [10, 30], [15, 15]],
		drop_key(Bozo.Matter.SOLID, Bozo.Quality.COMMON): [[5, 35], [10, 25], [20, 25], [25, 15]],
		drop_key(Bozo.Matter.SOLID, Bozo.Quality.RICH): [[5, 20], [15, 25], [25, 25], [30, 30]],
	}
