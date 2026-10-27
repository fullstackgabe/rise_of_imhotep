extends Node2D

## Cenário do mapa infinito: pirâmides, palmeiras e oásis espalhados por blocos
## (CHUNK px). Cada bloco sorteia o conteúdo com uma semente tirada da própria
## coordenada, então voltar a um lugar mostra as mesmas coisas. Blocos longe da
## câmera são apagados. Filho do Map, com y-sort junto do jogador e das múmias.
##
## Colisão só na base (pegada) do objeto, camada 1: segura jogador, múmias e balas.
## Dá para passar por trás da copa/do topo da pirâmide (o y-sort esconde quem está
## atrás) e, de lá, atirar para cima e para os lados — só o tiro que cruza a base
## bate. (O desenho inteiro como bloqueio de tiro prendia quem estava atrás.)
## O oásis é chão: só a água bloqueia o caminho (camada 5) e as balas passam por cima.

const CHUNK      := 1000.0
const KEEP_RANGE := 2          ## blocos mantidos em volta do bloco da câmera
const SAFE_SPOT  := Vector2(640, 360)   ## onde o jogador nasce: nada perto
const SAFE_RADIUS := 360.0

## Espaço livre entre objetos: dist mínima = raio de um + raio do outro + GAP.
const GAP := 140.0
const R_PYRAMID := 230.0
const R_PALM    := 60.0
const R_OASIS   := 230.0

## O y-sort usa a posição do nó; jogador e múmias têm o nó no meio do corpo,
## ~40 px acima do pé. O nó do objeto fica 40 px acima da base para empatar.
const SORT_LIFT := 40.0

const LAYER_SOLID := 1
const LAYER_WATER := 16

const PYRAMID := preload("res://props/pyramid.png")
const PALM    := preload("res://props/palm.png")
const OASIS   := preload("res://props/oasis.png")

var _chunks: Dictionary = {}   ## Vector2i -> Node2D

func _ready() -> void:
	y_sort_enabled = true
	z_index = 1   ## mesmo z do jogador e das múmias, senão o y-sort não vale entre eles

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else SAFE_SPOT
	var c := Vector2i((center / CHUNK).floor())
	for y in range(c.y - KEEP_RANGE, c.y + KEEP_RANGE + 1):
		for x in range(c.x - KEEP_RANGE, c.x + KEEP_RANGE + 1):
			var k := Vector2i(x, y)
			if not _chunks.has(k):
				_chunks[k] = _build_chunk(k)
	for k in _chunks.keys():
		if absi(k.x - c.x) > KEEP_RANGE + 1 or absi(k.y - c.y) > KEEP_RANGE + 1:
			_chunks[k].queue_free()
			_chunks.erase(k)

func _build_chunk(k: Vector2i) -> Node2D:
	var holder := Node2D.new()
	holder.y_sort_enabled = true
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k * 7919 + Vector2i(13, 101))
	var origin := Vector2(k) * CHUNK
	var spot := origin + Vector2(rng.randf_range(260, CHUNK - 260), rng.randf_range(300, CHUNK - 160))
	var roll := rng.randf()
	if _is_oasis_chunk(k):
		_try_add(holder, spot, _oasis, R_OASIS)
		for i in rng.randi_range(2, 3):
			var a := rng.randf() * TAU
			## palmeiras do oásis ficam coladas na beira (sem o GAP com a água)
			_try_add(holder, spot + Vector2(cos(a) * 300, sin(a) * 240), _palm, R_PALM, -GAP)
	elif roll < 0.35:
		_try_add(holder, spot, _pyramid, R_PYRAMID)
	else:
		for i in rng.randi_range(2, 3):
			_try_add(holder, spot + Vector2(rng.randf_range(-300, 300), rng.randf_range(-220, 220)), _palm, R_PALM)
	## Palmeira solta extra em metade dos blocos, para o deserto não ficar vazio.
	if rng.randf() < 0.5:
		_try_add(holder, origin + Vector2(rng.randf_range(80, CHUNK - 80), rng.randf_range(120, CHUNK - 40)), _palm, R_PALM)
	return holder

