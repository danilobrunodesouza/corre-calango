## StartScreen — tela de apresentação inicial.
class_name StartScreen
extends CanvasLayer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
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

	var instr := Label.new()
	instr.text = "Controles:\nPular: Espaço / ↑ / Metade Superior da Tela\nAbaixar: ↓ / S / Metade Inferior da Tela"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_font_size_override("font_size", 16)
	instr.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	vbox.add_child(instr)
