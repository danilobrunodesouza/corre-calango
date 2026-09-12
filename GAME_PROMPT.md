# 🦎 PROMPT MESTRE — Corre Calango! (Godot 4 · Web/Mobile)

## Contexto e Objetivo

Você é um desenvolvedor expert em Godot 4 e GDScript. Sua tarefa é criar do zero o jogo **"Corre Calango!"**, um endless runner 2D inspirado no Dino Runner do Google Chrome, usando **Godot 4.x** com exportação para **Web (HTML5)**, otimizado para jogar no **celular (touch)** e no navegador desktop.

O personagem principal é um **calango (lagarto) com chapéu de cangaceiro** que corre automaticamente e o jogador precisa pular ou abaixar para desviar de obstáculos (cactos).

---

## Regras de Ouro — Leia Antes de Implementar

1. **Planeje antes de criar qualquer cena ou script.** Liste todos os arquivos que serão criados.
2. **Use a skill `godot-gdscript-patterns`** disponível no projeto. Ela define padrões de:
   - StateMachine (para estados do player e do jogo)
   - Autoload Singletons (GameManager, EventBus)
   - Object Pooling (para obstáculos)
   - Component System
3. **Pense passo a passo.** Implemente na ordem: estrutura do projeto → autoloads → cenas base → player → obstáculos → cenário parallax → UI → lógica de jogo → exportação.
4. **Não invente APIs.** Consulte a documentação oficial Godot 4 se tiver dúvida sobre um nó ou método.
5. **Todos os assets estão prontos** na pasta `assets/`. Não crie imagens placeholder.

---

## Assets Disponíveis — Mapeamento Completo

```
assets/
├── spritesheet (2).png   # Spritesheet do calango (fundo preto)
│                         #   CORRENDO  → 4 frames × 96×96 px  (linha 0, y=0)
│                         #   PULANDO   → 4 frames × 96×96 px  (linha 1, y=96)
│                         #   AGACHADO  → 2 frames × 112×64 px (linha 2, y=192)
├── cacto1.png            # Obstáculo cacto alto
├── cacto2.png            # Obstáculo cacto baixo/largo (variação)
├── linha.png             # Linha do chão (tile horizontal)
├── montes.png            # Silhueta de montanhas (parallax lento)
├── nuvem-grande-v2.png   # Nuvem grande (parallax médio)
├── nuvem-media-v2.png    # Nuvem média (parallax rápido)
└── sol.png               # Sol (elemento estático decorativo)
```

> **Sobre o spritesheet:** O fundo é preto. Como o jogo tem estética retrô monocromática (sprites brancos sobre fundo preto), isso é intencional. Use `modulate = Color.WHITE` padrão.

---

## Arquitetura de Cenas — Hierarquia Completa

```
res://
├── project.godot
├── export_presets.cfg
├── assets/                    # pasta assets/ do projeto
├── autoloads/
│   ├── game_manager.gd        # Singleton: estado global, score, high score
│   └── event_bus.gd           # Singleton: sinais globais desacoplados
├── scenes/
│   ├── main/
│   │   ├── main.tscn          # Cena raiz
│   │   └── main.gd
│   ├── world/
│   │   ├── world.tscn         # Cenário com parallax + chão
│   │   └── world.gd
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd
│   │   └── states/
│   │       ├── state.gd       # Classe base State
│   │       ├── state_machine.gd
│   │       ├── run_state.gd
│   │       ├── jump_state.gd
│   │       └── duck_state.gd
│   ├── obstacles/
│   │   ├── object_pool.gd     # Pattern 4 da skill
│   │   ├── obstacle_spawner.tscn
│   │   ├── obstacle_spawner.gd
│   │   ├── cactus_tall.tscn
│   │   ├── cactus_wide.tscn
│   │   └── obstacle.gd
│   └── ui/
│       ├── hud.tscn
│       ├── hud.gd
│       ├── start_screen.tscn
│       └── game_over.tscn
```

---

## Especificações Técnicas

### 1. Configurações do Projeto (`project.godot`)

```ini
[display]
window/size/viewport_width = 960
window/size/viewport_height = 540
window/stretch/mode = "canvas_items"
window/stretch/aspect = "expand"

[rendering]
renderer/rendering_method = "mobile"

[input]
; Actions a criar:
; "jump" → Space, ArrowUp, W
; "duck" → ArrowDown, S
```

