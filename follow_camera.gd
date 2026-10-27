extends Camera2D

## Câmera que segue o jogador pelo mapa infinito.

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed   = 8.0

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		global_position = player.global_position
