## ScreenShake — Helper reutilizável para tremor de tela (Game Juice).
## Adiciona impacto a colisões, passos pesados ou eventos dramáticos.
class_name ScreenShake
extends Node

@export var camera: Camera2D
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0

func start_shake(intensity: float = 8.0, decay: float = 5.0) -> void:
	_shake_intensity = intensity
	_shake_decay = decay
	set_process(true)

func _process(delta: float) -> void:
	if _shake_intensity > 0.1:
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
		var offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		if camera:
			camera.offset = offset
	else:
		_shake_intensity = 0.0
		if camera:
			camera.offset = Vector2.ZERO
		set_process(false)
