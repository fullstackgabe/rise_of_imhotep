class_name CharacterAnim

# Popula idle + walk para as 4 direções num SpriteFrames existente.
static func setup_walk_dirs(sf: SpriteFrames, char_name: String, walk_fps: int) -> void:
	for dir in ["south", "north", "east", "west"]:
		sf.add_animation("idle_" + dir)
		sf.set_animation_loop("idle_" + dir, false)
		sf.set_animation_speed("idle_" + dir, 1)
		sf.add_frame("idle_" + dir, load("res://characters/%s/%s.png" % [char_name, dir]))
		sf.add_animation("walk_" + dir)
		sf.set_animation_loop("walk_" + dir, true)
		sf.set_animation_speed("walk_" + dir, walk_fps)
		for i in 8:
			sf.add_frame("walk_" + dir, load(
				"res://characters/%s/walk/%s/frame_%03d.png" % [char_name, dir, i]))

# Atualiza a animação com base na direção de movimento.
# Retorna o novo facing ("south", "north", "east" ou "west").
static func update_anim(sprite: AnimatedSprite2D, dir: Vector2, facing: String) -> String:
	var d := facing
	if dir != Vector2.ZERO:
		d = ("east" if dir.x > 0 else "west") if abs(dir.x) > abs(dir.y) \
			else ("south" if dir.y > 0 else "north")
	var anim := ("walk_" if dir != Vector2.ZERO else "idle_") + d
	if sprite.animation != anim:
		sprite.play(anim)
	return d
