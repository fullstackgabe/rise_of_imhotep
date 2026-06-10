extends CharacterBody2D

const WALK_FPS  := 10
const GunScript := preload("res://gun.gd")
const AIM_RANGE := 600.0  # alcance máximo da mira automática, em pixels

var is_blinking  := false
var _fire_timer  := 0.0
var _regen_timer := 0.0
var _facing      := "south"
var _gun         : Node2D

func _ready() -> void:
	add_to_group("player")
	scale = Vector2(2.0, 2.0)
	var sf := SpriteFrames.new()
	CharacterAnim.setup_walk_dirs(sf, PlayerStats.selected_character, WALK_FPS)
	$Visual.sprite_frames = sf
	$Visual.play("idle_south")
	_gun = GunScript.new()
	add_child(_gun)

# --- Movimento ---

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	velocity = direction.normalized() * PlayerStats.speed if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	_facing = CharacterAnim.update_anim($Visual, direction, _facing)

	# Mira automática: aponta e atira no inimigo mais próximo (estilo Brotato)
	var target := _nearest_enemy()
	if target:
		_gun.aim_at(target.global_position)
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = PlayerStats.fire_rate
			_gun.shoot()
	else:
		_fire_timer = 0.0  # pronto para atirar assim que um inimigo aparecer

	_regen_timer += delta
	if _regen_timer >= PlayerStats.regen_rate:
		_regen_timer = 0.0
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.heal(PlayerStats.regen_hp)

# --- Mira automática ---

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	# Inicia com o alcance máximo ao quadrado: inimigos além disso são ignorados
	var nearest_dist := AIM_RANGE * AIM_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

# --- Receber dano ---

func take_hit(damage: int) -> void:
	if is_blinking:
		return
	is_blinking = true
	var effective: int = max(1, damage - PlayerStats.resistance)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.take_damage(effective)
	_do_blink()

func _do_blink() -> void:
	for i in 6:
		modulate.a = 0.2
		await get_tree().create_timer(0.12).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.12).timeout
	is_blinking = false
