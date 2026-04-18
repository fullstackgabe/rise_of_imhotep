extends Node

const ENEMY_SCENE     = preload("res://enemy.tscn")
const INITIAL_COUNT   = 3
const SPEED_INCREMENT  = 1.3
const MAX_SPEED_MULT   = 2.5
const DAMAGE_INCREMENT = 1.3
const MAX_DAMAGE       = 30
const HP_INCREMENT     = 1.2
const MAX_ENEMY_HP     = 12
const MAX_ENEMIES      = 10

var wave        := 1
var count       := INITIAL_COUNT
var speed_mult  := 1.0
var damage_raw  := 10.0
var hp_raw      := 3.0
var _checking   := false

func _ready() -> void:
	add_to_group("wave_manager")
	call_deferred("_spawn_wave")

func on_enemy_died() -> void:
	if _checking:
		return
	_checking = true
	get_tree().create_timer(0.15).timeout.connect(_check_clear)

func _check_clear() -> void:
	_checking = false
	if get_tree().get_nodes_in_group("enemy").size() > 0:
		return
	wave        += 1
	count       *= 2
	speed_mult = minf(speed_mult * SPEED_INCREMENT,  MAX_SPEED_MULT)
	damage_raw = minf(damage_raw * DAMAGE_INCREMENT, float(MAX_DAMAGE))
	hp_raw     = minf(hp_raw    * HP_INCREMENT,      float(MAX_ENEMY_HP))
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.set_wave(wave)
	_spawn_wave()

func _spawn_wave() -> void:
	var to_spawn = min(count, MAX_ENEMIES)
	for i in to_spawn:
		var enemy = ENEMY_SCENE.instantiate()
		enemy.speed_multiplier = speed_mult
		enemy.damage           = int(damage_raw)
		enemy.hp               = int(hp_raw)
		enemy.position         = _spawn_position()
		get_parent().add_child(enemy)

func _spawn_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	var map    = get_tree().get_first_node_in_group("map")
	var margin := 80.0
	var max_x  := 1200.0
	var max_y  := 640.0
	if map:
		margin = map.TILE_SIZE * 2.0
		max_x  = (map.MAP_COLS - 2) * map.TILE_SIZE
		max_y  = (map.MAP_ROWS - 2) * map.TILE_SIZE
	for _attempt in 10:
		var pos = Vector2(randf_range(margin, max_x), randf_range(margin, max_y))
		if player == null or pos.distance_to(player.global_position) > 250.0:
			return pos
	return Vector2(margin, margin)
