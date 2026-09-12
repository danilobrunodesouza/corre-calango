## Player — Calango com chapéu de cangaceiro.
## CharacterBody2D com StateMachine e animações alinhadas por centro.
class_name Player
extends CharacterBody2D

const StateMachineScript = preload("res://scenes/player/states/state_machine.gd")
const RunStateScript = preload("res://scenes/player/states/run_state.gd")
const JumpStateScript = preload("res://scenes/player/states/jump_state.gd")
const DuckStateScript = preload("res://scenes/player/states/duck_state.gd")

const GRAVITY: float = 2000.0
const JUMP_FORCE: float = -750.0
const NORMAL_HEIGHT: float = 64.0
const DUCK_HEIGHT: float = 32.0
const SPRITE_SCALE: Vector2 = Vector2(0.35, 0.35)

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

func _ready() -> void:
	add_to_group("player")
	_ensure_child_nodes()

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
		shape.radius = 20.0
		shape.height = NORMAL_HEIGHT
		collision.shape = shape
		add_child(collision)

	# 3. HurtboxArea (Detecção de colisão com cactos)
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
		hshape.radius = 18.0
		hshape.height = NORMAL_HEIGHT * 0.85
		hurtbox_collision.shape = hshape
		hurtbox_area.add_child(hurtbox_collision)

	# 4. StateMachine — Adiciona os filhos ANTES de adicionar à árvore e inicializar
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
	if not sheet:
		push_error("Player: não foi possível carregar spritesheet")
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# --- CORRENDO — 4 frames alinhados no centro, velocidade 5.5 FPS ---
	frames.add_animation("run")
	frames.set_animation_speed("run", 5.5)
	frames.set_animation_loop("run", true)
	var run_rects: Array[Rect2] = [
		Rect2(40, 116, 320, 245),
		Rect2(392, 116, 320, 245),
		Rect2(755, 116, 320, 245),
		Rect2(1160, 116, 320, 245)
	]
	for r in run_rects:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = r
		frames.add_frame("run", atlas)

	# --- PULANDO — 4 frames 340x330, y=395 ---
	frames.add_animation("jump")
	frames.set_animation_speed("jump", 6.0)
	frames.set_animation_loop("jump", false)
	var jump_rects: Array[Rect2] = [
		Rect2(40, 395, 340, 330),
		Rect2(380, 395, 340, 330),
		Rect2(760, 395, 340, 330),
		Rect2(1140, 395, 340, 330)
	]
	for r in jump_rects:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = r
		frames.add_frame("jump", atlas)

	# --- AGACHADO — 2 frames ~360x155, y=835 ---
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
	sprite.play("run")
