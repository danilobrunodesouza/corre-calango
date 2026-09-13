## World — gerencia o cenário com ParallaxBackground, chão físico, player e spawner.
extends Node2D

const PlayerScript = preload("res://scenes/player/player.gd")
const ObstacleSpawnerScript = preload("res://scenes/obstacles/obstacle_spawner.gd")
const SceneryManagerScript = preload("res://scenes/world/scenery_manager.gd")

var parallax: ParallaxBackground
var ground_sprite: Sprite2D
var ground_body: StaticBody2D
var player: CharacterBody2D
var spawner: Node
var scenery_manager: Node2D

# Corpos Celestes Dinâmicos
var sol_sprite: Sprite2D
var lua_sprite: Sprite2D
var estrelas_node: Node2D
var _celestial_tween: Tween

const SKY_Y: float = 90.0
const HORIZON_Y: float = 350.0
const CELESTIAL_X: float = 800.0
const GROUND_Y: float = 460.0

func _ready() -> void:
	_build_parallax()
	_build_ground()
	_build_scenery()
	_build_player()
	_build_spawner()
	EventBus.day_night_changed.connect(_on_day_night_changed)
	GameManager.game_started.connect(_reset_celestials)
	GameManager.restart_requested.connect(_reset_celestials)

func _build_scenery() -> void:
	scenery_manager = SceneryManagerScript.new()
	scenery_manager.name = "SceneryManager"
	add_child(scenery_manager)

func _build_parallax() -> void:
	parallax = ParallaxBackground.new()
	parallax.name = "ParallaxBackground"
	add_child(parallax)

	# 0. Fundo preto base
	var bg_layer := ParallaxLayer.new()
	bg_layer.name = "LayerBackground"
	bg_layer.motion_scale = Vector2(0.0, 0.0)
	var bg_rect := ColorRect.new()
	bg_rect.color = Color.BLACK
	bg_rect.size = Vector2(2400.0, 1200.0)
	bg_rect.position = Vector2(-400.0, -200.0)
	bg_layer.add_child(bg_rect)
	parallax.add_child(bg_layer)

	# 1. Estrelas (visíveis apenas à noite, movimento parallax muito lento)
	var estrelas_layer := ParallaxLayer.new()
	estrelas_layer.name = "LayerEstrelas"
	estrelas_layer.motion_scale = Vector2(0.05, 0.0)
	estrelas_layer.motion_mirroring = Vector2(960.0, 0.0)
	estrelas_node = Node2D.new()
	estrelas_node.name = "EstrelasContainer"
	estrelas_node.modulate.a = 0.0 # Começa invisível de dia
	_populate_stars(estrelas_node)
	estrelas_layer.add_child(estrelas_node)
	parallax.add_child(estrelas_layer)

	# 2. Sol (visível apenas de dia)
	var sol_layer := ParallaxLayer.new()
	sol_layer.name = "LayerSol"
	sol_layer.motion_scale = Vector2(0.0, 0.0)
	sol_sprite = Sprite2D.new()
	sol_sprite.name = "SolSprite"
	sol_sprite.texture = load("res://assets/sol.png")
	sol_sprite.scale = Vector2(0.25, 0.25)
	sol_sprite.position = Vector2(CELESTIAL_X, SKY_Y)
	sol_sprite.modulate.a = 1.0 # Começa visível no alto do céu de dia
	sol_layer.add_child(sol_sprite)
	parallax.add_child(sol_layer)

	# 3. Lua (visível apenas à noite)
	var lua_layer := ParallaxLayer.new()
	lua_layer.name = "LayerLua"
	lua_layer.motion_scale = Vector2(0.0, 0.0)
	lua_sprite = Sprite2D.new()
	lua_sprite.name = "LuaSprite"
	lua_sprite.texture = load("res://assets/lua.png")
	lua_sprite.scale = Vector2(0.22, 0.22)
	lua_sprite.position = Vector2(CELESTIAL_X, HORIZON_Y)
	lua_sprite.modulate.a = 0.0 # Começa invisível abaixo do horizonte de dia
	lua_layer.add_child(lua_sprite)
	parallax.add_child(lua_layer)

	# 4. Montes (silhueta montanhosa distante — movimento lento)
	var montes_layer := ParallaxLayer.new()
	montes_layer.name = "LayerMontes"
	montes_layer.motion_scale = Vector2(0.1, 0.0)
	var montes_tex: Texture2D = load("res://assets/montes.png")
	var montes_w: float = 7680.0 * 0.35
	montes_layer.motion_mirroring = Vector2(montes_w, 0.0)
	var montes_sprite := Sprite2D.new()
	montes_sprite.texture = montes_tex
	montes_sprite.scale = Vector2(0.35, 0.35)
	montes_sprite.position = Vector2(montes_w * 0.5, 360.0)
	montes_layer.add_child(montes_sprite)
	parallax.add_child(montes_layer)

