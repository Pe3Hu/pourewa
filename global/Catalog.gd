extends Node


const CARD_W := 48.0
const CARD_TOP_H := 24.0
const CARD_BODY_H := 36.0
const CARD_HALF_H := (CARD_BODY_H + CARD_TOP_H) * 0.5
const SHARD_CIRCUMRADIUS := CARD_W * 0.5
const DEPOSIT_RADIUS := SHARD_CIRCUMRADIUS * 2.0

const OFFSET_ALPHA := Vector2(0, -CARD_BODY_H)
const OFFSET_BETA := Vector2(CARD_W * 0.5, CARD_TOP_H * 0.5)
const OFFSET_GAMMA := Vector2(-CARD_W * 0.5, CARD_TOP_H * 0.5)

const ALPHA_BRIGHTNESS := 1.0
const BETA_BRIGHTNESS := 0.78
const GAMMA_BRIGHTNESS := 0.60

const LABEL_FONT_SIZE := 11
const SELECT_LIFT := 6.0
const STACK_CLEARANCE := 28.0

const HEX_SIZE := 64.0
const HEX_LAYERS := 5

const CLICKS_POOR := 3
const CLICKS_COMMON := 6
const CLICKS_RICH := 9

const SPAWN_MIN := DEPOSIT_RADIUS + SHARD_CIRCUMRADIUS + 8.0
const SPAWN_MAX := SPAWN_MIN + 40.0

const VIEW_W := 1920.0
const VIEW_H := 1080.0

const FELT_Z := -100
const DEPOSIT_Z := 40
const WORLD_Z := 500
const SELECT_Z := 3200
const FOCUS_Z := 3600

const WIN_NECTAR := 1000
const PEST_HP := 10
const THIEF_HP := 15
const PEST_CAP := 10
const THIEF_CAP := 3
const BODY_RADIUS := 10.0
const AVOID_WEIGHT := 0.6
const WORKER_ARC := 14.0
const ORBIT_MIN := 52.0
const ORBIT_MAX := 110.0
const BARN_RADIUS := 28.0
const HOUSE_RADIUS := 22.0
const RADIUS_PER_VALUE := 8.0
const WORKER_SPEED := 180.0
const PEST_SPEED := 100.0
const ARROW_SPEED := 520.0
const ARRIVE := 6.0
const BITE_REACH := 18.0
const ARROW_HIT := 8.0
const WORKER_RADIUS := 16.0
const FRUIT_RADIUS := 12.0
const PEST_RADIUS := 14.0
const FRUIT_MIN := 36.0
const FRUIT_MAX := 78.0
const PEST_RING := 760.0
const POST_OFFSET := Vector2(0, DEPOSIT_RADIUS + BODY_RADIUS + 6.0)
const SPAWN_SCATTER := 40.0
const AVOID_OUTER := 34.0
const AVOID_INNER := 16.0
const ARRIVE_RADIUS := 12.0
const NEAR_AIM := 24.0
const STACK_TOP_BUFFER := 3.0 * CARD_W
const SPAWN_ATTEMPTS := 40
const SHARD_GAP := 8.0

const LAYER_SHARD := 1
const LAYER_BARN := 2
const LAYER_MINE := 4
const LAYER_GREENHOUSE := 8
const LAYER_BARRACKS := 16
const LAYER_WAREHOUSE := 32
const LAYER_TREE := 64
const LAYER_TOWER := 128
const LAYER_DEPOSIT := 256
const LAYER_FRUIT := 512
const LAYER_WORKER := 1024
const LAYER_PEST := 2048


func hire_cost(index_: int) -> int:
	return fib_term(index_) * 10


func fib_term(index_: int) -> int:
	if index_ <= 0:
		return 1
	if index_ == 1:
		return 2
	var left := 1
	var right := 2
	for _step in range(index_ - 1):
		var nxt := left + right
		left = right
		right = nxt
	return right


func boost_cost(level_: int) -> int:
	var base := 10 + level_
	return base * base


func speed_mult(level_: int) -> float:
	return 1.0 + 0.25 * float(level_)


func mask_for_kind(kind_: int) -> int:
	var clutter := LAYER_SHARD
	match kind_:
		Bozo.Kind.MINER:
			return clutter | LAYER_MINE | LAYER_DEPOSIT
		Bozo.Kind.GARDENER:
			return clutter | LAYER_GREENHOUSE | LAYER_TREE
		Bozo.Kind.HUNTER:
			return clutter | LAYER_BARRACKS | LAYER_TOWER
		Bozo.Kind.COLLECTOR:
			return clutter | LAYER_BARN | LAYER_WAREHOUSE | LAYER_FRUIT
		_:
			return clutter


func layer_for_house(house_: int) -> int:
	match house_:
		Bozo.House.MINE:
			return LAYER_MINE
		Bozo.House.GREENHOUSE:
			return LAYER_GREENHOUSE
		Bozo.House.BARRACKS:
			return LAYER_BARRACKS
		Bozo.House.WAREHOUSE:
			return LAYER_WAREHOUSE
		_:
			return LAYER_SHARD


func mask_for_pest() -> int:
	return LAYER_SHARD | LAYER_TREE


func mask_for_thief() -> int:
	return LAYER_SHARD | LAYER_BARN | LAYER_TREE
