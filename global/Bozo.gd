extends Node


# NONE = 0 у каждого enum. Остальные значения не повторяются между enum.

enum Port {
	NONE = 0,
	ALPHA = 1,
	BETA = 2,
	GAMMA = 3,
}

enum Matter {
	NONE = 0,
	GAS = 4,
	LIQUID = 5,
	SOLID = 6,
}

enum Quality {
	NONE = 0,
	POOR = 7,
	COMMON = 8,
	RICH = 9,
}

enum Sector {
	NONE = 0,
	SWAMP = 10,
	JUNGLE = 11,
	MOUNTAIN = 12,
}

enum Element {
	NONE = 0,
	CLOUD = 13,
	VAPOR = 14,
	DUST = 15,
	SAND = 16,
	ICE = 17,
	LAVA = 18,
}

enum Phase {
	NONE = 0,
	IDLE = 19,
	CLICK_DEPOSIT = 20,
	SELECT_SHARD = 21,
	SELECT_STACK_PORT = 22,
	ASSIGN_WORKER = 23,
	PAUSED = 24,
}

enum Kind {
	NONE = 0,
	MINER = 25,
	GARDENER = 26,
	HUNTER = 27,
	COLLECTOR = 28,
}

enum Duty {
	NONE = 0,
	IDLE = 29,
	TO_SHARD = 30,
	TO_STACK = 31,
	TO_DEPOSIT = 32,
	TO_FRUIT = 33,
	EAT = 34,
	TO_BARN = 48,
}

enum Form {
	NONE = 0,
	TREE = 35,
	TOWER = 36,
}

enum PestState {
	NONE = 0,
	CHASE = 37,
	PATROL = 38,
	ORBIT = 39,
	IDLE = 49,
}

enum ThiefState {
	NONE = 0,
	TO_BARN = 40,
	STEAL = 41,
	FLEE = 42,
	DEAD = 43,
}

enum House {
	NONE = 0,
	MINE = 44,
	GREENHOUSE = 45,
	BARRACKS = 46,
	WAREHOUSE = 47,
}