---

### 2. Autoload: `GameManager` (`autoloads/game_manager.gd`)

Implemente seguindo o **Pattern 2 (Autoload Singletons)** da skill `godot-gdscript-patterns`:

```gdscript
extends Node

signal game_started
signal game_over_triggered
signal score_changed(new_score: int)

enum GameState { IDLE, PLAYING, GAME_OVER }

const SPEED_INCREMENT: float = 10.0
const MAX_SPEED: float = 900.0

var state: GameState = GameState.IDLE
var score: int = 0
var high_score: int = 0
var game_speed: float = 300.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_high_score()

func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	score += int(game_speed * delta * 0.1)
	score_changed.emit(score)
	var new_speed := 300.0 + (score / 200) * SPEED_INCREMENT
	game_speed = minf(new_speed, MAX_SPEED)

func start_game() -> void:
	score = 0
	game_speed = 300.0
	state = GameState.PLAYING
	game_started.emit()

func trigger_game_over() -> void:
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	if score > high_score:
		high_score = score
		_save_high_score()
	game_over_triggered.emit()

func _load_high_score() -> void:
	if FileAccess.file_exists("user://save.dat"):
		var file := FileAccess.open("user://save.dat", FileAccess.READ)
		high_score = file.get_32()

func _save_high_score() -> void:
	var file := FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_32(high_score)
```

---

### 3. Autoload: `EventBus` (`autoloads/event_bus.gd`)

```gdscript
extends Node

signal player_jumped
signal player_ducked
signal player_died
signal obstacle_passed
```

Registre ambos em `Project > Project Settings > Autoload`:
- `GameManager` → `autoloads/game_manager.gd`
- `EventBus` → `autoloads/event_bus.gd`

---

### 4. StateMachine — Pattern 1 da Skill

Copie exatamente o `state_machine.gd` e `state.gd` do **Pattern 1** da skill `godot-gdscript-patterns`.

**`player.gd`** — nó raiz `CharacterBody2D`:

```gdscript
class_name Player
extends CharacterBody2D

const GRAVITY: float = 2000.0
const JUMP_FORCE: float = -750.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	_setup_animations()

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	move_and_slide()

func is_on_floor_custom() -> bool:
	return is_on_floor()

func jump() -> void:
	velocity.y = JUMP_FORCE
	EventBus.player_jumped.emit()

func duck_start() -> void:
	var shape := collision.shape as CapsuleShape2D
	shape.height = 32.0
	collision.position.y = 16.0

func duck_end() -> void:
	var shape := collision.shape as CapsuleShape2D
	shape.height = 64.0
	collision.position.y = 0.0

func _setup_animations() -> void:
	var sheet := preload("res://assets/spritesheet (2).png")
	var frames := SpriteFrames.new()

	# Animação CORRENDO — 4 frames 96x96, linha 0
	frames.add_animation("run")
	frames.set_animation_speed("run", 10.0)
	frames.set_animation_loop("run", true)
	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 96, 0, 96, 96)
		frames.add_frame("run", atlas)

	# Animação PULANDO — 4 frames 96x96, linha 1 (y=96)
	frames.add_animation("jump")
	frames.set_animation_speed("jump", 8.0)
	frames.set_animation_loop("jump", false)
	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 96, 96, 96, 96)
		frames.add_frame("jump", atlas)

	# Animação AGACHADO — 2 frames 112x64, linha 2 (y=192)
	frames.add_animation("duck")
	frames.set_animation_speed("duck", 6.0)
	frames.set_animation_loop("duck", true)
	for i in 2:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * 112, 192, 112, 64)
		frames.add_frame("duck", atlas)

	sprite.sprite_frames = frames
	sprite.play("run")
```

> **⚠ Atenção:** As coordenadas Y do spritesheet (0, 96, 192) são estimativas. Ao implementar, abra a imagem no Godot e verifique as coordenadas exatas de cada linha de frames e ajuste se necessário.

**Estados do player:**

