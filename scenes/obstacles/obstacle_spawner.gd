## ObstacleSpawner — gerencia o pooling e spawn adaptativo de cactos.
extends Node

const ObjectPoolScript = preload("res://scenes/obstacles/object_pool.gd")
const ObstacleScript = preload("res://scenes/obstacles/obstacle.gd")

@export var spawn_x: float = 1050.0
@export var ground_y: float = 420.8

var _pool_tall: Node
var _pool_wide: Node
var _pool_fogueira: Node
var _timer: float = 0.0
var _next_spawn: float = 2.0
var _is_active: bool = false

func _ready() -> void:
	_pool_tall = ObjectPoolScript.new()
	_pool_tall.name = "PoolTall"
	add_child(_pool_tall)
	_pool_tall.init_pool(func() -> Node:
		var o: Node = ObstacleScript.new()
		o.setup("tall")
		return o
	, 5)

	_pool_wide = ObjectPoolScript.new()
	_pool_wide.name = "PoolWide"
	add_child(_pool_wide)
	_pool_wide.init_pool(func() -> Node:
		var o: Node = ObstacleScript.new()
		o.setup("wide")
		return o
	, 5)

	_pool_fogueira = ObjectPoolScript.new()
	_pool_fogueira.name = "PoolFogueira"
	add_child(_pool_fogueira)
	_pool_fogueira.init_pool(func() -> Node:
		var o: Node = ObstacleScript.new()
		o.setup("fogueira")
		return o
	, 5)

	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)

func _on_game_started() -> void:
	_timer = 0.0
	_next_spawn = 2.0
	_is_active = true

func _on_game_over() -> void:
	_is_active = false
	call_deferred("_clear_obstacles")

func _clear_obstacles() -> void:
	if _pool_tall:
		_pool_tall.return_all()
	if _pool_wide:
		_pool_wide.return_all()
	if _pool_fogueira:
		_pool_fogueira.return_all()

func _process(delta: float) -> void:
	if not _is_active or GameManager.state != GameManager.GameState.PLAYING:
		return

	_timer += delta
	if _timer >= _next_spawn:
		_timer = 0.0
		_spawn_obstacle()
		_schedule_next()

func _schedule_next() -> void:
	var ratio := clampf(GameManager.game_speed / GameManager.MAX_SPEED, 0.0, 1.0)
	_next_spawn = randf_range(lerpf(1.5, 0.75, ratio), lerpf(2.8, 1.4, ratio))

func _spawn_obstacle() -> void:
	var r := randf()
	var pool: Node
	if r < 0.35:
		pool = _pool_tall
	elif r < 0.70:
		pool = _pool_wide
	else:
		pool = _pool_fogueira

	var obs: Node2D = pool.get_instance() as Node2D
	if obs == null:
		return

	obs.global_position = Vector2(spawn_x, ground_y)
	obs.set("speed", GameManager.game_speed)
