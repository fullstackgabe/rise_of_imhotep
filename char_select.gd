extends Node2D

# Lista de personagens disponíveis para seleção.
const CHARS := [
	{ "id": "rick",   "name": "Rick O'Connell",  "desc": "Soldado aventureiro\nForça e velocidade",    "color": Color(0.3, 0.55, 1.0) },
	{ "id": "evelyn", "name": "Evelyn Carnahan",  "desc": "Exploradora corajosa\nAgilidade e precisão", "color": Color(1.0, 0.25, 0.25) },
]

var _selected_index := 0  # índice do personagem atualmente destacado
var _panel_styles   := []  # guarda o StyleBoxFlat de cada painel para atualizar a borda

func _ready() -> void:
	_build_ui()
	_update_selection()

# --- Construção da interface ---

func _build_ui() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_add_background()
	_add_title()
	_add_character_panels()
	_add_hint_label()

func _add_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.01)
	bg.size  = Vector2(1280, 720)
	add_child(bg)

func _add_title() -> void:
	var lbl := Label.new()
	lbl.text               = "ESCOLHER PERSONAGEM"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size               = Vector2(1280, 70)
	lbl.position           = Vector2(0, 60)
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	add_child(lbl)

func _add_character_panels() -> void:
	# Posiciona os painéis lado a lado, centrados na tela
	var positions := [Vector2(310, 180), Vector2(690, 180)]
	for i in CHARS.size():
		_create_panel(i, positions[i])

func _add_hint_label() -> void:
	var lbl := Label.new()
	lbl.text                 = "Selecione seu personagem"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size                 = Vector2(1280, 36)
	lbl.position             = Vector2(0, 135)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.55, 0.38))
	add_child(lbl)


# Cria o painel visual de um personagem (sprite + nome + descrição).
func _create_panel(idx: int, pos: Vector2) -> void:
	var data: Dictionary = CHARS[idx]

	# Container do painel com borda
	var border_color := Color(0.4, 0.3, 0.1)
	var panel_sty    := Styles.bordered(Color(0.12, 0.08, 0.04), border_color, 8, 3)
	var panel        := PanelContainer.new()
	panel.size     = Vector2(280, 420)
	panel.position = pos
	panel.add_theme_stylebox_override("panel", panel_sty)
	add_child(panel)

	# Layout vertical interno
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_add_sprite_preview(vbox, data)
	_add_panel_labels(vbox, data)

	# Seleciona ao passar o mouse por cima
	panel.mouse_entered.connect(func(): _select(idx))

	# Inicia partida ao clicar no painel
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_start_game())

	# Guarda o style para poder atualizar a borda ao selecionar
	_panel_styles.append(panel_sty)

func _add_sprite_preview(parent: Control, data: Dictionary) -> void:
	var path := "res://characters/%s/south.png" % data["id"]
	if not ResourceLoader.exists(path):
		# Mostra "?" se o sprite ainda não foi gerado
		var ph := Label.new()
		ph.text                = "?"
		ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph.add_theme_font_size_override("font_size", 48)
		ph.add_theme_color_override("font_color", data["color"])
		parent.add_child(ph)
		return

	var sp := TextureRect.new()
	sp.texture              = load(path)
	sp.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sp.custom_minimum_size  = Vector2(220, 220)
	sp.expand_mode          = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	parent.add_child(sp)

func _add_panel_labels(parent: Control, data: Dictionary) -> void:
	var name_lbl := Label.new()
	name_lbl.text                = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", data["color"])
	parent.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text                = data["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.5))
	parent.add_child(desc_lbl)

# --- Seleção por teclado ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_select((_selected_index - 1 + CHARS.size()) % CHARS.size())
	elif event.is_action_pressed("ui_right"):
		_select((_selected_index + 1) % CHARS.size())
	elif event.is_action_pressed("ui_accept"):
		_start_game()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://title_screen.tscn")

func _select(idx: int) -> void:
	_selected_index = idx
	_update_selection()

# Destaca o painel selecionado com borda dourada.
func _update_selection() -> void:
	for i in _panel_styles.size():
		var sty: StyleBoxFlat = _panel_styles[i]
		if i == _selected_index:
			sty.border_color        = Color(0.9, 0.75, 0.2)
			sty.border_width_top    = 4
			sty.border_width_bottom = 4
			sty.border_width_left   = 4
			sty.border_width_right  = 4
		else:
			sty.border_color        = Color(0.4, 0.3, 0.1)
			sty.border_width_top    = 3
			sty.border_width_bottom = 3
			sty.border_width_left   = 3
			sty.border_width_right  = 3

func _start_game() -> void:
	PlayerStats.selected_character = CHARS[_selected_index]["id"]
	get_tree().change_scene_to_file("res://main.tscn")