```gdscript
# run_state.gd
class_name RunState
extends State

@export var player: Player

func enter(_msg: Dictionary = {}) -> void:
	player.sprite.play("run")

func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and player.is_on_floor_custom():
		state_machine.transition_to("Jump")
	elif Input.is_action_pressed("duck"):
		state_machine.transition_to("Duck")

# jump_state.gd
class_name JumpState
extends State

@export var player: Player

func enter(_msg: Dictionary = {}) -> void:
	player.sprite.play("jump")
	player.jump()

func physics_update(_delta: float) -> void:
	if player.is_on_floor_custom():
		state_machine.transition_to("Run")

# duck_state.gd
class_name DuckState
extends State

@export var player: Player

func enter(_msg: Dictionary = {}) -> void:
	player.sprite.play("duck")
	player.duck_start()

func exit() -> void:
	player.duck_end()

func physics_update(_delta: float) -> void:
	if not Input.is_action_pressed("duck"):
		state_machine.transition_to("Run")
```

**`player.tscn` — hierarquia de nós:**
```
Player (CharacterBody2D)  [script: player.gd]
├── AnimatedSprite2D
├── CollisionShape2D       [CapsuleShape2D, height=64]
├── HurtboxArea (Area2D)   [group: "player_hurtbox"]
│   └── CollisionShape2D
└── StateMachine (Node)    [script: state_machine.gd, initial_state → Run]
	├── Run (Node)         [script: run_state.gd]
	├── Jump (Node)        [script: jump_state.gd]
	└── Duck (Node)        [script: duck_state.gd]
```

---

### 5. Input Touch (Mobile)

No `main.gd`:

```gdscript
func _input(event: InputEvent) -> void:
	var vp_height := get_viewport().get_visible_rect().size.y

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.y < vp_height / 2.0:
				# Metade superior = pular
				Input.action_press("jump")
				await get_tree().create_timer(0.05).timeout
				Input.action_release("jump")
			else:
				# Metade inferior = agachar
				Input.action_press("duck")
		else:
			Input.action_release("duck")
```

---

### 6. Cenário Parallax (`scenes/world/world.tscn`)

**Hierarquia de nós:**
```
World (Node2D)  [script: world.gd]
├── ParallaxBackground
│   ├── ParallaxLayer [Sol]           motion_scale=(0.0, 0.0)   mirroring=(0,0)
│   │   └── Sprite2D [sol.png]
│   ├── ParallaxLayer [Montes]        motion_scale=(0.1, 0.0)   mirroring=(largura_img, 0)
│   │   └── Sprite2D [montes.png]
│   ├── ParallaxLayer [NuvemGrande]   motion_scale=(0.3, 0.0)   mirroring=(largura_img, 0)
│   │   └── Sprite2D [nuvem-grande-v2.png]
│   └── ParallaxLayer [NuvemMedia]    motion_scale=(0.5, 0.0)   mirroring=(largura_img, 0)
│       └── Sprite2D [nuvem-media-v2.png]
├── Ground (Node2D)
│   ├── GroundSprite (Sprite2D)       [linha.png, region=true, hframes tiled]
│   └── GroundBody (StaticBody2D)
│       └── CollisionShape2D          [WorldBoundaryShape2D ou retângulo fino]
└── ObstacleSpawner (Node)  [script: obstacle_spawner.gd]
```

**`world.gd`:**
```gdscript
extends Node2D

@onready var parallax: ParallaxBackground = $ParallaxBackground
@onready var ground_sprite: Sprite2D = $Ground/GroundSprite

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var speed := GameManager.game_speed

	# Avança o scroll do parallax — Godot cuida do loop via mirroring
	parallax.scroll_offset.x -= speed * delta

	# Loop manual da textura do chão
	ground_sprite.region_rect.position.x += speed * delta
	if ground_sprite.region_rect.position.x >= ground_sprite.texture.get_width():
		ground_sprite.region_rect.position.x = 0.0
```

**Configuração do chão (`linha.png`):**
- `Sprite2D > Region > Enabled = true`
- `Region Rect`: `x=0, y=0, w=1920, h=40` (ou largura da viewport × 2)
- Posição Y: no nível do chão (ex.: y=500 para viewport 540)
- `StaticBody2D` com `WorldBoundaryShape2D` logo abaixo

---

### 7. Obstáculos — Object Pooling

Copie o **Pattern 4 (Object Pooling)** da skill `godot-gdscript-patterns` como `object_pool.gd`.

