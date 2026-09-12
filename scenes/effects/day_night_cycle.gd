## DayNightCycle — gerencia a transição dia/noite estilo clássico (Chrome Dino)
## Dia com fundo claro suave (#F5F5F5) e noite com fundo escuro (#000000)
## com transição suave via Tween a cada 700 pontos ou botão/tecla N.
class_name DayNightCycle
extends CanvasLayer

const CYCLE_INTERVAL: int = 700
const NIGHT_DURATION_SCORE: int = 250
const FADE_DURATION: float = 1.2

var is_night: bool = false
var next_night_threshold: int = CYCLE_INTERVAL
var next_day_threshold: int = CYCLE_INTERVAL + NIGHT_DURATION_SCORE

var color_rect: ColorRect
var shader_material: ShaderMaterial
var _tween: Tween

const INVERT_SHADER_CODE: String = """shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float invert_progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	// Dia (invert_progress = 1.0): Fundo claro suave (0.96) e elementos em silhueta escura (0.10)
	// Noite (invert_progress = 0.0): Fundo escuro (0.0) e elementos brilhando em branco (1.0)
	vec3 day_color = vec3(0.96) - screen_color.rgb * 0.86;
	vec3 night_color = screen_color.rgb;
	COLOR = vec4(mix(night_color, day_color, invert_progress), screen_color.a);
}
"""

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fullscreen_shader()
	_connect_signals()

func _setup_fullscreen_shader() -> void:
	color_rect = ColorRect.new()
	color_rect.name = "InversionRect"
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0

	var shader := Shader.new()
	shader.code = INVERT_SHADER_CODE

	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	# Começa de DIA com fundo claro (invert_progress = 1.0)
	shader_material.set_shader_parameter("invert_progress", 1.0)

	color_rect.material = shader_material
	add_child(color_rect)

func _connect_signals() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.restart_requested.connect(_on_restart_requested)
	EventBus.request_day_night_toggle.connect(toggle_day_night)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_N:
		toggle_day_night()

func toggle_day_night() -> void:
	_set_night_mode(!is_night)

func _on_score_changed(current_score: int) -> void:
	if not is_night and current_score >= next_night_threshold:
		_set_night_mode(true)
		next_day_threshold = next_night_threshold + NIGHT_DURATION_SCORE
	elif is_night and current_score >= next_day_threshold:
		_set_night_mode(false)
		next_night_threshold += CYCLE_INTERVAL

func _set_night_mode(to_night: bool) -> void:
	if is_night == to_night:
		return
	is_night = to_night
	EventBus.day_night_changed.emit(is_night)

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	# Noite = 0.0 (fundo escuro), Dia = 1.0 (fundo claro)
	var target: float = 0.0 if is_night else 1.0
	_tween.tween_property(shader_material, "shader_parameter/invert_progress", target, FADE_DURATION)

func reset_cycle() -> void:
	var was_night := is_night
	is_night = false
	next_night_threshold = CYCLE_INTERVAL
	next_day_threshold = CYCLE_INTERVAL + NIGHT_DURATION_SCORE

	if _tween and _tween.is_valid():
		_tween.kill()

	if shader_material:
		shader_material.set_shader_parameter("invert_progress", 1.0)

	if was_night:
		EventBus.day_night_changed.emit(false)

func get_invert_progress() -> float:
	if shader_material:
		return shader_material.get_shader_parameter("invert_progress") as float
	return 1.0

func _on_game_started() -> void:
	reset_cycle()

func _on_restart_requested() -> void:
	reset_cycle()
