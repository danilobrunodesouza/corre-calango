## Player — Calango com Ancoragem Canônica de Solo (Ground Anchor).
## CharacterBody2D com StateMachine desacoplada e matriz de offsets por animação.
class_name Player
extends CharacterBody2D

const StateMachineScript = preload("res://scenes/player/states/state_machine.gd")
const RunStateScript = preload("res://scenes/player/states/run_state.gd")
const JumpStateScript = preload("res://scenes/player/states/jump_state.gd")
const DuckStateScript = preload("res://scenes/player/states/duck_state.gd")

## Constantes de Física do Salto e Movimento
const GRAVITY: float = 1400.0
const JUMP_FORCE: float = -525.0

## Dimensões Anatômicas da Colisão
const NORMAL_HEIGHT: float = 44.8
const DUCK_HEIGHT: float = 22.4
const GROUND_Y_LOCAL: float = 22.4 # NORMAL_HEIGHT / 2.0 (ponto de contato com o chão)
const SPRITE_SCALE: Vector2 = Vector2(0.245, 0.245)

## Matriz de Calibração de Ground Anchor
## Cada animação compensa as diferenças de corte do frame para que a pata
## toque exatamente em GROUND_Y_LOCAL (+22.4 px)
const ANIMATION_OFFSETS: Dictionary = {
	"run": Vector2(0.0, 58.6),
	"jump": Vector2(0.0, 65.0),
	"duck": Vector2(0.0, 83.4),
}

## Modo imortal para testes (sincronizado com GameManager.immortal)
@export var immortal: bool:
	set(val):
		GameManager.immortal = val
	get:
		return GameManager.immortal

var sprite: AnimatedSprite2D
var collision: CollisionShape2D
var hurtbox_area: Area2D
var hurtbox_collision: CollisionShape2D
var state_machine: Node

var ground_y: float = 437.6

func _ready() -> void:
	add_to_group("player")
	_ensure_child_nodes()
	ground_y = global_position.y

func get_ground_y() -> float:
	if is_on_floor() or ground_y == 0.0:
		ground_y = global_position.y
	return ground_y

func _ensure_child_nodes() -> void:
	# 1. AnimatedSprite2D (configurado com animações antes de iniciar a StateMachine)
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.scale = SPRITE_SCALE
		add_child(sprite)
	_setup_animations()

	# 2. CollisionShape2D (Física com o chão)
	collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CapsuleShape2D.new()
		shape.radius = 14.0
		shape.height = NORMAL_HEIGHT
		collision.shape = shape
		add_child(collision)

	# 3. HurtboxArea (Detecção de colisão com perigos)
	hurtbox_area = get_node_or_null("HurtboxArea") as Area2D
	if hurtbox_area == null:
		hurtbox_area = Area2D.new()
		hurtbox_area.name = "HurtboxArea"
		add_child(hurtbox_area)
	hurtbox_area.add_to_group("player_hurtbox")

	hurtbox_collision = hurtbox_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurtbox_collision == null:
		hurtbox_collision = CollisionShape2D.new()
		hurtbox_collision.name = "CollisionShape2D"
		var hshape := CapsuleShape2D.new()
		hshape.radius = 12.6
		hshape.height = NORMAL_HEIGHT * 0.85
		hurtbox_collision.shape = hshape
		hurtbox_area.add_child(hurtbox_collision)

	# 4. StateMachine
	state_machine = get_node_or_null("StateMachine")
	if state_machine == null:
		state_machine = StateMachineScript.new()
		state_machine.name = "StateMachine"

		var run_st := RunStateScript.new()
		run_st.name = "Run"
		state_machine.add_child(run_st)

		var jump_st := JumpStateScript.new()
		jump_st.name = "Jump"
		state_machine.add_child(jump_st)

		var duck_st := DuckStateScript.new()
		duck_st.name = "Duck"
		state_machine.add_child(duck_st)

		add_child(state_machine)
		if state_machine.has_method("init_states"):
			state_machine.call("init_states")

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()
	if is_on_floor():
		ground_y = global_position.y

func is_on_floor_custom() -> bool:
	return is_on_floor()

func try_jump() -> bool:
	if is_on_floor():
		if state_machine and state_machine.has_method("transition_to"):
			state_machine.transition_to("Jump")
			return true
	return false

func jump() -> void:
	velocity.y = JUMP_FORCE
	EventBus.player_jumped.emit()

