# Mecânicas de Salto e Sincronização Física x Animação

Este documento estabelece as regras e fórmulas para a física do salto no **Corre Calango**, garantindo resposta precisa dos controles, fluidez visual e eliminação de trepidações (*jittering*) na aterrissagem.

---

## 1. Fundamentos da Cinemática do Salto

No Godot 4 2D, o salto é regido pela integração de aceleração e velocidade em `_physics_process`:

$$v_y(t) = v_{0y} + g \cdot t$$
$$y(t) = y_0 + v_{0y} \cdot t + \frac{1}{2} g \cdot t^2$$

### Constantes Calibradas do Jogo:
- **Gravidade ($g$)**: `1400.0 px/s²`
- **Força Inicial ($v_{0y}$)**: `-525.0 px/s`

### Métricas Físicas Derivadas:
1. **Tempo até o ápice ($t_{apex}$)**:
   $$t_{apex} = \frac{|v_{0y}|}{g} = \frac{525.0}{1400.0} = 0.375\text{ s}$$
2. **Tempo total no ar ($t_{air}$)** em terreno plano:
   $$t_{air} = 2 \times t_{apex} = 0.750\text{ s}$$
3. **Altura máxima do pulo ($H_{max}$)**:
   $$H_{max} = \frac{v_{0y}^2}{2g} = \frac{525^2}{2800} \approx 98.4\text{ px}$$

---

## 2. O Problema da Animação com Arco Embutido

Alguns spritesheets (como `calango-spritesheet-pulando.png`) foram desenhados com o personagem "subindo" internamente no quadro:
- **Frame 0**: Pata no chão (decolagem).
- **Frames 1 e 2**: Pata desenhada $70\text{ px}$ mais alta dentro do frame (tentativa de arco manual).
- **Frame 3**: Pata próxima ao chão (queda / pouso).

### O Conflito:
Se a física do `CharacterBody2D` já está elevando o nó em $98\text{ px}$, e o sprite simultaneamente sobe $70 \times 0.245 = 17.15\text{ px}$ dentro da imagem, ocorre um efeito de **"dupla subida"** e uma descontinuidade abrupta no momento em que a física encosta no chão e a animação retorna para `run`.

### Regras de Ouro da Animação de Salto:
1. **Sincronização do Framerate com a Gravidade**:
   A taxa de quadros da animação de salto deve coincidir exatamente com a duração total do voo físico:
   $$FPS_{jump} = \frac{N_{frames}}{t_{air}} = \frac{4}{0.75\text{ s}} \approx 5.33\text{ fps}$$
   Isso garante que:
   - Frame 0 (0.00s a 0.18s): Decolagem no solo.
   - Frame 1 (0.18s a 0.37s): Subida até o ápice exato da física ($0.375\text{s}$).
   - Frame 2 (0.37s a 0.56s): Primeira fase da descida.
   - Frame 3 (0.56s a 0.75s): Pouso suave, tocando o solo no mesmo instante em que a física encosta no chão.

2. **Compensação de Margem por Quadro (`AtlasTexture.margin`)**:
   Se os frames da spritesheet tiverem variações de sola entre decolagem e aterrissagem, use `atlas.margin` no `AtlasTexture` para normalizar a altura do solo:
   ```gdscript
   var jump_configs: Array[Dictionary] = [
       { "region": Rect2(0, 0, 384, 379), "margin": Rect2(0, 0, 384, 379) },
       { "region": Rect2(384, 0, 384, 379), "margin": Rect2(0, 0, 384, 379) },
       { "region": Rect2(768, 0, 384, 379), "margin": Rect2(0, 0, 384, 379) },
       { "region": Rect2(1152, 0, 384, 379), "margin": Rect2(0, 12, 384, 379) } # Compensa pata no pouso
   ]
   ```

3. **Loop Desativado (`loop = false`)**:
   A animação de salto nunca entra em repetição cíclica. Se o salto for mais longo do que a duração dos quadros, o último frame (preparação para queda/pouso) permanece congelado até o contato com o solo (`is_on_floor()`).

---

## 3. Transição Estável na Máquina de Estados (`JumpState`)

Para evitar saídas prematuras da animação antes do jogador realmente decolar:

```gdscript
# scenes/player/states/jump_state.gd
extends "res://scenes/player/states/state.gd"

var player: CharacterBody2D
var _jump_timer: float = 0.0
const MIN_JUMP_TIME: float = 0.10 # Impede re-trigger no mesmo frame do pulo

func enter(_msg: Dictionary = {}) -> void:
    _get_player()
    _jump_timer = 0.0
    if player:
        if player.get("sprite"):
            player.get("sprite").play("jump")
        if player.has_method("jump"):
            player.jump()

func physics_update(delta: float) -> void:
    _jump_timer += delta
    _get_player()
    if player and _jump_timer >= MIN_JUMP_TIME and player.is_on_floor():
        # Aterrissagem concluída com sucesso
        state_machine.transition_to("Run")
```

---

## 4. Polimento e Tolerância nos Controles

### Jump Buffering (Buffer de Salto):
Permite que o jogador aperte o botão de pulo até `0.10s` antes de tocar o solo, enfileirando o salto para o instante exato da aterrissagem. Elimina a sensação de "botão falhando".

### Coyote Time (Tempo Coiote):
Permite que o jogador pule até `0.08s` após sair do chão ou da borda da plataforma, tornando a física amigável ao tempo de reação humano.
