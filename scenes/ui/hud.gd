## HUD — exibe pontuação, recorde e botões de toque na tela (Pular e Abaixar).
class_name HUD
extends CanvasLayer

var score_label: Label
var hi_label: Label
var jump_button: Button
var duck_button: Button
var day_night_button: Button
var theme_button: Button

func _ready() -> void:
	_build_ui()
	GameManager.score_changed.connect(_on_score_changed)
	EventBus.day_night_changed.connect(_on_day_night_changed)
	PaletteManager.palette_changed.connect(_on_palette_changed)
	_update_labels(0)

func _build_ui() -> void:
	# Top bar (Botão Dia/Noite e Tema à esquerda, Scores à direita)
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.anchor_right = 1.0
	margin.offset_left = 20.0
	margin.offset_top = 20.0
	margin.offset_right = -20.0
	margin.offset_bottom = 65.0
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	# Botão de Teste Dia/Noite
	day_night_button = Button.new()
	day_night_button.name = "DayNightButton"
	day_night_button.text = "🌙 NOITE"
	day_night_button.focus_mode = Control.FOCUS_NONE
	day_night_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_style_control_button(day_night_button)
	day_night_button.pressed.connect(_on_day_night_pressed)
	hbox.add_child(day_night_button)

	# Botão de Troca de Tema / Paleta
	theme_button = Button.new()
	theme_button.name = "ThemeButton"
	theme_button.text = "🎨 %s" % PaletteManager.current_palette_name
	theme_button.focus_mode = Control.FOCUS_NONE
	theme_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_style_control_button(theme_button)
	theme_button.pressed.connect(_on_theme_pressed)
	hbox.add_child(theme_button)

	# Espaçador flexível para posicionar o score no canto direito
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	hi_label = Label.new()
	hi_label.name = "HiLabel"
	hi_label.add_theme_font_size_override("font_size", 22)
	hi_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	hi_label.text = "HI: %05d" % GameManager.high_score
	hbox.add_child(hi_label)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.text = "00000"
	hbox.add_child(score_label)

	# --- Botão de Pular (Inferior Direito) ---
	jump_button = Button.new()
	jump_button.name = "JumpButton"
	jump_button.text = "▲ PULAR"
	jump_button.anchor_left = 1.0
	jump_button.anchor_top = 1.0
	jump_button.anchor_right = 1.0
	jump_button.anchor_bottom = 1.0
	jump_button.offset_left = -190.0
	jump_button.offset_top = -90.0
	jump_button.offset_right = -20.0
	jump_button.offset_bottom = -20.0
	jump_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	jump_button.focus_mode = Control.FOCUS_NONE
	_style_touch_button(jump_button, Color(0.2, 0.6, 0.2, 0.75))
	jump_button.button_down.connect(_on_jump_down)
	jump_button.button_up.connect(_on_jump_up)
	add_child(jump_button)

	# --- Botão de Abaixar (Inferior Esquerdo) ---
	duck_button = Button.new()
	duck_button.name = "DuckButton"
	duck_button.text = "▼ ABAIXAR"
	duck_button.anchor_left = 0.0
	duck_button.anchor_top = 1.0
	duck_button.anchor_right = 0.0
	duck_button.anchor_bottom = 1.0
	duck_button.offset_left = 20.0
	duck_button.offset_top = -90.0
	duck_button.offset_right = 190.0
	duck_button.offset_bottom = -20.0
	duck_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	duck_button.focus_mode = Control.FOCUS_NONE
	_style_touch_button(duck_button, Color(0.5, 0.3, 0.1, 0.75))
	duck_button.button_down.connect(_on_duck_down)
	duck_button.button_up.connect(_on_duck_up)
	add_child(duck_button)

func _style_touch_button(btn: Button, bg_color: Color) -> void:
	btn.add_theme_font_size_override("font_size", 20)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.set_corner_radius_all(12)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(1.0, 1.0, 1.0, 0.6)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = bg_color.lightened(0.25)
	style_pressed.set_corner_radius_all(12)
	style_pressed.border_width_left = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color.WHITE

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("hover", style_normal)

func _on_jump_down() -> void:
	Input.action_press("jump")

func _on_jump_up() -> void:
	Input.action_release("jump")

func _on_duck_down() -> void:
	Input.action_press("duck")

func _on_duck_up() -> void:
	Input.action_release("duck")

func _on_score_changed(s: int) -> void:
	_update_labels(s)

func _update_labels(s: int) -> void:
	if score_label:
		score_label.text = "%05d" % s
	if hi_label:
		hi_label.text = "HI: %05d" % GameManager.high_score

func _on_day_night_pressed() -> void:
	EventBus.request_day_night_toggle.emit()

func _on_day_night_changed(is_night: bool) -> void:
	if day_night_button:
		day_night_button.text = "☀️ DIA" if is_night else "🌙 NOITE"

func _on_theme_pressed() -> void:
	PaletteManager.next_palette()

func _on_palette_changed(_dark: Color, _light: Color) -> void:
	if theme_button:
		theme_button.text = "🎨 %s" % PaletteManager.current_palette_name

func _style_control_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(110.0, 36.0)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	style_normal.set_corner_radius_all(8)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.8, 0.8, 0.8, 0.8)
	style_normal.content_margin_left = 12.0
	style_normal.content_margin_right = 12.0

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.35, 0.35, 0.35, 0.95)
	style_pressed.set_corner_radius_all(8)
	style_pressed.border_width_left = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color.WHITE
	style_pressed.content_margin_left = 12.0
	style_pressed.content_margin_right = 12.0

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("pressed", style_pressed)
