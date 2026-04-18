extends CharacterBody2D

const WALK_FPS  := 10
const GunScript := preload("res://gun.gd")

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

	_gun.aim_at(get_global_mouse_position())

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = PlayerStats.fire_rate
		_gun.shoot()

	_regen_timer += delta
	if _regen_timer >= PlayerStats.regen_rate:
		_regen_timer = 0.0
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.heal(PlayerStats.regen_hp)

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
