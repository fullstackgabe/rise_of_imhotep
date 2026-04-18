extends Node2D

const BULLET     = preload("res://bullet.tscn")
const GUN_SCALE  = 0.7
const MUZZLE_LOCAL := Vector2(34.4, 2.0)  # ponta do cano em espaço local do nó

var _sprite : Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://tiles/gun.png")
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(GUN_SCALE, GUN_SCALE)
	_sprite.position = Vector2(12, 2)
	_sprite.z_index = 4
	add_child(_sprite)

func aim_at(world_pos: Vector2) -> void:
	rotation = (world_pos - global_position).angle()
	# Quando aponta para a esquerda, inverte Y para não ficar de ponta-cabeça
	var pointing_left := absf(rotation) > PI * 0.5
	_sprite.scale.y = -GUN_SCALE if pointing_left else GUN_SCALE

func shoot() -> void:
	var dir := Vector2.RIGHT.rotated(rotation)
	var bullet = BULLET.instantiate()
	bullet.direction = dir
	bullet.global_position = to_global(MUZZLE_LOCAL)
	get_tree().current_scene.add_child(bullet)
