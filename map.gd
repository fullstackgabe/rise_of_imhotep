extends Node2D

## Mapa infinito (estilo Vampire Survivors): sem paredes. O chão de areia é uma
## textura que se repete e acompanha a câmera, então dá para andar para qualquer
## lado sem fim. Grupo `map`.

const SAND_SIZE  := 256    ## textura procedural de areia (px), emenda nas bordas
const SAND_SCALE := 3.0    ## pixel do chão do mesmo tamanho dos pixels dos objetos (×2.5–3)

const PropsScript := preload("res://props.gd")

var _floor: Sprite2D

func _ready() -> void:
	add_to_group("map")
	y_sort_enabled = true   ## o cenário (props.gd) ordena junto com jogador e múmias
	_floor = Sprite2D.new()
	_floor.z_index        = -10
	_floor.texture        = _make_sand_texture(SAND_SIZE)
	_floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_floor.centered       = false
	_floor.region_enabled = true
	_floor.scale          = Vector2(SAND_SCALE, SAND_SCALE)
	add_child(_floor)
	var props := Node2D.new()
	props.set_script(PropsScript)
	add_child(props)
	_follow_camera()

func _process(_delta: float) -> void:
	_follow_camera()

## Reposiciona o chão em múltiplos do bloco para cobrir a tela + 1 bloco de folga.
func _follow_camera() -> void:
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else Vector2.ZERO
	var view   := get_viewport_rect().size / (cam.zoom if cam else Vector2.ONE)
	var block  := SAND_SIZE * SAND_SCALE
	var top_left := ((center - view / 2.0) / block).floor() * block
	var blocks := (view / block).ceil() + Vector2.ONE * 2.0
	_floor.position    = top_left
	_floor.region_rect = Rect2(Vector2.ZERO, blocks * SAND_SIZE)

## Areia em pixel art com a paleta da areia dos sprites (pirâmide, oásis, palmeira):
## as dunas (ruído que emenda) escolhem a faixa de tom, um pontilhado na borda das
## faixas suaviza a passagem e umas pedrinhas soltas quebram a repetição.
const SAND_PALETTE := [
	Color("c8955a"), Color("d6a466"), Color("e2b273"), Color("ebbf80"), Color("f3cd8e"),
]
const PEBBLE := Color("a77b4b")

func _make_sand_texture(size: int) -> Texture2D:
	var dunes := FastNoiseLite.new()
	dunes.seed      = 7
	dunes.frequency = 0.02
	dunes.fractal_octaves = 3
	var low := dunes.get_seamless_image(size, size)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n := SAND_PALETTE.size()
	for y in size:
		for x in size:
			var v := clampf(low.get_pixel(x, y).r, 0.0, 0.999) * n
			var i := int(v)
			## pontilhado: perto da borda da faixa, alguns pixels pegam o tom vizinho
			if v - i > 0.75 and (x + y) % 2 == 0 and i < n - 1:
				i += 1
			elif rng.randf() < 0.04:
				i = clampi(i + (1 if rng.randf() < 0.5 else -1), 0, n - 1)
			img.set_pixel(x, y, SAND_PALETTE[i])
	for i in size * size / 900:
		var px := rng.randi_range(0, size - 2)
		var py := rng.randi_range(0, size - 2)
		img.set_pixel(px, py, PEBBLE)
		if rng.randf() < 0.5:
			img.set_pixel(px + 1, py, PEBBLE)
	return ImageTexture.create_from_image(img)

## A rota até o jogador é a linha reta; quem contorna o cenário é a própria múmia (enemy.gd).
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return PackedVector2Array([from, to])
