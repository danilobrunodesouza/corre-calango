extends Node
## GameManager — estado global, score, velocidade, input de início/restart.
## Autoload com PROCESS_MODE_ALWAYS — sempre recebe _input.

signal game_started
signal game_over_triggered
signal score_changed(new_score: int)
signal restart_requested

enum GameState { IDLE, PLAYING, GAME_OVER }

const SPEED_INCREMENT: float = 10.0
const MAX_SPEED: float = 900.0

var state: GameState = GameState.IDLE
var score: int = 0
var high_score: int = 0
var game_speed: float = 300.0

## Modo Imortal para facilitar testes (pode ser ativado no Inspector ou pressionando 'I' no teclado)
@export var immortal: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.set_default_clear_color(Color.BLACK)
	_ensure_input_actions()
	_load_high_score()

func _ensure_input_actions() -> void:
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
		var sp := InputEventKey.new()
		sp.physical_keycode = KEY_SPACE
		InputMap.action_add_event("jump", sp)
		var up := InputEventKey.new()
		up.physical_keycode = KEY_UP
		InputMap.action_add_event("jump", up)
		var w := InputEventKey.new()
		w.physical_keycode = KEY_W
		InputMap.action_add_event("jump", w)
	if not InputMap.has_action("duck"):
		InputMap.add_action("duck")
		var dn := InputEventKey.new()
		dn.physical_keycode = KEY_DOWN
		InputMap.action_add_event("duck", dn)
		var s := InputEventKey.new()
		s.physical_keycode = KEY_S
		InputMap.action_add_event("duck", s)

func _input(event: InputEvent) -> void:
	# Tecla 'I' alterna modo imortal (God Mode) para testes rápidos
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_I:
		immortal = !immortal
		print("[TESTE] Modo Imortal: ", "LIGADO (ON)" if immortal else "DESLIGADO (OFF)")

	var activate := false
	if event is InputEventKey and event.pressed and not event.echo:
		activate = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activate = true
	if event is InputEventScreenTouch and event.pressed:
		activate = true

	if activate:
		if state == GameState.IDLE:
			start_game()
		elif state == GameState.GAME_OVER:
			restart_requested.emit()

func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	score += int(game_speed * delta * 0.1)
	score_changed.emit(score)
	var new_speed := 300.0 + (score / 200.0) * SPEED_INCREMENT
	game_speed = minf(new_speed, MAX_SPEED)

func start_game() -> void:
	score = 0
	game_speed = 300.0
	state = GameState.PLAYING
	game_started.emit()

func trigger_game_over() -> void:
	if immortal:
		return
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	if score > high_score:
		high_score = score
		_save_high_score()
	game_over_triggered.emit()

func _load_high_score() -> void:
	if FileAccess.file_exists("user://save.dat"):
		var file := FileAccess.open("user://save.dat", FileAccess.READ)
		if file:
			high_score = file.get_32()

func _save_high_score() -> void:
	var file := FileAccess.open("user://save.dat", FileAccess.WRITE)
	if file:
		file.store_32(high_score)
