# Integração com a Máquina de Estados do Player (`StateMachine`)

Este documento orienta a integração de spritesheets com a máquina de estados hierárquica do personagem principal (`scenes/player/states/`).

---

## 1. Estrutura Atual da StateMachine

A arquitetura do `Player` desacopla a entrada, as regras de transição e a física por meio de nós de estado dedicados:

```text
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HurtboxArea
└── StateMachine (Node)
    ├── Run (RunState)
    ├── Jump (JumpState)
    └── Duck (DuckState)
```

Cada estado herda de `res://scenes/player/states/state.gd` e implementa:
- `enter(_msg: Dictionary = {})`: Inicialização do estado, acionamento da animação via `sprite.play("nome")` e emissão de eventos.
- `exit()`: Limpeza antes da transição.
- `physics_update(delta: float)`: Verificação de condições de transição (ex: velocidade Y, `is_on_floor()`).
- `handle_input(event: InputEvent)`: Captura de comandos do jogador.

---

## 2. Caso A: Melhorar um Comportamento Existente

Quando o spritesheet substitui ou refina um comportamento que já existe (ex: nova animação de pulo ou agachamento):

1. **Atualizar `player.gd`**:
   - Registrar o novo spritesheet e frames em `_setup_animations()`.
   - Atualizar a escala e offset em `_update_sprite_transform_for_anim()`.
2. **Revisar o Estado Correspondente**:
   - Por exemplo, em `jump_state.gd`:
     ```gdscript
     func enter(_msg: Dictionary = {}) -> void:
         _get_player()
         _jump_timer = 0.0
         if player and player.get("sprite"):
             player.get("sprite").play("jump")
         if player and player.has_method("jump"):
             player.jump()
     ```
   - Ajustar tempos mínimos de permanência se a nova animação tiver duração específica (ex: checagem de `_jump_timer >= 0.12`).

---

## 3. Caso B: Adicionar um Novo Comportamento

Exemplo: Adicionar um comportamento de **Deslize/Dash** (`slide`) ou **Morte/Impacto** (`hurt`).

### Passo 1: Criar o Script do Novo Estado
Crie `scenes/player/states/slide_state.gd`:
```gdscript
extends "res://scenes/player/states/state.gd"

var player: CharacterBody2D
var _slide_timer: float = 0.0
const SLIDE_DURATION: float = 0.6

func enter(_msg: Dictionary = {}) -> void:
    player = get_parent().get_parent() as CharacterBody2D
    _slide_timer = 0.0
    if player and player.get("sprite"):
        player.get("sprite").play("slide")
    # Reduz colisor se necessário
    if player and player.has_method("duck_start"):
        player.duck_start()
    EventBus.emit_signal("player_slid")

func exit() -> void:
    if player and player.has_method("duck_end"):
        player.duck_end()

func physics_update(delta: float) -> void:
    _slide_timer += delta
    if _slide_timer >= SLIDE_DURATION:
        state_machine.transition_to("Run")
```

### Passo 2: Registrar o Estado em `_ensure_child_nodes()` em `player.gd`
```gdscript
const SlideStateScript = preload("res://scenes/player/states/slide_state.gd")

# Dentro de _ensure_child_nodes():
var slide_st := SlideStateScript.new()
slide_st.name = "Slide"
state_machine.add_child(slide_st)
```

### Passo 3: Adicionar a Transição de Entrada
Em `run_state.gd` ou no input do `player.gd`:
```gdscript
func handle_input(event: InputEvent) -> void:
    if event.is_action_pressed("slide") and player.is_on_floor():
        state_machine.transition_to("Slide")
```

---

## 4. Comunicação com `EventBus` e `GameJuice`

Sempre que um novo comportamento ou animação for integrado:
1. Emita o sinal correspondente no `EventBus` (ex: `EventBus.player_jumped.emit()`).
2. Conecte com o sistema de feedback tátil (`godot-game-juice`), como poeira de partículas (`CPUParticles2D`) ao pular ou aterrissar.
