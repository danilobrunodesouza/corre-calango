## StartScreen — tela de apresentação inicial.
class_name StartScreen
extends CanvasLayer

var theme_button: Button

func _ready() -> void:
	_build_ui()
	PaletteManager.palette_changed.connect(_on_palette_changed)

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "🦎 CORRE CALANGO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var prompt := Label.new()
	prompt.text = "Pressione ESPAÇO ou TOQUE na tela para começar"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	vbox.add_child(prompt)

	# Seletor interativo de paleta/tema
	theme_button = Button.new()
	theme_button.name = "StartThemeButton"
	theme_button.text = "🎨 Tema: %s (Clique ou pressione 'C')" % PaletteManager.current_palette_name
	theme_button.focus_mode = Control.FOCUS_NONE
	theme_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_style_theme_button(theme_button)
	theme_button.pressed.connect(_on_theme_pressed)
	vbox.add_child(theme_button)

	var instr := Label.new()
	instr.text = "Controles:\nPular: Espaço / ↑ / Metade Superior da Tela\nAbaixar: ↓ / S / Metade Inferior da Tela\nTema de Cores: Tecla C | Dia/Noite: Tecla N"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_font_size_override("font_size", 15)
	instr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	vbox.add_child(instr)

func _style_theme_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(280.0, 42.0)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.18, 0.18, 0.18, 0.9)
	style_normal.set_corner_radius_all(10)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.8, 0.8, 0.8, 0.8)
	style_normal.content_margin_left = 16.0
	style_normal.content_margin_right = 16.0

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.35, 0.35, 0.35, 0.95)
	style_pressed.set_corner_radius_all(10)
	style_pressed.border_width_left = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color.WHITE
	style_pressed.content_margin_left = 16.0
	style_pressed.content_margin_right = 16.0

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("pressed", style_pressed)

func _on_theme_pressed() -> void:
	PaletteManager.next_palette()

func _on_palette_changed(_dark: Color, _light: Color) -> void:
	if theme_button:
		theme_button.text = "🎨 Tema: %s (Clique ou pressione 'C')" % PaletteManager.current_palette_name
