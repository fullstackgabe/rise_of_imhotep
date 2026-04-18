# Funções estáticas para criar estilos de UI.
# Use isto em vez de criar StyleBoxFlat manualmente em cada cena.
class_name Styles

# Cria um painel com cor de fundo e cantos arredondados.
static func flat(color: Color, radius := 6, padding := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_content_margin_all(padding)
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

# Cria um painel com borda colorida além do fundo.
static func bordered(bg: Color, border: Color, radius := 8, border_px := 3) -> StyleBoxFlat:
	var s := flat(bg, radius)
	s.border_color        = border
	s.border_width_top    = border_px
	s.border_width_bottom = border_px
	s.border_width_left   = border_px
	s.border_width_right  = border_px
	return s

# Aplica estilo dourado de hover em um Button já existente.
static func gold_button(btn: Button, normal: Color, hover: Color) -> void:
	btn.add_theme_stylebox_override("normal", flat(normal, 6))
	btn.add_theme_stylebox_override("hover",  flat(hover,  6))
	btn.add_theme_color_override("font_color", Color(0.05, 0.03, 0.01))
