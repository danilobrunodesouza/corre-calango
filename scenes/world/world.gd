## World — gerencia o cenário com ParallaxBackground, chão físico, player e spawner.
extends Node2D

const PlayerScript = preload("res://scenes/player/player.gd")
const ObstacleSpawnerScript = preload("res://scenes/obstacles/obstacle_spawner.gd")

var parallax: ParallaxBackground
var ground_sprite: Sprite2D
var ground_body: StaticBody2D
var player: CharacterBody2D
var spawner: Node

const GROUND_Y: float = 460.0

func _ready() -> void:
	_build_parallax()
	_build_ground()
	_build_player()
	_build_spawner()

func _build_parallax() -> void:
	parallax = ParallaxBackground.new()
	parallax.name = "ParallaxBackground"
	add_child(parallax)

	# 0. Fundo preto absoluto (#000000)
	var bg_layer := ParallaxLayer.new()
	bg_layer.name = "LayerBackground"
	bg_layer.motion_scale = Vector2(0.0, 0.0)
	var bg_rect := ColorRect.new()
	bg_rect.color = Color.BLACK
	bg_rect.size = Vector2(2400.0, 1200.0)
	bg_rect.position = Vector2(-400.0, -200.0)
	bg_layer.add_child(bg_rect)
	parallax.add_child(bg_layer)

	# 1. Sol (estático no topo direito)
	var sol_layer := ParallaxLayer.new()
	sol_layer.name = "LayerSol"
	sol_layer.motion_scale = Vector2(0.0, 0.0)
	var sol_sprite := Sprite2D.new()
	sol_sprite.texture = load("res://assets/sol.png")
	sol_sprite.scale = Vector2(0.25, 0.25)
	sol_sprite.position = Vector2(800.0, 90.0)
	sol_layer.add_child(sol_sprite)
	parallax.add_child(sol_layer)

	# 2. Montes (movimento lento)
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

	# 3. Nuvem Grande (nuvem2.png - movimento médio)
	var nuvem_g_layer := ParallaxLayer.new()
	nuvem_g_layer.name = "LayerNuvemGrande"
	nuvem_g_layer.motion_scale = Vector2(0.25, 0.0)
	nuvem_g_layer.motion_mirroring = Vector2(960.0, 0.0)
	var nuvem_g_sprite := Sprite2D.new()
	nuvem_g_sprite.texture = load("res://assets/nuvem2.png")
	nuvem_g_sprite.scale = Vector2(0.35, 0.35)
	nuvem_g_sprite.position = Vector2(300.0, 110.0)
	nuvem_g_layer.add_child(nuvem_g_sprite)
	parallax.add_child(nuvem_g_layer)

	# 4. Nuvem Média (nuvem.png - movimento rápido)
	var nuvem_m_layer := ParallaxLayer.new()
	nuvem_m_layer.name = "LayerNuvemMedia"
	nuvem_m_layer.motion_scale = Vector2(0.4, 0.0)
	nuvem_m_layer.motion_mirroring = Vector2(800.0, 0.0)
	var nuvem_m_sprite := Sprite2D.new()
	nuvem_m_sprite.texture = load("res://assets/nuvem.png")
	nuvem_m_sprite.scale = Vector2(0.35, 0.35)
	nuvem_m_sprite.position = Vector2(650.0, 160.0)
	nuvem_m_layer.add_child(nuvem_m_sprite)
	parallax.add_child(nuvem_m_layer)

	# 5. Grama decorativa no chão (grama.png - velocidade 1.0)
	var grama_tex: Texture2D = load("res://assets/grama.png")
	if grama_tex:
		var grama_layer := ParallaxLayer.new()
		grama_layer.name = "LayerGrama"
		grama_layer.motion_scale = Vector2(1.0, 0.0)
		grama_layer.motion_mirroring = Vector2(960.0, 0.0)
		var offsets := [120.0, 360.0, 620.0, 840.0]
		for gx in offsets:
			var gs := Sprite2D.new()
			gs.texture = grama_tex
			gs.scale = Vector2(0.25, 0.25)
			gs.position = Vector2(gx, GROUND_Y - 20.0)
			grama_layer.add_child(gs)
		parallax.add_child(grama_layer)

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
