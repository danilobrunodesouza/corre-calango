## Obstacle — base para todos os obstáculos (cactos).
## Area2D que se move da direita para a esquerda e detecta colisão com o jogador.
class_name Obstacle
extends Area2D

signal returned_to_pool

const FOGUEIRA_TEXTURES: Array[Texture2D] = [
	preload("res://assets/fogueira1.png"),
	preload("res://assets/fogueira2.png"),
	preload("res://assets/fogueira3.png")
]
const ANIM_FRAME_TIME: float = 0.1

var speed: float = 300.0
var sprite: Sprite2D
var collision: CollisionShape2D
var obstacle_type: String = "tall"
var _anim_timer: float = 0.0
var _current_frame: int = 0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_ensure_components()

func setup(type: String) -> void:
	obstacle_type = type
	_ensure_components()
	_apply_type()

func _ensure_components() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Sprite2D"
			add_child(sprite)

	if collision == null:
		collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision == null:
			collision = CollisionShape2D.new()
			collision.name = "CollisionShape2D"
			add_child(collision)

func _apply_type() -> void:
	_ensure_components()
	var rect_shape := RectangleShape2D.new()

	if obstacle_type == "fogueira":
		_current_frame = 0
		_anim_timer = 0.0
		sprite.texture = FOGUEIRA_TEXTURES[0]
		sprite.scale = Vector2(0.203, 0.203)
		rect_shape.size = Vector2(32.2, 61.6)
	elif obstacle_type == "tall":
		sprite.texture = load("res://assets/cacto1.png")
		sprite.scale = Vector2(0.245, 0.245)
		rect_shape.size = Vector2(35.0, 66.5)
	else:
		sprite.texture = load("res://assets/cacto2.png")
		sprite.scale = Vector2(0.245, 0.245)
		rect_shape.size = Vector2(31.5, 63.0)

	collision.shape = rect_shape

func on_spawn() -> void:
	speed = GameManager.game_speed
	_anim_timer = 0.0
	if obstacle_type == "fogueira":
		_current_frame = 0
		sprite.texture = FOGUEIRA_TEXTURES[0]
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func on_despawn() -> void:
	speed = GameManager.game_speed
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	if obstacle_type == "fogueira":
		_anim_timer += delta
		if _anim_timer >= ANIM_FRAME_TIME:
			_anim_timer -= ANIM_FRAME_TIME
			_current_frame = (_current_frame + 1) % FOGUEIRA_TEXTURES.size()
			sprite.texture = FOGUEIRA_TEXTURES[_current_frame]

	position.x -= speed * delta
	if position.x < -200.0:
		returned_to_pool.emit()
		EventBus.obstacle_passed.emit()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		if GameManager.immortal:
			return
		EventBus.player_died.emit()
		GameManager.trigger_game_over()
