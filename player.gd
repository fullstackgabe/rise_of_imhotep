extends CharacterBody2D

const WALK_FPS  := 10
const GunScript := preload("res://gun.gd")
const JoystickScript := preload("res://virtual_joystick.gd")
const AIM_RANGE := 600.0  # alcance máximo da mira automática, em pixels

var is_blinking  := false
var _fire_timer  := 0.0
var _regen_timer := 0.0
var _facing      := "south"
var _gun         : Node2D
var _joystick    : CanvasLayer   # joystick virtual de toque/clique

func _ready() -> void:
	add_to_group("player")
	scale = Vector2(2.0, 2.0)
	var sf := SpriteFrames.new()
	CharacterAnim.setup_walk_dirs(sf, PlayerStats.selected_character, WALK_FPS)
	$Visual.sprite_frames = sf
	$Visual.play("idle_south")
	_gun = GunScript.new()
	add_child(_gun)
	## Celular: joystick virtual. PC: só teclado (WASD + setas).
	## No editor, testar com Project Settings → Input Devices → Pointing → Emulate Touch From Mouse.
	if DisplayServer.is_touchscreen_available():
		_joystick = JoystickScript.new()
		add_child(_joystick)

# --- Movimento ---

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		clampf(Input.get_axis("ui_left", "ui_right") + _key_axis(KEY_A, KEY_D), -1.0, 1.0),
		clampf(Input.get_axis("ui_up", "ui_down") + _key_axis(KEY_W, KEY_S), -1.0, 1.0)
	)
	if direction == Vector2.ZERO and _joystick:
		direction = _joystick.direction
	velocity = direction.normalized() * PlayerStats.speed if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	_facing = CharacterAnim.update_anim($Visual, direction, _facing)

	# Mira automática: aponta e atira no inimigo mais próximo (estilo Brotato)
	var target := _nearest_enemy()
	if target:
		_gun.aim_at(target.global_position, _facing)
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = PlayerStats.fire_rate
			_gun.shoot()
	else:
		_fire_timer = 0.0  # pronto para atirar assim que um inimigo aparecer
		_gun.aim_dir(FACING_ANGLE[_facing], _facing)

	_regen_timer += delta
	if _regen_timer >= PlayerStats.regen_rate:
		_regen_timer = 0.0
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.heal(PlayerStats.regen_hp)

## WASD além das setas. Tecla física: no teclado AZERTY etc. fica na mesma posição.
func _key_axis(neg: Key, pos: Key) -> float:
	return float(Input.is_physical_key_pressed(pos)) - float(Input.is_physical_key_pressed(neg))

# --- Mira automática ---

## Só mira em quem dá para acertar: pula múmia com a base de uma pirâmide/palmeira
## no caminho (raio contra a camada do cenário, a mesma que segura as balas).
const SHOT_BLOCK_MASK := 1

## Sem alvo, a arma aponta para onde o jogador está virado.
const FACING_ANGLE := {"east": 0.0, "south": PI / 2.0, "west": PI, "north": -PI / 2.0}

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	# Inicia com o alcance máximo ao quadrado: inimigos além disso são ignorados
	var nearest_dist := AIM_RANGE * AIM_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < nearest_dist and _has_line_of_fire(e.global_position):
			nearest_dist = d
			nearest = e
	return nearest

func _has_line_of_fire(target: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(_gun.global_position, target, SHOT_BLOCK_MASK)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()

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

## Invulnerável enquanto pisca: 3 piscadas de 0.2 s = 0.6 s (era 6 × 0.24 = ~1.4 s).
func _do_blink() -> void:
	for i in 3:
		modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
	is_blinking = false