## Oásis espaçados: o mapa é dividido em regiões de OASIS_REGION×OASIS_REGION blocos e
## cada região sorteia no máximo um bloco com oásis (nunca na borda da região, para
## dois oásis de regiões vizinhas não ficarem colados).
const OASIS_REGION := 3
const OASIS_CHANCE := 0.75

func _is_oasis_chunk(k: Vector2i) -> bool:
	var region := Vector2i(floori(float(k.x) / OASIS_REGION), floori(float(k.y) / OASIS_REGION))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(region * 4099 + Vector2i(57, 3))
	if rng.randf() > OASIS_CHANCE:
		return false
	return k == region * OASIS_REGION + Vector2i(1, 1)

## Só coloca se ficar longe do spawn e de todo objeto já existente (inclusive dos
## blocos vizinhos).
func _try_add(holder: Node2D, base: Vector2, maker: Callable, radius: float, gap := GAP) -> void:
	if base.distance_to(SAFE_SPOT) < SAFE_RADIUS + radius:
		return
	for h in _chunks.values() + [holder]:
		for other in h.get_children():
			var min_d: float = radius + float(other.get_meta("radius", 0.0)) + gap
			if other.get_meta("base", Vector2.INF).distance_to(base) < min_d:
				return
	var node: Node2D = maker.call(base)
	node.set_meta("radius", radius)
	holder.add_child(node)

# ---------------------------------------------------------------------------

func _body(base: Vector2, layer: int) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = layer
	b.collision_mask  = 0
	b.position = base - Vector2(0, SORT_LIFT)
	b.set_meta("base", base)
	return b

## Sprite com a base (pé) da imagem no ponto `base`.
func _sprite(b: StaticBody2D, tex: Texture2D, scale_k: float, base_px: float) -> void:
	var s := Sprite2D.new()
	s.texture        = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale          = Vector2.ONE * scale_k
	s.centered       = false
	s.position = Vector2(-tex.get_width() * scale_k / 2.0, SORT_LIFT - base_px * scale_k)
	b.add_child(s)

func _rect_shape(b: CollisionObject2D, size: Vector2, center_from_base: Vector2) -> void:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(0, SORT_LIFT) + center_from_base
	b.add_child(cs)

func _pyramid(base: Vector2) -> Node2D:
	const K := 3.0
	var b := _body(base, LAYER_SOLID)
	_sprite(b, PYRAMID, K, _content_bottom(PYRAMID))
	## pegada: a base quadrada vista em 3/4 ocupa a metade de baixo do desenho
	var used := PYRAMID.get_image().get_used_rect()
	_rect_shape(b, Vector2(used.size.x * K * 0.9, used.size.y * K * 0.5), Vector2(0, -used.size.y * K * 0.25))
	return b

func _palm(base: Vector2) -> Node2D:
	const K := 2.5
	var b := _body(base, LAYER_SOLID)
	_sprite(b, PALM, K, _content_bottom(PALM))
	_rect_shape(b, Vector2(34, 22), Vector2(0, -14))   ## pé do tronco
	return b

func _oasis(base: Vector2) -> Node2D:
	const K := 2.5
	var b := _body(base, LAYER_WATER)
	b.z_index = 0
	b.z_as_relative = false   ## sempre embaixo dos personagens (eles estão em z 1)
	_sprite(b, OASIS, K, OASIS.get_height() / 2.0)
	_rect_shape(b, Vector2(OASIS.get_width() * K * 0.6, OASIS.get_height() * K * 0.5), Vector2.ZERO)
	return b

static func _content_bottom(tex: Texture2D) -> float:
	return float(tex.get_image().get_used_rect().end.y)
