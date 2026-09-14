---
name: godot-player-gameplay
description: >-
  Specialist skill for calibrating, aligning, and synchronizing player character gameplay, physics, and ground anchor origins in Godot 4 endless runners. Use whenever the player has different origins between running, jumping, or ducking, when spritesheets cause visual jitter or ground sinking/floating, when tuning jump force, gravity, and apex timing, or when refactoring player collision shapes and state machine transitions.
---

# Godot Player Gameplay & Grounding Specialist

Esta skill guia a refatoração, calibração matemática e manutenção da jogabilidade do personagem principal (**Player / Calango**) no **Corre Calango** (Godot 4). Ela resolve a causa raiz de spritesheets com dimensões heterogêneas, garantindo uma **Origem Canônica de Solo (Ground Anchor)** idêntica para corrida, salto e agachamento, além de sincronizar a física do `CharacterBody2D` com as animações.

---

## 1. Princípios Fundamentais da Jogabilidade

1. **Origem Canônica no Ponto de Contato do Solo ($Y_{ground} = +22.4\text{ px}$)**:
   - A física (`CollisionShape2D`) governa a interação com o mundo. Com a cápsula anatômica padrão (`NORMAL_HEIGHT = 44.8`, raio `14.0`), o ponto mais baixo da colisão que toca o chão físico fica em $Y = +22.4\text{ px}$ local.
   - Toda e qualquer animação deve posicionar a sola da pata do Calango rigorosamente nessa linha, compensando as diferenças de altura de corte e margens transparentes.
   - Consulte a dedução matemática completa em [Arquitetura de Ground Anchor](./references/ground_anchor_architecture.md).

2. **Desacoplamento entre Física e Arte**:
   - A física do `CharacterBody2D` cuida da gravidade, aceleração e detecção de solo (`is_on_floor()`).
   - O `AnimatedSprite2D` adapta-se através da matriz de calibração `ANIMATION_OFFSETS`, disparada no sinal `animation_changed`. Nunca utilize valores arbitrários manuais sem cálculo de pixels.

3. **Sincronia do Arco de Salto**:
   - O salto físico dura $\approx 0.75\text{ s}$ ($v_{0y} = -525$, $g = 1400$).
   - A animação de pulo não repete em loop (`loop = false`). A ancoragem é calibrada pelo frame de decolagem (Frame 0), evitando o efeito de "dupla subida" quando o ilustrador desenha o personagem subindo dentro do frame.
   - Consulte o guia de sincronização em [Mecânicas de Salto](./references/jump_mechanics_and_sync.md).

4. **Preservação do Solo no Agachamento**:
   - Ao agachar (`DuckState`), a cápsula física reduz sua altura para `22.4 px`, e seu centro desce em $+11.2\text{ px}$. Isso assegura que a sola continue em $+22.4\text{ px}$, prevenindo trepidações e colisões falsas.
   - Consulte as diretrizes em [Regras de Colisão e Hitbox](./references/collision_and_hitbox_rules.md).

---

## 2. Ferramenta de Automação (CLI)

A skill inclui um utilitário CLI de alta precisão em Node.js (sem dependências externas) que decodifica os arquivos PNG, localiza os pixels exatos das patas e calcula os offsets ideais:

Script: [`scripts/calibrate_player_grounding.js`](./scripts/calibrate_player_grounding.js)

### Comandos Principais:

```bash
# Calibrar automaticamente todas as animações padrão (run, jump, duck) e gerar código GDScript
node .agents/skills/godot-player-gameplay/scripts/calibrate_player_grounding.js

# Inspecionar e sugerir offset para um spritesheet específico
node .agents/skills/godot-player-gameplay/scripts/calibrate_player_grounding.js \
  --inspect assets/calango-spritesheet-pulando.png \
  --cols 4

# Exportar calibração completa em JSON para automações
node .agents/skills/godot-player-gameplay/scripts/calibrate_player_grounding.js --json
```

---

## 3. Fluxo de Trabalho Passo a Passo para Refazer a Jogabilidade

Sempre que a jogabilidade apresentar inconsistências de origem, flutuação ou trepidação:

### Passo 1: Executar a Calibração Automática
Rode a CLI de calibração no terminal do projeto:
```bash
node .agents/skills/godot-player-gameplay/scripts/calibrate_player_grounding.js
```
Anote a matriz `ANIMATION_OFFSETS` gerada para as animações presentes no projeto.

### Passo 2: Atualizar a Matriz no `player.gd`
1. Remova quaisquer constantes de ajuste manual soltas (ex: `RUN_OFFSET_Y = 50.0`).
2. Defina `GROUND_Y_LOCAL: float = 22.4` e adicione a constante canônica:
   ```gdscript
   const ANIMATION_OFFSETS: Dictionary = {
       "run": Vector2(0.0, -21.4),
       "jump": Vector2(0.0, -15.0),
       "duck": Vector2(0.0, 3.4),
   }
   ```
3. Garanta que a função de atualização posicione o nó do sprite:
   ```gdscript
   func _on_animation_changed() -> void:
       _update_sprite_transform()

   func _update_sprite_transform() -> void:
       if sprite == null:
           return
       var anim := sprite.animation
       if ANIMATION_OFFSETS.has(anim):
           sprite.position = ANIMATION_OFFSETS[anim]
       else:
           sprite.position = Vector2.ZERO
   ```

### Passo 3: Verificar a Sincronização dos Estados (`scenes/player/states/`)
- Em `jump_state.gd`: garanta que a aterrissagem ocorra quando `player.is_on_floor()` após um tempo mínimo (`_jump_timer >= 0.10`), sem transições prematuras.
- Em `duck_state.gd`: verifique se `duck_start()` e `duck_end()` reposicionam `collision.position.y` para manter a base da cápsula fixa no solo.

### Passo 4: Validação com Godot Headless
Execute o Godot para validar sintaxe e inicialização de nós:
```powershell
& "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless --editor --quit
```

---

## 4. Templates Disponíveis

- [templates/calibrated_player.gd](./templates/calibrated_player.gd): Código de referência completo para o `Player`, incorporando a StateMachine, o tratamento de Ground Anchor, os ajustes de Duck e o isolamento de Hurtbox.
