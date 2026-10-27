extends Node2D

const PAN_PERIOD   := 26.0   # segundos para ir e voltar (era 40)
const BG_SCALE     := 3.6    # 400x200px * 3.6 = 1440x720 — cobre a altura exata de 1280x720
const BG_CROP_RIGHT := 4     # colunas defeituosas na borda direita de egypt_landscape.png

## A paisagem tem os morros escuros nas duas bordas (moldura), então não emenda
## consigo mesma: em vez de rolar em loop, uma cópia só passeia devagar de um
## lado para o outro e volta (sem emenda, sem sol duplicado).
var _bg : Sprite2D
var _pan_range := 0.0
var _t := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_add_background()
	_add_title()
	_add_start_button()

func _process(delta: float) -> void:
	if _bg == null:
		return
	_t += delta
	_bg.position.x = -_pan_range * (0.5 - 0.5 * cos(TAU * _t / PAN_PERIOD))

func _add_background() -> void:
	# Céu sólido por baixo (cor do pôr do sol egípcio)
	var sky := ColorRect.new()
	sky.color = Color(0.85, 0.5, 0.15)
	sky.size  = Vector2(1280, 720)
	add_child(sky)

	var tex := load("res://backgrounds/egypt_landscape.png") as Texture2D
	if tex == null:
		return

	_bg = Sprite2D.new()
	_bg.texture        = tex
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg.scale          = Vector2(BG_SCALE, BG_SCALE)
	_bg.centered       = false
	_bg.region_enabled = true
	_bg.region_rect    = Rect2(0, 0, tex.get_width() - BG_CROP_RIGHT, tex.get_height())
	add_child(_bg)
	_pan_range = maxf(0.0, _bg.region_rect.size.x * BG_SCALE - 1280.0)

func _add_title() -> void:
	var title := Label.new()
	title.text                     = "A  M Ú M I A"
	title.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	title.size                     = Vector2(1280, 100)
	title.position                 = Vector2(0, 180)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color",        Color(0.9, 0.75, 0.3))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var sub := Label.new()
	sub.text                   = "Sobreviva às hordas de Imhotep"
	sub.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	sub.size                   = Vector2(1280, 40)
	sub.position               = Vector2(0, 280)
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	add_child(sub)

func _add_start_button() -> void:
	var btn := Button.new()
	btn.text     = "INICIAR JOGO"
	btn.size     = Vector2(220, 60)
	btn.position = Vector2(530, 400)
	btn.add_theme_font_size_override("font_size", 28)
	Styles.gold_button(btn, Color(0.7, 0.5, 0.1), Color(0.9, 0.65, 0.15))
	btn.pressed.connect(_go_to_char_select)
	add_child(btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_go_to_char_select()

func _go_to_char_select() -> void:
	get_tree().change_scene_to_file("res://char_select.tscn")
