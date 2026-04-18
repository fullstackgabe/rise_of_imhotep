extends CharacterBody2D

const BASE_SPEED         := 42.0
const PATH_REFRESH       := 0.25   # segundos entre recálculos de rota
const WAYPOINT_THRESHOLD := 16.0   # distância para considerar waypoint atingido

# Configuráveis pelo WaveManager antes de adicionar ao mundo
var speed_multiplier := 1.0
var hp               := 3
var damage           := 10

var _path          : PackedVector2Array = []
var _path_index    := 0
var _path_timer    := 0.0
var _facing        := "south"
var _dying         := false
var _is_flashing   := false
var _damage_cooldown  := 0.0
var _player_in_area   := false

const DAMAGE_INTERVAL := 1.0

func _ready() -> void:
	add_to_group("enemy")
	scale = Vector2(1.7, 1.7)
	_setup_animations()
	$Visual.play("idle_south")
	$HitArea.body_exited.connect(_on_hit_area_body_exited)

# --- Animações ---

func _setup_animations() -> void:
	var sf := SpriteFrames.new()
	for dir in ["south", "north", "east", "west"]:
		_add_idle_anim(sf, dir)
		_add_walk_anim(sf, dir)
	$Visual.sprite_frames = sf

func _add_idle_anim(sf: SpriteFrames, dir: String) -> void:
	# East frames are broken — reuse west (sprite will be flipped in code)
	var src_dir := "west" if dir == "east" else dir
	sf.add_animation("idle_" + dir)
	sf.set_animation_loop("idle_" + dir, true)
	sf.set_animation_speed("idle_" + dir, 8)
	sf.add_frame("idle_" + dir, load("res://characters/mummy/%s.png" % src_dir))

func _add_walk_anim(sf: SpriteFrames, dir: String) -> void:
	# East frames are broken — reuse west (sprite will be flipped in code)
	var src_dir := "west" if dir == "east" else dir
	sf.add_animation("walk_" + dir)
	sf.set_animation_loop("walk_" + dir, true)
	sf.set_animation_speed("walk_" + dir, 8)

	var loaded := false
	for i in 8:
		var path := "res://characters/mummy/walk/%s/frame_%03d.png" % [src_dir, i]
		if ResourceLoader.exists(path):
			sf.add_frame("walk_" + dir, load(path))
			loaded = true

	if not loaded:
		sf.add_frame("walk_" + dir, load("res://characters/mummy/%s.png" % src_dir))

# --- Movimento com A* ---

func _physics_process(delta: float) -> void:
	if _dying:
		return
	_path_timer += delta
	if _path_timer >= PATH_REFRESH:
		_path_timer = 0.0
		_refresh_path()
	_follow_path()

	# Dano contínuo enquanto player está dentro da HitArea
	if _player_in_area:
		_damage_cooldown -= delta
		if _damage_cooldown <= 0.0:
			var player = get_tree().get_first_node_in_group("player")
			if is_instance_valid(player) and not player.is_blinking:
				player.take_hit(damage)
				_damage_cooldown = DAMAGE_INTERVAL
			# se ainda está piscando, não reseta — checa de novo no próximo frame

func _refresh_path() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var map    = get_tree().get_first_node_in_group("map")
	if player == null or map == null:
		return
	var new_path = map.find_path(global_position, player.global_position)
	if not new_path.is_empty():
		_path       = new_path
		_path_index = 1

func _follow_path() -> void:
	if _path.is_empty() or _path_index >= _path.size():
		velocity = Vector2.ZERO
		move_and_slide()
		_facing = CharacterAnim.update_anim($Visual, Vector2.ZERO, _facing)
		$Visual.flip_h = (_facing == "east")
		return

	var to_next := _path[_path_index] - global_position
	if to_next.length() < WAYPOINT_THRESHOLD:
		_path_index += 1

	var vel := to_next.normalized() * BASE_SPEED * speed_multiplier
	velocity = vel
	move_and_slide()
	_facing = CharacterAnim.update_anim($Visual, vel, _facing)
	$Visual.flip_h = (_facing == "east")

# --- Vida e dano ---

func take_damage(amount: int = 1) -> void:
	if _dying:
		return
	hp -= amount
	_flash()
	if hp <= 0:
		_die()

func _die() -> void:
	_dying = true
	remove_from_group("enemy")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$HitArea/AreaShape.set_deferred("disabled", true)

	var wm = get_tree().get_first_node_in_group("wave_manager")
	if wm:
		wm.on_enemy_died()

	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_xp(PlayerStats.XP_PER_KILL)

	queue_free()

func _flash() -> void:
	if _is_flashing:
		return
	_is_flashing = true
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)
		_is_flashing = false

# --- Colisão com bala ou jogador ---

func _on_hit_area_body_entered(body: Node2D) -> void:
	if _dying or not is_instance_valid(body):
		return
	if body.is_in_group("bullet"):
		take_damage(body.damage)
		body.queue_free()
	elif body.is_in_group("player"):
		_player_in_area = true
		_damage_cooldown = 0.0  # aplica dano imediatamente na próxima tick

func _on_hit_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = false
		_damage_cooldown = 0.0
