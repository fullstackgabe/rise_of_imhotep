extends CanvasLayer

var hp         := 0
var level      := 1
var _xp        := 0      # XP atual do jogador
var _xp_needed := 60     # XP necessário para o próximo nível (cresce 1.5× a cada nível)

@onready var hp_bar:      ProgressBar    = $Control/HPRow/HPBarContainer/HPBar
@onready var hp_value:    Label          = $Control/HPRow/HPBarContainer/HPValue
@onready var xp_bar:      ProgressBar    = $Control/XPRow/XPBarContainer/XPBar
@onready var xp_value:    Label          = $Control/XPRow/XPBarContainer/XPValue
@onready var level_label: Label          = $Control/NivelLabel
@onready var wave_label:  Label          = $Control/WaveLabel
@onready var game_over:   ColorRect      = $Control/GameOver
@onready var toast:       PanelContainer = $Control/Toast
@onready var toast_label: Label          = $Control/Toast/ToastLabel

func _ready() -> void:
	add_to_group("hud")
	hp = int(hp_bar.max_value)
	_style_bars()
	_style_info_labels()
	_update_hp()
	_update_xp()

# --- Estilo das barras de HP e XP ---

func _style_bars() -> void:
	hp_bar.add_theme_stylebox_override("fill",       Styles.flat(Color(0.85, 0.1, 0.1), 0, 0))
	hp_bar.add_theme_stylebox_override("background", Styles.flat(Color(0.2, 0.2, 0.2),  0, 0))
	xp_bar.add_theme_stylebox_override("fill",       Styles.flat(Color(0.1, 0.8, 0.2),  0, 0))
	xp_bar.add_theme_stylebox_override("background", Styles.flat(Color(0.2, 0.2, 0.2),  0, 0))

# Adiciona fundo escuro nos labels de nível e onda para ficarem legíveis.
func _style_info_labels() -> void:
	var bg := Styles.flat(Color(0, 0, 0, 0.65), 3, 0)
	level_label.add_theme_stylebox_override("normal", bg)
	wave_label.add_theme_stylebox_override("normal",  bg.duplicate())

# --- HP ---

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	_update_hp()
	if hp <= 0:
		_game_over()

func heal(amount: int) -> void:
	hp = min(int(hp_bar.max_value), hp + amount)
	_update_hp()

func _update_hp() -> void:
	hp_bar.value  = hp
	hp_value.text = "%d/%d" % [hp, int(hp_bar.max_value)]

# --- XP e Nível ---

func add_xp(amount: int) -> void:
	_xp += amount
	if _xp >= _xp_needed:
		_xp       = 0
		_xp_needed = int(_xp_needed * 1.5)
		level     += 1
		level_label.text = "Nível %d" % level
		var modal = get_tree().get_first_node_in_group("upgrade_modal")
		if modal:
			modal.show_modal(level)
	_update_xp()

func _update_xp() -> void:
	# Barra sempre de 0-100; preenchimento proporcional ao progresso no nível
	xp_bar.value  = float(_xp) / float(_xp_needed) * 100.0
	xp_value.text = "%d/%d" % [_xp, _xp_needed]

# --- Onda ---

func set_wave(n: int) -> void:
	wave_label.text = "Onda %d" % n

# --- Toast (mensagem temporária) ---

func show_toast(msg: String) -> void:
	toast_label.text = msg
	toast.modulate.a = 1.0
	toast.visible    = true
	await get_tree().create_timer(1.5).timeout
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.8)
	await tween.finished
	toast.visible = false

# --- Game Over ---

func _game_over() -> void:
	game_over.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")