func duck_start() -> void:
	# Ao agachar, a cápsula reduz para DUCK_HEIGHT e o centro desce
	# para que a base continue rigorosamente ancorada em GROUND_Y_LOCAL (+22.4)
	if collision and collision.shape is CapsuleShape2D:
		var shape := collision.shape as CapsuleShape2D
		shape.height = DUCK_HEIGHT
		collision.position.y = (NORMAL_HEIGHT - DUCK_HEIGHT) * 0.5

	if hurtbox_collision and hurtbox_collision.shape is CapsuleShape2D:
		var hshape := hurtbox_collision.shape as CapsuleShape2D
		hshape.height = DUCK_HEIGHT * 0.85
		hurtbox_collision.position.y = collision.position.y

	EventBus.player_ducked.emit()

func duck_end() -> void:
	if collision and collision.shape is CapsuleShape2D:
		var shape := collision.shape as CapsuleShape2D
		shape.height = NORMAL_HEIGHT
		collision.position.y = 0.0

	if hurtbox_collision and hurtbox_collision.shape is CapsuleShape2D:
		var hshape := hurtbox_collision.shape as CapsuleShape2D
		hshape.height = NORMAL_HEIGHT * 0.85
		hurtbox_collision.position.y = 0.0

func _setup_animations() -> void:
	if sprite == null:
		return

	var sheet: Texture2D = load("res://assets/spritesheet (2).png")
	var run_sheet: Texture2D = load("res://assets/calango-correndo.png")
	if not run_sheet:
		push_error("Player: não foi possível carregar calango-correndo.png")
		run_sheet = sheet

	var jump_sheet: Texture2D = load("res://assets/calango-spritesheet-pulando.png")
	if not jump_sheet:
		push_error("Player: não foi possível carregar calango-spritesheet-pulando.png")
		jump_sheet = sheet

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# --- CORRENDO — 4 frames em calango-correndo.png ---
	frames.add_animation("run")
	frames.set_animation_speed("run", 5.5)
	frames.set_animation_loop("run", true)
	var run_configs: Array[Dictionary] = [
		{ "region": Rect2(6, 0, 384, 425), "margin": Rect2(0, 0, 384, 425) },
		{ "region": Rect2(391, 0, 384, 425), "margin": Rect2(0, 0, 384, 425) },
		{ "region": Rect2(777, 0, 378, 425), "margin": Rect2(3, 0, 384, 425) },
		{ "region": Rect2(1152, 0, 384, 425), "margin": Rect2(0, 0, 384, 425) }
	]
	for cfg in run_configs:
		var atlas := AtlasTexture.new()
		atlas.atlas = run_sheet
		atlas.region = cfg["region"]
		atlas.margin = cfg["margin"]
		atlas.filter_clip = true
		frames.add_frame("run", atlas)

	# --- PULANDO — 4 frames em calango-spritesheet-pulando.png ---
	# Sincronizado: 0.75s de física / 4 frames = 5.33 FPS
	if jump_sheet:
		frames.add_animation("jump")
		frames.set_animation_speed("jump", 5.33)
		frames.set_animation_loop("jump", false)
		var jump_configs: Array[Dictionary] = [
			{ "region": Rect2(0, 0, 384, 379), "margin": Rect2(0, 0, 384, 379) },
			{ "region": Rect2(384, 0, 384, 379), "margin": Rect2(0, 0, 384, 379) },
			{ "region": Rect2(768, 0, 384, 379), "margin": Rect2(0, 0, 384, 379) },
			{ "region": Rect2(1152, 0, 384, 379), "margin": Rect2(0, 12, 384, 379) }
		]
		for cfg in jump_configs:
			var atlas := AtlasTexture.new()
			atlas.atlas = jump_sheet
			atlas.region = cfg["region"]
			atlas.margin = cfg["margin"]
			atlas.filter_clip = true
			frames.add_frame("jump", atlas)

	# --- AGACHADO — 2 frames em spritesheet (2).png ---
	if sheet:
		frames.add_animation("duck")
		frames.set_animation_speed("duck", 4.0)
		frames.set_animation_loop("duck", true)
		var duck_rects: Array[Rect2] = [
			Rect2(40, 835, 360, 155),
			Rect2(500, 835, 360, 155)
		]
		for r in duck_rects:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = r
			frames.add_frame("duck", atlas)

	sprite.sprite_frames = frames
	if not sprite.animation_changed.is_connected(_on_animation_changed):
		sprite.animation_changed.connect(_on_animation_changed)

	sprite.play("run")
	_update_sprite_transform()

func _on_animation_changed() -> void:
	_update_sprite_transform()

## Aplica o offset compensado de solo canônico correspondente à animação atual
func _update_sprite_transform() -> void:
	if sprite == null:
		return
	var anim := sprite.animation
	if ANIMATION_OFFSETS.has(anim):
		sprite.position = ANIMATION_OFFSETS[anim]
	else:
		sprite.position = Vector2.ZERO
