extends Node

const XP_PER_KILL := 10

var selected_character := "rick"  # "rick" ou "evelyn"

var speed      := 200.0
var bullet_dmg := 1
var resistance := 0
var fire_rate  := 0.25  # segundos entre tiros (menor = mais rápido)
var regen_hp   := 5     # HP regenerado por ciclo
var regen_rate := 8.0   # segundos entre cada regeneração

# Volta os atributos aos valores iniciais (chamado ao começar uma partida nova).
func reset() -> void:
	speed      = 200.0
	bullet_dmg = 1
	resistance = 0
	fire_rate  = 0.25
	regen_hp   = 5
	regen_rate = 8.0

func upgrade_speed() -> void:
	speed += 20.0

func upgrade_force() -> void:
	bullet_dmg += 1

func upgrade_resistance() -> void:
	resistance += 5

## Sem limite: cada upgrade corta 15% do intervalo (nunca chega a 0).
func upgrade_fire_rate() -> void:
	fire_rate *= 0.85

func upgrade_regen() -> void:
	regen_rate *= 0.85
