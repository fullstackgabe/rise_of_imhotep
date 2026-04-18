extends CharacterBody2D

const SPEED = 600.0
var direction := Vector2.ZERO
var damage    := 1

func _ready() -> void:
	add_to_group("bullet")
	damage = PlayerStats.bullet_dmg
	get_tree().create_timer(3.0).timeout.connect(queue_free)
	$Visual.texture = load("res://tiles/bullet.png")
	rotation = direction.angle()

func _physics_process(_delta: float) -> void:
	velocity = direction * SPEED
	move_and_slide()
	if get_slide_collision_count() > 0:
		queue_free()
