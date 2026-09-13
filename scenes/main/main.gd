## Main — cena raiz que instancia e coordena o Mundo, UI e fluxo de jogo.
extends Node

const WorldScript = preload("res://scenes/world/world.gd")
const HUDScript = preload("res://scenes/ui/hud.gd")
const StartScreenScript = preload("res://scenes/ui/start_screen.gd")
const GameOverScreenScript = preload("res://scenes/ui/game_over_screen.gd")
const DayNightCycleScript = preload("res://scenes/effects/day_night_cycle.gd")

var world: Node2D
var hud: CanvasLayer
var start_screen: CanvasLayer
var game_over_screen: CanvasLayer
var day_night_cycle: CanvasLayer

func _ready() -> void:
	_build_scene()
	_connect_signals()
	_update_initial_display()

	var cmd_args := OS.get_cmdline_args()
	var user_args := OS.get_cmdline_user_args()
	if "--test" in cmd_args or "--test" in user_args:
		_run_automated_test()

func _build_scene() -> void:
	# 1. World (cenário, parallax, player, obstáculos)
	world = WorldScript.new() as Node2D
	world.name = "World"
	add_child(world)

	# 2. HUD
	hud = HUDScript.new() as CanvasLayer
	hud.name = "HUD"
	add_child(hud)

	# 3. Tela Inicial
	start_screen = StartScreenScript.new() as CanvasLayer
	start_screen.name = "StartScreen"
	add_child(start_screen)

	# 4. Tela de Game Over
	game_over_screen = GameOverScreenScript.new() as CanvasLayer
	game_over_screen.name = "GameOverScreen"
	add_child(game_over_screen)

	# 5. Ciclo Dia/Noite (Shader de inversão de tela estilo Chrome Dino)
	day_night_cycle = DayNightCycleScript.new() as CanvasLayer
	day_night_cycle.name = "DayNightCycle"
	add_child(day_night_cycle)

func _connect_signals() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over_triggered)
	GameManager.restart_requested.connect(_on_restart_requested)

func _update_initial_display() -> void:
	start_screen.show()
	game_over_screen.hide()
	hud.hide()

## Usa _unhandled_input para não conflitar com cliques nos botões de UI do HUD
func _unhandled_input(event: InputEvent) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_handle_touch_or_mouse(event)

func _handle_touch_or_mouse(event: InputEvent) -> void:
	var vp_h := get_viewport().get_visible_rect().size.y
	var is_pressed := false
	var is_released := false
	var pos_y := 0.0

	if event is InputEventScreenTouch:
		is_pressed = event.pressed
		is_released = not event.pressed
		pos_y = event.position.y
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.pressed
		is_released = not event.pressed
		pos_y = event.position.y
	else:
		return

	if is_pressed:
		if pos_y < vp_h * 0.55:
			# Metade superior da tela: PULAR
			Input.action_press("jump")
			get_tree().create_timer(0.08).timeout.connect(
				func(): Input.action_release("jump"),
				CONNECT_ONE_SHOT
			)
		else:
			# Metade inferior da tela: ABAIXAR
			Input.action_press("duck")
	elif is_released:
		Input.action_release("duck")

func _on_game_started() -> void:
	start_screen.hide()
	game_over_screen.hide()
	hud.show()

func _on_game_over_triggered() -> void:
	hud.hide()
	if game_over_screen.has_method("update_scores"):
		game_over_screen.update_scores(GameManager.score, GameManager.high_score)
	game_over_screen.show()

func _on_restart_requested() -> void:
	GameManager.state = GameManager.GameState.IDLE
	get_tree().reload_current_scene()

