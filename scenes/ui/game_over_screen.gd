## GameOverScreen — tela de fim de jogo com pontuação e reinício.
class_name GameOverScreen
extends CanvasLayer

var score_label: Label
var hi_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	vbox.add_child(title)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(score_label)

	hi_label = Label.new()
	hi_label.name = "HiLabel"
	hi_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hi_label.add_theme_font_size_override("font_size", 22)
	hi_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4, 1.0))
	vbox.add_child(hi_label)

	var prompt := Label.new()
	prompt.text = "Pressione ESPAÇO ou TOQUE na tela para reiniciar"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	vbox.add_child(prompt)

func update_scores(score: int, high_score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %05d" % score
	if hi_label:
		hi_label.text = "RECORDE: %05d" % high_score
