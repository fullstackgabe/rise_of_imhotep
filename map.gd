extends Node2D

const TILE_SIZE = 40
const MAP_COLS  = 32
const MAP_ROWS  = 18

const COLOR_BG := Color(0.05, 0.03, 0.02)

var _grid := []
var astar  := AStarGrid2D.new()

# Tiles de parede — cada posição tem seu sprite dedicado
var _wall_h_tex    : Texture2D   # parede horizontal (topo/base)
var _wall_v_tex    : Texture2D   # parede vertical   (laterais)
var _corner_tl_tex : Texture2D   # canto topo-esquerda
var _corner_tr_tex : Texture2D   # canto topo-direita
var _corner_br_tex : Texture2D   # canto baixo-direita
var _corner_bl_tex : Texture2D   # canto baixo-esquerda

func _ready() -> void:
	add_to_group("map")
	_load_textures()
	_build_grid()
	_build_map()
	_setup_astar()

func _load_textures() -> void:
	var wall_tex   := load("res://tiles/tile_wall_pyramid.png") as Texture2D
	_wall_h_tex    = wall_tex
	_wall_v_tex    = wall_tex
	_corner_tl_tex = _try_load("res://tiles/corner_tl.png", wall_tex)
	_corner_tr_tex = _try_load("res://tiles/corner_tr.png", wall_tex)
	_corner_br_tex = _try_load("res://tiles/corner_br.png", wall_tex)
	_corner_bl_tex = _try_load("res://tiles/corner_bl.png", wall_tex)

func _try_load(path: String, fallback: Texture2D) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return fallback

# --- Grid ---

func _build_grid() -> void:
	_grid.resize(MAP_ROWS)
	for r in MAP_ROWS:
		_grid[r] = []
		_grid[r].resize(MAP_COLS)
		for c in MAP_COLS:
			_grid[r][c] = 1 if (r == 0 or r == MAP_ROWS - 1 or c == 0 or c == MAP_COLS - 1) else 0

func _is_wall(col: int, row: int) -> bool:
	if row < 0 or row >= MAP_ROWS or col < 0 or col >= MAP_COLS:
		return true
	return _grid[row][col] == 1

# --- Render ---

func _build_map() -> void:
	# Fundo escuro
	var bg := ColorRect.new()
	bg.size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	bg.color = COLOR_BG
	add_child(bg)

	# Chão — textura procedural de areia cobrindo o interior
	var floor_w := (MAP_COLS - 2) * TILE_SIZE
	var floor_h := (MAP_ROWS - 2) * TILE_SIZE
	var s := Sprite2D.new()
	s.texture = _make_sand_texture(256, 144)
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.position = Vector2(TILE_SIZE, TILE_SIZE)
	s.scale = Vector2(float(floor_w) / 256.0, float(floor_h) / 144.0)
	add_child(s)

	# Paredes — topo e base
	_place_wall_strip(1, 0,            MAP_COLS - 2, 1, _wall_h_tex, 0.0)
	_place_wall_strip(1, MAP_ROWS - 1, MAP_COLS - 2, 1, _wall_h_tex, PI)
	# Laterais — tile horizontal girado 90°
	_place_wall_strip(0,            1, 1, MAP_ROWS - 2, _wall_h_tex, PI * 1.5)
	_place_wall_strip(MAP_COLS - 1, 1, 1, MAP_ROWS - 2, _wall_h_tex, PI * 0.5)
	# 4 cantos
	_place_corner(0,            0,            _wall_h_tex, 0.0)
	_place_corner(MAP_COLS - 1, 0,            _wall_h_tex, 0.0)
	_place_corner(MAP_COLS - 1, MAP_ROWS - 1, _wall_h_tex, PI)
	_place_corner(0,            MAP_ROWS - 1, _wall_h_tex, PI)

func _make_sand_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in h:
		for x in w:
			var v := rng.randf_range(-0.08, 0.08)
			img.set_pixel(x, y, Color(
				clampf(0.55 + v, 0.0, 1.0),
				clampf(0.43 + v * 0.75, 0.0, 1.0),
				clampf(0.22 + v * 0.4, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

func _place_wall_strip(col: int, row: int, cols: int, rows: int, tex: Texture2D, rot: float = 0.0) -> void:
	var px := Vector2(col * TILE_SIZE, row * TILE_SIZE)
	var sz := Vector2(cols * TILE_SIZE, rows * TILE_SIZE)
	var sc := Vector2(float(TILE_SIZE) / tex.get_width(), float(TILE_SIZE) / tex.get_height())
	for r in rows:
		for c in cols:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.centered = true
			sp.scale = sc
			sp.rotation = rot
			sp.position = px + Vector2(c * TILE_SIZE + TILE_SIZE * 0.5, r * TILE_SIZE + TILE_SIZE * 0.5)
			add_child(sp)
	var body := StaticBody2D.new()
	body.position = px + sz / 2.0
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = sz
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _place_corner(col: int, row: int, tex: Texture2D, rot: float = 0.0) -> void:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.centered = true
	sp.scale = Vector2(float(TILE_SIZE) / tex.get_width(), float(TILE_SIZE) / tex.get_height())
	sp.rotation = rot
	sp.position = Vector2(col * TILE_SIZE + TILE_SIZE * 0.5, row * TILE_SIZE + TILE_SIZE * 0.5)
	add_child(sp)
	var body  := StaticBody2D.new()
	body.position = sp.position
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

# Iluminação ambiente fixa
func _add_ambient_dark() -> void:
	pass

# --- A* ---

func _setup_astar() -> void:
	astar.region        = Rect2i(0, 0, MAP_COLS, MAP_ROWS)
	astar.cell_size     = Vector2(TILE_SIZE, TILE_SIZE)
	astar.offset        = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for r in MAP_ROWS:
		for c in MAP_COLS:
			if _grid[r][c] == 1:
				astar.set_point_solid(Vector2i(c, r), true)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(
		clamp(int(pos.x / TILE_SIZE), 0, MAP_COLS - 1),
		clamp(int(pos.y / TILE_SIZE), 0, MAP_ROWS - 1)
	)

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var from_cell := world_to_grid(from)
	var to_cell   := world_to_grid(to)
	if astar.is_in_boundsv(from_cell) and astar.is_in_boundsv(to_cell):
		return astar.get_point_path(from_cell, to_cell)
	return PackedVector2Array()