**`obstacle.gd`:**
```gdscript
class_name Obstacle
extends Area2D

signal returned_to_pool

var speed: float = 300.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func on_spawn() -> void:
	speed = GameManager.game_speed

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	position.x -= speed * delta
	if position.x < -300.0:
		returned_to_pool.emit()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		EventBus.player_died.emit()
		GameManager.trigger_game_over()
```

**`obstacle_spawner.gd`:**
```gdscript
extends Node

@export var cactus_tall_scene: PackedScene
@export var cactus_wide_scene: PackedScene
@export var spawn_x: float = 1050.0
@export var ground_y: float = 460.0

var _pool_tall: ObjectPool
var _pool_wide: ObjectPool
var _timer: float = 0.0
var _next_spawn: float = 2.0

func _ready() -> void:
	_pool_tall = ObjectPool.new()
	_pool_tall.pooled_scene = cactus_tall_scene
	_pool_tall.initial_size = 5
	_pool_tall.can_grow = true
	add_child(_pool_tall)

	_pool_wide = ObjectPool.new()
	_pool_wide.pooled_scene = cactus_wide_scene
	_pool_wide.initial_size = 5
	_pool_wide.can_grow = true
	add_child(_pool_wide)

	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)

func _on_game_started() -> void:
	_timer = 0.0
	_next_spawn = 2.0
	set_process(true)

func _on_game_over() -> void:
	set_process(false)
	_pool_tall.return_all()
	_pool_wide.return_all()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next_spawn:
		_timer = 0.0
		_spawn_obstacle()
		_schedule_next()

func _schedule_next() -> void:
	var ratio := GameManager.game_speed / GameManager.MAX_SPEED
	_next_spawn = randf_range(lerpf(1.5, 0.7, ratio), lerpf(3.0, 1.4, ratio))

func _spawn_obstacle() -> void:
	var pool := _pool_tall if randf() > 0.4 else _pool_wide
	var obs := pool.get_instance() as Node2D
	if obs == null:
		return
	obs.global_position = Vector2(spawn_x, ground_y)
	obs.speed = GameManager.game_speed
```

---

### 8. UI

**`hud.gd`:**
```gdscript
extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var hi_label: Label = $HiLabel

func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	hi_label.text = "HI: %05d" % GameManager.high_score

func _on_score_changed(s: int) -> void:
	score_label.text = "%05d" % s
	hi_label.text = "HI: %05d" % GameManager.high_score
```

**Tela de Start (`start_screen.tscn`):**
- Label grande: "🦎 CORRE CALANGO!"
- Label menor: "Toque na tela ou pressione ESPAÇO"
- AnimationPlayer com bounce na escala do label principal

**Tela de Game Over (`game_over.tscn`):**
- Label: "GAME OVER"
- Label score atual e high score
- Label: "Toque para jogar novamente"
- Conecte ao sinal `GameManager.game_over_triggered`

---

### 9. Main Scene (`scenes/main/main.tscn`)

**Hierarquia:**
```
Main (Node2D)  [script: main.gd]
├── World (instância de world.tscn)
│   └── Player (instância de player.tscn) — filho do World
├── HUD (instância de hud.tscn)
├── StartScreen (instância de start_screen.tscn)
└── GameOverScreen (instância de game_over.tscn)
```

**`main.gd`:**
```gdscript
extends Node

@onready var hud: CanvasLayer = $HUD
@onready var start_screen: CanvasLayer = $StartScreen
@onready var game_over_screen: CanvasLayer = $GameOverScreen

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	GameManager.game_started.connect(_on_game_started)
	start_screen.show()
	game_over_screen.hide()
	hud.hide()

func _input(event: InputEvent) -> void:
	# Touch input
	_handle_touch(event)

	match GameManager.state:
		GameManager.GameState.IDLE:
			if event.is_action_just_pressed("jump"):
				GameManager.start_game()
		GameManager.GameState.GAME_OVER:
			if event.is_action_just_pressed("jump"):
				get_tree().reload_current_scene()

func _handle_touch(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	var vp_h := get_viewport().get_visible_rect().size.y
	if event.pressed:
		if event.position.y < vp_h / 2.0:
			Input.action_press("jump")
			get_tree().create_timer(0.05).timeout.connect(
				func(): Input.action_release("jump"), CONNECT_ONE_SHOT)
		else:
			Input.action_press("duck")
	else:
		Input.action_release("duck")

func _on_game_started() -> void:
	start_screen.hide()
	game_over_screen.hide()
	hud.show()

func _on_player_died() -> void:
	game_over_screen.show()
	hud.hide()
	# Atualiza UI do game over
	game_over_screen.get_node("ScoreLabel").text = "Score: %05d" % GameManager.score
	game_over_screen.get_node("HiLabel").text = "Recorde: %05d" % GameManager.high_score
```

