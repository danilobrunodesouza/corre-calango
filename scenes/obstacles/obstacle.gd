## Obstacle — base para todos os obstáculos (cactos).
## Area2D que se move da direita para a esquerda e detecta colisão com o jogador.
class_name Obstacle
extends Area2D

signal returned_to_pool

var speed: float = 300.0
var sprite: Sprite2D
var collision: CollisionShape2D
var obstacle_type: String = "tall"

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
	var tex_path := "res://assets/cacto1.png" if obstacle_type == "tall" else "res://assets/cacto2.png"
	var tex: Texture2D = load(tex_path)
	sprite.texture = tex
	sprite.scale = Vector2(0.35, 0.35)

	var rect_shape := RectangleShape2D.new()
	if obstacle_type == "tall":
		rect_shape.size = Vector2(50.0, 95.0)
	else:
		rect_shape.size = Vector2(45.0, 90.0)

	collision.shape = rect_shape

func on_spawn() -> void:
	speed = GameManager.game_speed
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func on_despawn() -> void:
	speed = GameManager.game_speed
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

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
