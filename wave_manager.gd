extends Node

## A quantidade cresce `COUNT_STEP` por onda até `MAX_COUNT`; velocidade, dano e vida das múmias crescem
## a cada onda, sem teto (o dano acaba matando com 1 hit).
## Parte da onda nasce de uma vez (`BURST`) em volta do jogador; o resto vai chegando
## aos poucos, na frente ou atrás de para onde ele está andando.

const ENEMY_SCENE     = preload("res://enemy.tscn")
const INITIAL_COUNT   = 12
const COUNT_STEP      = 8      # múmias a mais por onda (onda 10 = 84)
const MAX_COUNT       = 150    # teto de múmias por onda (chega na onda 19)
const SPEED_INCREMENT  = 1.3
const DAMAGE_INCREMENT = 1.3
const HP_INCREMENT     = 1.2
const BURST           := 30     # quantas nascem de uma vez no início da onda
const TRICKLE_EVERY   := 0.5    # segundos entre levas do resto da onda
const TRICKLE_TIME    := 12.0   # o resto da onda termina de chegar em ~12 s
const TRICKLE_SPREAD  := deg_to_rad(70.0)   # abertura do cone à frente/atrás

var wave        := 1
var count       := INITIAL_COUNT
var speed_mult  := 1.0
var damage_raw  := 10.0
var hp_raw      := 3.0
var _checking   := false
var _pending    := 0      # múmias da onda que ainda vão nascer aos poucos
var _per_tick   := 1
var _trickle_t  := 0.0

func _ready() -> void:
	add_to_group("wave_manager")
	call_deferred("_spawn_wave")

func _process(delta: float) -> void:
	if _pending <= 0:
		return
	_trickle_t -= delta
	if _trickle_t > 0.0:
		return
	_trickle_t = TRICKLE_EVERY
	for i in mini(_per_tick, _pending):
		_spawn_one(_trickle_position())
	_pending -= mini(_per_tick, _pending)

func on_enemy_died() -> void:
	if _checking:
		return
	_checking = true
	get_tree().create_timer(0.15).timeout.connect(_check_clear)

func _check_clear() -> void:
	_checking = false
	if _pending > 0 or get_tree().get_nodes_in_group("enemy").size() > 0:
		return
	wave       += 1
	count       = mini(count + COUNT_STEP, MAX_COUNT)
	speed_mult *= SPEED_INCREMENT
	damage_raw *= DAMAGE_INCREMENT
	hp_raw     *= HP_INCREMENT
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.set_wave(wave)
	_spawn_wave()

func _spawn_wave() -> void:
	var burst := mini(count, BURST)
	for i in burst:
		_spawn_one(spawn_point_near_player())
	_pending   = count - burst
	_per_tick  = maxi(1, ceili(_pending * TRICKLE_EVERY / TRICKLE_TIME))
	_trickle_t = TRICKLE_EVERY

func _spawn_one(pos: Vector2) -> void:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.speed_multiplier = speed_mult
	enemy.damage           = int(damage_raw)
	enemy.hp               = int(hp_raw)
	enemy.position         = pos
	get_parent().add_child(enemy)

## Mapa infinito: nasce num anel em volta do jogador, logo fora da tela.
const SPAWN_RING_MIN := 760.0
const SPAWN_RING_MAX := 900.0

func spawn_point_near_player() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	var center: Vector2 = player.global_position if player else Vector2(640, 360)
	return center + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(SPAWN_RING_MIN, SPAWN_RING_MAX)

## Leva aos poucos: sorteia frente ou atrás de para onde o jogador anda (parado = qualquer lado).
func _trickle_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.velocity.length() < 1.0:
		return spawn_point_near_player()
	var ang: float = player.velocity.angle() + randf_range(-TRICKLE_SPREAD, TRICKLE_SPREAD) / 2.0
	if randf() < 0.5:
		ang += PI
	return player.global_position + Vector2.RIGHT.rotated(ang) * randf_range(SPAWN_RING_MIN, SPAWN_RING_MAX)
