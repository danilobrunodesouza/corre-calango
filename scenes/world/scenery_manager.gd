## SceneryManager — Gerencia elementos decorativos de solo e ar em um 2D Endless Runner.
## Recicla elementos continuamente para evitar GC spikes e stutters.
## TOTALMENTE DESACOPLADO DE COLISÕES (Zero interação física com o calango).
class_name SceneryManager
extends Node2D

const SceneryItemScript = preload("res://scenes/world/scenery_item.gd")
const CONFIG_PATH: String = "res://scenes/world/scenery_config.json"

const SCREEN_WIDTH: float = 960.0
const GROUND_Y: float = 460.0
const SPAWN_MARGIN_X: float = 120.0

# Configurações data-driven
var ground_configs: Dictionary = {}
var aerial_configs: Dictionary = {}

# Pools e instâncias ativas
var _ground_items: Array[Node2D] = []
var _aerial_items: Array[Node2D] = []
var _max_ground_x: float = SCREEN_WIDTH

# Controle de spawn aéreo
var _aerial_timer: float = 0.0
var _next_aerial_spawn: float = 3.0

func _ready() -> void:
	load_config()
	_setup_initial_scenery()
	
	if Engine.has_singleton("GameManager") or GameManager:
		GameManager.game_started.connect(_on_game_started)
		GameManager.restart_requested.connect(_on_game_restart)

func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_warning("SceneryManager: Arquivo scenery_config.json não encontrado. Usando defaults.")
		_load_defaults()
		return

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		_load_defaults()
		return

	var text := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SceneryManager: Erro ao parsear scenery_config.json: " + json.get_error_message())
		_load_defaults()
		return

	var data: Dictionary = json.data as Dictionary
	ground_configs = data.get("ground_elements", {})
	aerial_configs = data.get("aerial_elements", {})

func _load_defaults() -> void:
	ground_configs = {
		"arvore": { "texture": "res://assets/arvore.png", "scale": 0.32, "y_offset": -60.0, "z_index": -1, "weight": 1.0, "random_flip": true },
		"arbusto": { "texture": "res://assets/arbusto.png", "scale": 0.28, "y_offset": -36.0, "z_index": -1, "weight": 1.2, "random_flip": true },
		"pedra": { "texture": "res://assets/pedra.png", "scale": 0.35, "y_offset": -17.0, "z_index": -1, "weight": 1.5, "random_flip": true },
		"grama": { "texture": "res://assets/grama.png", "scale": 0.24, "y_offset": -23.0, "z_index": -1, "weight": 1.8, "random_flip": true }
	}
	aerial_configs = {
		"nuvem": { "texture": "res://assets/nuvem.png", "scale": 0.35, "speed_factor": 0.35, "y_min": 120.0, "y_max": 180.0, "z_index": -3, "weight": 1.2, "bobbing": false },
		"nuvem2": { "texture": "res://assets/nuvem2.png", "scale": 0.35, "speed_factor": 0.22, "y_min": 70.0, "y_max": 130.0, "z_index": -4, "weight": 1.0, "bobbing": false },
		"balao": { "texture": "res://assets/balao.png", "scale": 0.26, "speed_factor": 0.28, "y_min": 90.0, "y_max": 230.0, "z_index": -2, "weight": 0.6, "bobbing": true, "bob_speed": 1.5, "bob_amplitude": 12.0 }
	}

## Registra um novo elemento dinamicamente em runtime
func register_element(id: String, type: String, config: Dictionary) -> void:
	if type == "ground":
		ground_configs[id] = config
	elif type == "aerial":
		aerial_configs[id] = config

func _setup_initial_scenery() -> void:
	# Cria pool de 10 elementos de solo
	_max_ground_x = 100.0
	for i in range(10):
		var item: Node2D = SceneryItemScript.new()
		add_child(item)
		item.exited_screen.connect(_on_ground_item_exited)
		_ground_items.append(item)
		
		# Distribui ao longo da tela inicial
		_spawn_ground_item(item, _max_ground_x)
		_max_ground_x += randf_range(160.0, 320.0)

	# Cria pool de 6 elementos aéreos
	for i in range(6):
		var a_item: Node2D = SceneryItemScript.new()
		add_child(a_item)
		a_item.exited_screen.connect(_on_aerial_item_exited)
		_aerial_items.append(a_item)
		
		# Distribui inicialmente na tela e logo à direita
		var init_x := randf_range(100.0, SCREEN_WIDTH + 600.0)
		_spawn_aerial_item(a_item, init_x)

func _spawn_ground_item(item: Node2D, spawn_x: float) -> void:
	var id := _pick_weighted_id(ground_configs)
	if id.is_empty():
		return
	var cfg: Dictionary = ground_configs[id]
	item.setup(id, "ground", cfg)
	
	var y_pos: float = GROUND_Y + float(cfg.get("y_offset", -20.0))
	item.reset(Vector2(spawn_x, y_pos), cfg.get("random_flip", true))

func _spawn_aerial_item(item: Node2D, spawn_x: float) -> void:
	var id := _pick_weighted_id(aerial_configs)
	if id.is_empty():
		return
	var cfg: Dictionary = aerial_configs[id]
	item.setup(id, "aerial", cfg)
	
	var y_min: float = cfg.get("y_min", 90.0)
	var y_max: float = cfg.get("y_max", 200.0)
	var y_pos: float = randf_range(y_min, y_max)
	item.reset(Vector2(spawn_x, y_pos), cfg.get("random_flip", false))

func _on_ground_item_exited(item: Node2D) -> void:
	# Recicla o item imediatamente posicionando-o à frente
	var rightmost_x: float = SCREEN_WIDTH + SPAWN_MARGIN_X
	for gi in _ground_items:
		if gi != item and gi.position.x > rightmost_x:
			rightmost_x = gi.position.x
	
	var next_x := rightmost_x + randf_range(180.0, 380.0)
	_spawn_ground_item(item, next_x)

func _on_aerial_item_exited(item: Node2D) -> void:
	# Recicla o item aéreo com distância espaçada
	var next_x := SCREEN_WIDTH + randf_range(200.0, 800.0)
	_spawn_aerial_item(item, next_x)

func _pick_weighted_id(configs: Dictionary) -> String:
	if configs.is_empty():
		return ""
	var total_weight: float = 0.0
	for id in configs:
		total_weight += float(configs[id].get("weight", 1.0))
	
	var roll := randf() * total_weight
	var accum: float = 0.0
	for id in configs:
		accum += float(configs[id].get("weight", 1.0))
		if roll <= accum:
			return id
	return configs.keys()[0]

func _on_game_started() -> void:
	pass

func _on_game_restart() -> void:
	# Reposiciona elementos para recomeço suave
	var g_x: float = 120.0
	for item in _ground_items:
		_spawn_ground_item(item, g_x)
		g_x += randf_range(160.0, 300.0)
	
	for a_item in _aerial_items:
		_spawn_aerial_item(a_item, randf_range(100.0, SCREEN_WIDTH + 500.0))