func _populate_stars(parent: Node2D) -> void:
	# Distribuição de estrelas (estrela1 a estrela5) espalhadas pelo céu
	var star_textures: Array[Texture2D] = [
		load("res://assets/estrela1.png"),
		load("res://assets/estrela2.png"),
		load("res://assets/estrela3.png"),
		load("res://assets/estrela4.png"),
		load("res://assets/estrela5.png")
	]
	var star_positions: Array[Vector2] = [
		Vector2(60.0, 50.0),
		Vector2(140.0, 120.0),
		Vector2(220.0, 60.0),
		Vector2(320.0, 150.0),
		Vector2(410.0, 80.0),
		Vector2(500.0, 130.0),
		Vector2(590.0, 55.0),
		Vector2(680.0, 100.0),
		Vector2(750.0, 170.0),
		Vector2(850.0, 60.0),
		Vector2(910.0, 140.0)
	]
	for i in range(star_positions.size()):
		var s := Sprite2D.new()
		s.texture = star_textures[i % star_textures.size()]
		s.position = star_positions[i]
		s.scale = Vector2(0.32, 0.32)
		parent.add_child(s)

func _build_ground() -> void:
	var ground_node := Node2D.new()
	ground_node.name = "Ground"
	add_child(ground_node)

	# Sprite contínuo do chão com linha.png
	ground_sprite = Sprite2D.new()
	ground_sprite.name = "GroundSprite"
	ground_sprite.texture = load("res://assets/linha.png")
	ground_sprite.region_enabled = true
	ground_sprite.region_rect = Rect2(0.0, 0.0, 3840.0, 200.0)
	ground_sprite.scale = Vector2(0.5, 0.5)
	ground_sprite.position = Vector2(480.0, GROUND_Y + 45.0)
	ground_node.add_child(ground_sprite)

	# Corpo físico estático para o chão
	ground_body = StaticBody2D.new()
	ground_body.name = "GroundBody"
	ground_body.position = Vector2(480.0, GROUND_Y + 20.0)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2400.0, 40.0)
	col.shape = rect
	ground_body.add_child(col)
	ground_node.add_child(ground_body)

func _build_player() -> void:
	player = PlayerScript.new() as CharacterBody2D
	player.name = "Player"
	player.position = Vector2(120.0, GROUND_Y - 40.0)
	add_child(player)

func _build_spawner() -> void:
	spawner = ObstacleSpawnerScript.new()
	spawner.name = "ObstacleSpawner"
	spawner.set("spawn_x", 1050.0)
	spawner.set("ground_y", GROUND_Y - 56.0)
	add_child(spawner)

func _reset_celestials() -> void:
	if _celestial_tween and _celestial_tween.is_valid():
		_celestial_tween.kill()
	if sol_sprite:
		sol_sprite.position = Vector2(CELESTIAL_X, SKY_Y)
		sol_sprite.modulate.a = 1.0
	if lua_sprite:
		lua_sprite.position = Vector2(CELESTIAL_X, HORIZON_Y)
		lua_sprite.modulate.a = 0.0
	if estrelas_node:
		estrelas_node.modulate.a = 0.0

func _on_day_night_changed(is_night: bool) -> void:
	if _celestial_tween and _celestial_tween.is_valid():
		_celestial_tween.kill()

	_celestial_tween = create_tween().set_parallel(true)
	if is_night:
		# Transição para Noite:
		# Sol desce em direção aos montes (pôr do sol) e apaga
		if sol_sprite:
			_celestial_tween.tween_property(sol_sprite, "position:y", HORIZON_Y, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			_celestial_tween.tween_property(sol_sprite, "modulate:a", 0.0, 1.0)
		# Lua sobe a partir dos montes até o alto do céu e acende
		if lua_sprite:
			if lua_sprite.modulate.a == 0.0:
				lua_sprite.position.y = HORIZON_Y
			_celestial_tween.tween_property(lua_sprite, "position:y", SKY_Y, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_celestial_tween.tween_property(lua_sprite, "modulate:a", 1.0, 1.0)
		# Estrelas acendem suavemente
		if estrelas_node:
			_celestial_tween.tween_property(estrelas_node, "modulate:a", 1.0, 1.2)
	else:
		# Transição para Dia:
		# Lua desce em direção aos montes e apaga
		if lua_sprite:
			_celestial_tween.tween_property(lua_sprite, "position:y", HORIZON_Y, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			_celestial_tween.tween_property(lua_sprite, "modulate:a", 0.0, 1.0)
		# Sol sobe a partir dos montes até o alto do céu e acende
		if sol_sprite:
			if sol_sprite.modulate.a == 0.0:
				sol_sprite.position.y = HORIZON_Y
			_celestial_tween.tween_property(sol_sprite, "position:y", SKY_Y, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_celestial_tween.tween_property(sol_sprite, "modulate:a", 1.0, 1.0)
		# Estrelas apagam
		if estrelas_node:
			_celestial_tween.tween_property(estrelas_node, "modulate:a", 0.0, 1.0)

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var speed: float = GameManager.game_speed

	# Scroll de Parallax
	if parallax:
		parallax.scroll_offset.x -= speed * delta

	# Scroll da textura do chão
	if ground_sprite and ground_sprite.texture:
		ground_sprite.region_rect.position.x = fmod(
			ground_sprite.region_rect.position.x + speed * delta * 2.0,
			1920.0
		)
