extends CanvasLayer

var _level := 1

# --- Cores de tema de cada carta ---
const SPEED_COLOR := Color(0.35, 0.62, 1.00, 1)
const FORCE_COLOR := Color(1.00, 0.55, 0.18, 1)
const RES_COLOR   := Color(0.25, 0.82, 0.38, 1)
const FIRE_COLOR  := Color(0.72, 0.30, 1.00, 1)
const REGEN_COLOR := Color(0.15, 0.85, 0.70, 1)

# --- Estilo das cartas e botões ---

func _make_card_style(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = accent.darkened(0.68)
	s.border_color = accent
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left  = 8
	s.content_margin_left   = 16
	s.content_margin_right  = 16
	s.content_margin_top    = 16
	s.content_margin_bottom = 16
	return s

func _make_btn_style(color: Color, darken := 0.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color.darkened(darken)
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_right = 5
	s.corner_radius_bottom_left  = 5
	s.content_margin_left   = 8
	s.content_margin_right  = 8
	s.content_margin_top    = 7
	s.content_margin_bottom = 7
	return s

func _apply_card_theme(card_name: String, accent: Color) -> void:
	var card := get_node("Control/Panel/Margin/VBox/Cards/" + card_name)
	card.add_theme_stylebox_override("panel", _make_card_style(accent))
	var btn: Button = card.get_node("VBox/Btn")
	btn.add_theme_stylebox_override("normal",  _make_btn_style(accent))
	btn.add_theme_stylebox_override("hover",   _make_btn_style(accent, -0.18))
	btn.add_theme_stylebox_override("pressed", _make_btn_style(accent, 0.22))
	btn.add_theme_color_override("font_color", Color.WHITE)

# --- Ciclo de vida ---

func _ready() -> void:
	add_to_group("upgrade_modal")
	visible = false

	# Ícones pixel art (gerados pelo PixelLab)
	_card_icon("SpeedCard").texture  = load("res://icons/icon_speed.png")
	_card_icon("ForceCard").texture  = load("res://icons/icon_force.png")
	_card_icon("ResCard").texture    = load("res://icons/icon_resistance.png")
	_card_icon("FireCard").texture   = load("res://icons/icon_fire_rate.png")
	_card_icon("RegenCard").texture  = load("res://icons/icon_regen.png")

	# Temas de cor por carta
	_apply_card_theme("SpeedCard", SPEED_COLOR)
	_apply_card_theme("ForceCard", FORCE_COLOR)
	_apply_card_theme("ResCard",   RES_COLOR)
	_apply_card_theme("FireCard",  FIRE_COLOR)
	_apply_card_theme("RegenCard", REGEN_COLOR)

func _card_icon(card_name: String) -> TextureRect:
	return get_node("Control/Panel/Margin/VBox/Cards/" + card_name + "/VBox/Icon")

func _card_value(card_name: String) -> Label:
	return get_node("Control/Panel/Margin/VBox/Cards/" + card_name + "/VBox/Value")

func show_modal(level: int) -> void:
	_level = level
	get_node("Control/Panel/Margin/VBox/Header/LevelBadge").text = "NÍVEL %d" % level
	_card_value("SpeedCard").text  = "Atual: %.0f"  % PlayerStats.speed
	_card_value("ForceCard").text  = "Atual: %d"    % PlayerStats.bullet_dmg
	_card_value("ResCard").text    = "Atual: %d"    % PlayerStats.resistance
	_card_value("FireCard").text   = "Atual: %.2fs" % PlayerStats.fire_rate
	_card_value("RegenCard").text  = "Atual: %.1fs" % PlayerStats.regen_rate
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- Callbacks dos botões ---

func _on_speed_pressed() -> void:
	PlayerStats.upgrade_speed()
	_close("Velocidade +20")

func _on_force_pressed() -> void:
	PlayerStats.upgrade_force()
	_close("Força +1 dano")

func _on_res_pressed() -> void:
	PlayerStats.upgrade_resistance()
	_close("Resistência +5")

func _on_fire_rate_pressed() -> void:
	PlayerStats.upgrade_fire_rate()
	_close("Rajada +velocidade")

func _on_regen_pressed() -> void:
	PlayerStats.upgrade_regen()
	_close("Regeneração +veloz")

func _close(attr: String) -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_toast(attr)
