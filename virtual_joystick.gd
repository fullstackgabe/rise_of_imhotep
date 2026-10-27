extends CanvasLayer

## Joystick virtual flutuante (estilo jogos de Android): encostou o dedo (ou clicou) em
## qualquer ponto da tela, a base aparece ali; arrastando, o pino segue o dedo até o raio
## e o jogador anda nessa direção. Soltou, some e para. Toque entra como mouse
## (emulate_mouse_from_touch, padrão do Godot); botões da UI consomem o clique antes.
## Só existe em aparelho com tela de toque (o player cria); no PC é teclado.

const RADIUS    := 70.0    # quanto o pino anda a partir do centro
const DEAD_ZONE := 0.2     # fração do raio sem movimento
const BASE_R    := 70.0
const KNOB_R    := 30.0

var direction := Vector2.ZERO   # lida pelo player (tamanho 0 ou 1)

var _active := false
var _base   := Vector2.ZERO
var _knob   := Vector2.ZERO
var _canvas : Node2D

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS   # recebe o “soltou” mesmo com o jogo pausado (modal)
	_canvas = Node2D.new()
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_active = event.pressed
		_base = event.position
		_knob = _base
		direction = Vector2.ZERO
		_canvas.queue_redraw()
	elif event is InputEventMouseMotion and _active:
		var off: Vector2 = (event.position - _base).limit_length(RADIUS)
		_knob = _base + off
		direction = off.normalized() if off.length() > RADIUS * DEAD_ZONE else Vector2.ZERO
		_canvas.queue_redraw()

func _on_draw() -> void:
	if not _active:
		return
	_canvas.draw_circle(_base, BASE_R, Color(0, 0, 0, 0.25))
	_canvas.draw_arc(_base, BASE_R, 0.0, TAU, 48, Color(1, 0.9, 0.6, 0.6), 3.0)
	_canvas.draw_circle(_knob, KNOB_R, Color(1, 0.9, 0.6, 0.55))
