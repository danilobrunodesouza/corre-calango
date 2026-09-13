## SceneryItem — Elemento decorativo leve (solo ou aéreo) para o runner 2D.
## SEM qualquer colisor (imune a colisões com o jogador).
class_name SceneryItem
extends Node2D

signal exited_screen(item: Node2D)

const DESPAWN_X: float = -220.0

var sprite: Sprite2D
var item_type: String = "ground"
var element_id: String = ""
var speed_factor: float = 1.0
var base_y: float = 0.0
var bobbing: bool = false
var bob_speed: float = 1.5
var bob_amplitude: float = 12.0
var _bob_time: float = 0.0

func _init() -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)

func setup(id: String, type: String, config: Dictionary) -> void:
	element_id = id
	item_type = type

	var tex_path: String = config.get("texture", "")
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)

	var sc: float = config.get("scale", 0.3)
	sprite.scale = Vector2(sc, sc)

	z_index = config.get("z_index", -1 if type == "ground" else -3)
	speed_factor = config.get("speed_factor", 1.0)
	bobbing = config.get("bobbing", false)
	bob_speed = config.get("bob_speed", 1.5)
	bob_amplitude = config.get("bob_amplitude", 12.0)
	_bob_time = randf() * TAU

	if config.get("random_flip", false):
		sprite.flip_h = randf() < 0.5
	else:
		sprite.flip_h = false

func reset(new_position: Vector2, random_flip: bool = true) -> void:
	position = new_position
	base_y = new_position.y
	_bob_time = randf() * TAU
	if random_flip:
		sprite.flip_h = randf() < 0.5
	visible = true
	set_process(true)

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var current_speed: float = GameManager.game_speed * speed_factor
	position.x -= current_speed * delta

	if bobbing:
		_bob_time += delta * bob_speed
		position.y = base_y + sin(_bob_time) * bob_amplitude

	if position.x < DESPAWN_X:
		set_process(false)
		exited_screen.emit(self)