func _run_automated_test() -> void:
	print("--- INICIANDO TESTES AUTOMATIZADOS DO JOGO ---")
	await get_tree().process_frame
	await get_tree().process_frame

	print("✓ Main e World carregados!")
	var player: CharacterBody2D = world.get_node_or_null("Player") as CharacterBody2D
	assert(player != null, "Player deve existir")
	assert(start_screen.visible == true, "StartScreen deve estar visível")
	assert(hud.visible == false, "HUD deve estar oculto")

	var sm: Node = player.get_node_or_null("StateMachine")
	assert(sm != null, "StateMachine deve existir no Player")
	assert(sm.get("current_state") != null, "current_state não pode ser null na StateMachine!")
	assert(sm.get("current_state").name == "Run", "Estado inicial deve ser Run!")
	print("✓ StateMachine verificada: estado inicial ativo é ", sm.get("current_state").name)

	print("-> Iniciando o jogo...")
	GameManager.start_game()
	await get_tree().process_frame
	assert(GameManager.state == GameManager.GameState.PLAYING, "Estado deve ser PLAYING")
	assert(start_screen.visible == false, "StartScreen deve estar oculta")
	assert(hud.visible == true, "HUD deve estar visível")
	print("✓ Jogo iniciado: PLAYING")

	for i in 15:
		await get_tree().process_frame
	print("✓ 15 frames rodados com sucesso. Score: ", GameManager.score, " | Speed: ", GameManager.game_speed)

	# --- TESTE DO PULO ---
	print("-> Testando disparo do PULO...")
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")

	assert(sm.get("current_state").name == "Jump", "Estado atual deve ser Jump!")
	assert(player.velocity.y < -500.0, "Velocity.y deve ser negativa durante o pulo! Atual: %f" % player.velocity.y)
	print("✓ PULO EXECUTADO COM SUCESSO! Velocity.y: ", player.velocity.y, " | Estado: ", sm.get("current_state").name)

	# Aguarda atingir o ápice e aterrissar
	for i in 60:
		await get_tree().physics_frame
		if player.is_on_floor() and player.velocity.y >= 0.0:
			break
	await get_tree().physics_frame

	assert(sm.get("current_state").name == "Run", "Após aterrissar, o estado deve voltar para Run!")
	print("✓ Aterrissagem confirmada no chão! Y: ", player.position.y, " | Estado: ", sm.get("current_state").name)

	# --- TESTE DO AGACHAMENTO ---
	print("-> Testando agachamento...")
	Input.action_press("duck")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(sm.get("current_state").name == "Duck", "Estado deve ser Duck!")
	print("✓ Estado durante agachamento: ", sm.get("current_state").name)
	Input.action_release("duck")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(sm.get("current_state").name == "Run", "Estado deve retornar para Run!")
	print("✓ Estado após soltar agachamento: ", sm.get("current_state").name)

	# --- TESTE DO CICLO DIA/NOITE (ESTILO CLÁSSICO) ---
	print("-> Testando transição de Ciclo Dia/Noite...")
	assert(day_night_cycle.is_night == false, "Deve iniciar como dia!")
	assert(day_night_cycle.get_invert_progress() == 1.0, "Progresso inicial do shader deve ser 1.0 (dia claro)!")
	assert(world.sol_sprite.modulate.a == 1.0, "Sol deve iniciar visível no dia!")
	assert(world.sol_sprite.position.y == 90.0, "Sol deve iniciar no alto do céu!")
	assert(world.lua_sprite.modulate.a == 0.0, "Lua deve iniciar invisível no dia!")
	assert(world.lua_sprite.position.y == 350.0, "Lua deve iniciar no horizonte!")
	assert(world.estrelas_node.modulate.a == 0.0, "Estrelas devem iniciar invisíveis no dia!")

	# Verifica que elementos de cenário decorativo não possuem colisores
	var scenery = world.parallax.get_node_or_null("LayerCenarioChao")
	assert(scenery != null, "Camada de cenário decorativo deve existir!")
	for child in scenery.get_children():
		assert(child is Sprite2D, "Elementos do cenário decorativo devem ser apenas Sprite2D!")
		assert(not (child is CollisionObject2D or child is CollisionShape2D), "Cenário não pode ter colisores!")
	print("✓ Cenário decorativo verificado: nenhum colisor presente!")

	# Simula atingir pontuação de 700 (virada para noite)
	GameManager.score = 700
	GameManager.score_changed.emit(700)
	await get_tree().process_frame
	assert(day_night_cycle.is_night == true, "Ao atingir 700 pontos deve virar noite!")
	print("✓ Noite ativada com sucesso aos 700 pontos!")

	# Simula término da noite aos 950 pontos (retorno ao dia)
	GameManager.score = 950
	GameManager.score_changed.emit(950)
	await get_tree().process_frame
	assert(day_night_cycle.is_night == false, "Aos 950 pontos deve voltar para o dia!")
	print("✓ Dia reativado com sucesso aos 950 pontos!")

	# Simula nova noite e testa reset
	GameManager.score = 1400
	GameManager.score_changed.emit(1400)
	await get_tree().process_frame
	assert(day_night_cycle.is_night == true, "Aos 1400 pontos deve virar noite novamente!")
	GameManager.start_game()
	await get_tree().process_frame
	assert(day_night_cycle.is_night == false, "Novo jogo deve voltar para o dia!")
	assert(day_night_cycle.get_invert_progress() == 1.0, "Novo jogo deve restaurar invert_progress para 1.0 (dia claro)!")
	assert(world.sol_sprite.position.y == 90.0, "Novo jogo deve restaurar Sol no alto do céu!")
	assert(world.lua_sprite.position.y == 350.0, "Novo jogo deve restaurar Lua no horizonte!")
	print("✓ Reset do ciclo verificado com sucesso!")

	# --- TESTE DO BOTÃO TOGGLE DIA/NOITE ---
	print("-> Testando disparo manual do botão Dia/Noite...")
	assert(day_night_cycle.is_night == false, "Deve estar no dia!")
	assert(hud.day_night_button.text == "🌙 NOITE", "Texto do botão deve ser '🌙 NOITE' no dia!")
	EventBus.request_day_night_toggle.emit()
	await get_tree().process_frame
	assert(day_night_cycle.is_night == true, "Botão deve alternar para noite!")
	assert(hud.day_night_button.text == "☀️ DIA", "Texto do botão deve ser '☀️ DIA' na noite!")
	EventBus.request_day_night_toggle.emit()
	await get_tree().process_frame
	assert(day_night_cycle.is_night == false, "Segundo clique deve retornar para o dia!")
	assert(hud.day_night_button.text == "🌙 NOITE", "Texto do botão deve voltar para '🌙 NOITE'!")
	print("✓ Botão de alternar Dia/Noite verificado com sucesso!")

	# --- TESTE DO MODO IMORTAL ---
	print("-> Testando Modo Imortal...")
	GameManager.immortal = true
	assert(player.immortal == true, "player.immortal deve refletir GameManager.immortal!")
	GameManager.trigger_game_over()
	await get_tree().process_frame
	assert(GameManager.state == GameManager.GameState.PLAYING, "Quando imortal, não deve entrar em GAME_OVER!")
	GameManager.immortal = false
	assert(player.immortal == false, "player.immortal deve ser false após desativar!")
	print("✓ Modo Imortal verificado com sucesso!")

	# --- TESTE DO OBSTÁCULO FOGUEIRA ---
	print("-> Testando obstáculo Fogueira (animação do fogo com 3 sprites)...")
	var pool_fogueira = world.spawner.get_node_or_null("PoolFogueira")
	assert(pool_fogueira != null, "PoolFogueira deve existir no Spawner!")
	var fogueira: Obstacle = pool_fogueira.get_instance() as Obstacle
	assert(fogueira != null, "Deve conseguir instanciar uma Fogueira do pool!")
	assert(fogueira.obstacle_type == "fogueira", "Tipo deve ser 'fogueira'!")
	assert(fogueira.sprite != null and fogueira.sprite.texture != null, "Sprite da fogueira deve estar carregado!")
	assert(fogueira.collision != null and fogueira.collision.shape != null, "Fogueira deve possuir colisor!")

	# Testa ciclo de animação da fogueira (3 sprites: fogueira1, fogueira2, fogueira3)
	var tex1 = fogueira.sprite.texture
	fogueira._process(0.11)
	var tex2 = fogueira.sprite.texture
	fogueira._process(0.11)
	var tex3 = fogueira.sprite.texture
	fogueira._process(0.11)
	var tex4 = fogueira.sprite.texture
	assert(tex1 != tex2, "Animação de fogo: Frame 1 deve transitar para Frame 2!")
	assert(tex2 != tex3, "Animação de fogo: Frame 2 deve transitar para Frame 3!")
	assert(tex4 == tex1, "Animação de fogo: Frame 3 deve retornar ciclicamente para Frame 1!")
	print("✓ Animação dos 3 sprites de fogo verificada com sucesso!")
	fogueira.returned_to_pool.emit()

	# --- TESTE DE GAME OVER ---
	print("-> Testando Game Over...")
	GameManager.trigger_game_over()
	await get_tree().process_frame
	assert(GameManager.state == GameManager.GameState.GAME_OVER, "Estado deve ser GAME_OVER")
	assert(game_over_screen.visible == true, "GameOverScreen deve estar visível")
	assert(hud.visible == false, "HUD deve estar oculto")
	print("✓ Game Over confirmado! High score: ", GameManager.high_score)

	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
