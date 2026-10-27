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
	add_child(_sprite)

func aim_at(world_pos: Vector2, facing: String) -> void:
	aim_dir((world_pos - global_position).angle(), facing)

## Aponta para o ângulo `angle` (radianos). `facing` é a direção do sprite do jogador.
func aim_dir(angle: float, facing: String) -> void:
	rotation = angle
	# Quando aponta para a esquerda, inverte Y para não ficar de ponta-cabeça
	var pointing_left := absf(rotation) > PI * 0.5
	_sprite.scale.y = -GUN_SCALE if pointing_left else GUN_SCALE
	_update_layer(facing)

## A arma desenha na mesma camada do jogador (sem z_index próprio, senão aparece por
## cima de pirâmide/palmeira com o jogador escondido atrás). De costas (sprite north) ela
## fica atrás do corpo: vira o primeiro filho do jogador, antes do sprite (`Visual`);
## de frente ou de lado, na frente. Atira para qualquer lado em todos os casos.
var _behind := false

func _update_layer(facing: String) -> void:
	var behind := facing == "north"
	if behind == _behind:
		return
	_behind = behind
	get_parent().move_child(self, 0 if behind else -1)

func shoot() -> void:
	var dir := Vector2.RIGHT.rotated(rotation)
	var bullet = BULLET.instantiate()
	bullet.direction = dir
	bullet.global_position = to_global(MUZZLE_LOCAL)
	get_tree().current_scene.add_child(bullet)