---

## Configuração de Exportação Web

1. `Editor > Manage Export Templates` → baixe os templates Web
2. `Project > Export > Add > Web`
3. Configurações importantes:
   - `HTML > Canvas Resize Policy = Fit to Canvas`
   - `HTML > Focus Canvas on Start = true`
   - `VRAM Texture Compression > For Mobile = true`
4. `Project Settings > Display > Window > Handheld > Orientation = Landscape`

---

## Checklist de Implementação (ordem obrigatória)

- [ ] **1.** Criar estrutura de pastas e copiar assets
- [ ] **2.** Configurar `project.godot` (viewport, renderer, input actions)
- [ ] **3.** Implementar `event_bus.gd` e registrar como Autoload
- [ ] **4.** Implementar `game_manager.gd` e registrar como Autoload
- [ ] **5.** Criar `state.gd` e `state_machine.gd` (Pattern 1 da skill)
- [ ] **6.** Criar `object_pool.gd` (Pattern 4 da skill)
- [ ] **7.** Criar `world.tscn` com ParallaxBackground + chão
- [ ] **8.** Criar `player.tscn` com nós e scripts
- [ ] **9.** Implementar `_setup_animations()` e verificar coordenadas do spritesheet
- [ ] **10.** Criar estados Run, Jump, Duck e conectar à StateMachine
- [ ] **11.** Criar cenas de cacto (`cactus_tall.tscn`, `cactus_wide.tscn`)
- [ ] **12.** Implementar `obstacle_spawner.gd`
- [ ] **13.** Criar `hud.tscn`, `start_screen.tscn`, `game_over.tscn`
- [ ] **14.** Montar `main.tscn` unindo todos os sistemas
- [ ] **15.** Testar input teclado e touch no navegador
- [ ] **16.** Configurar e testar exportação Web
- [ ] **17.** Ajustar física (gravidade, força do pulo) e hitboxes (70% do sprite)
- [ ] **18.** Validar dificuldade progressiva e high score persistido

---

## Armadilhas e Soluções

| Problema | Solução |
|---|---|
| `ParallaxLayer` não faz loop | Defina `mirroring = Vector2(largura_imagem, 0)` no ParallaxLayer |
| Player atravessa o chão | Use `WorldBoundaryShape2D` no StaticBody2D do chão |
| Toque não funciona na web | `html/focus_canvas_on_start=true` no preset de exportação |
| Hitbox de agachar incorreta | Ajuste `collision.position.y` ao mudar height da CapsuleShape2D |
| Pool retorna null | `can_grow = true` e sempre cheque `if obs == null: return` |
| High score não persiste na web | `user://` usa IndexedDB no browser — funciona nativamente em Godot 4 |
| Frames errados no spritesheet | Abra o spritesheet no Godot e use o inspetor para verificar Rect2 exato |
| Player pula infinitamente | Cheque `is_on_floor()` — certifique-se que a colisão do chão está ativa |

---

## Critérios de Aceite

Ao terminar, o jogo deve:

1. ✅ Rodar sem erros no editor Godot 4
2. ✅ Exportar para Web sem warnings críticos
3. ✅ Funcionar com teclado: Espaço/↑ = pular, ↓ = agachar
4. ✅ Funcionar com toque no mobile (metade superior = pular, inferior = agachar)
5. ✅ Parallax com 3 camadas de velocidade diferentes funcionando em loop
6. ✅ Score crescendo e velocidade aumentando progressivamente
7. ✅ High score persistido entre sessões (via `user://save.dat`)
8. ✅ Telas de Start e Game Over funcionando
9. ✅ Sem memory leaks (pool de obstáculos com retorno correto)
10. ✅ Player com 3 estados animados: correndo, pulando, agachado

---

*Assets em `assets/`. Skill ativa: `godot-gdscript-patterns` (padrões: StateMachine, Autoload, ObjectPool).*
