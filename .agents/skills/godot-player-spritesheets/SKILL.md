---
name: godot-player-spritesheets
description: >-
  Specialist skill for preparing, slicing, aligning, and integrating spritesheet animations for the main player character (Calango) in Godot 4 endless runners. Use whenever you need to add or replace player spritesheets, calibrate frame slices and dimensions, calculate scale and foot grounding offsets, refine existing behaviors (running, jumping, ducking), or implement new character states and animations (sliding, hurt, double jump, attack).
---

# Godot Player Spritesheets Specialist

Esta skill guia o processo de preparação, fatiamento, alinhamento de solo e integração de spritesheets para o personagem principal (**Player / Calango**) do jogo **Corre Calango** (Godot 4). Ela garante proporções consistentes, animações fluidas sem trepidação (jittering) e integração perfeita com a máquina de estados (`StateMachine`).

---

## 1. Princípios Fundamentais

1. **Alinhamento e Grounding (Contato com o Chão)**:
   - O ponto de contato das patas do Calango com o chão deve permanecer estável em todas as animações.
   - Como diferentes ilustrações podem ter alturas de quadro variadas, cada animação deve ter sua própria constante de escala (`SCALE`) e compensação vertical (`OFFSET`), sincronizadas no evento `animation_changed`.
   - Consulte o guia completo em [Alinhamento e Pivôs](./references/alignment_and_pivots.md).

2. **Isolamento de Hitbox e Física**:
   - Nós de colisão (`CollisionShape2D` de física e `HurtboxArea` de dano) operam de acordo com as dimensões anatômicas do personagem (`NORMAL_HEIGHT = 44.8` e `DUCK_HEIGHT = 22.4`).
   - O `AnimatedSprite2D` adapta-se à física, e **nunca** a física deve ser distorcida por causa de um frame mal cortado.

3. **Arquitetura Baseada em Estados (`StateMachine`)**:
   - Toda animação do jogador é disparada por um estado da `StateMachine` (`RunState`, `JumpState`, `DuckState`, etc.).
   - Para novos comportamentos (como deslize ou cambalhota), cria-se um novo nó de estado desacoplado.
   - Consulte os padrões em [Integração com a Máquina de Estados](./references/player_state_integration.md).

4. **Estudo de Caso Prático**:
   - Veja o exemplo detalhado com a spritesheet de pulo em [Estudo de Caso: Calango Pulando](./references/calango_jump_case_study.md).

---

## 2. Ferramenta de Automação (CLI)

A skill inclui um utilitário em Node.js (sem dependências externas) para inspecionar a imagem, fatiar em grid, calcular escala/offset e gerar o código GDScript:

Script: [`scripts/manage_player_spritesheet.js`](./scripts/manage_player_spritesheet.js)

### Comandos Principais:

```bash
# Inspecionar um spritesheet e detectar grid sugerido
node .agents/skills/godot-player-spritesheets/scripts/manage_player_spritesheet.js \
  --inspect assets/calango-spritesheet-pulando.png

# Fatiar e gerar código GDScript pronto para injeção no player.gd
node .agents/skills/godot-player-spritesheets/scripts/manage_player_spritesheet.js \
  --inspect assets/calango-spritesheet-pulando.png \
  --cols 4 \
  --anim jump \
  --fps 6.0 \
  --loop false \
  --generate-gdscript

# Obter metadados brutos em JSON para automações
node .agents/skills/godot-player-spritesheets/scripts/manage_player_spritesheet.js \
  --inspect assets/calango-spritesheet-pulando.png \
  --cols 4 \
  --json
```

---

## 3. Fluxo de Trabalho Passo a Passo

Sempre que o usuário solicitar incluir uma nova spritesheet ou melhorar um movimento do Calango:

### Passo 1: Localizar e Inspecionar o Asset
1. Certifique-se de que o arquivo PNG está na pasta `assets/` (ex: `assets/calango-spritesheet-pulando.png`).
2. Caso o arquivo tenha acabado de ser adicionado, garanta que o Godot gere o arquivo `.import`:
   ```powershell
   & "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless --editor --quit
   ```
3. Execute o comando de inspeção da CLI para verificar largura, altura e quantidade de quadros.

### Passo 2: Calcular Fatiamento e Transformações
1. Execute a CLI com a flag `--generate-gdscript`, especificando:
   - `--cols`: quantidade de quadros horizontais.
   - `--anim`: nome da animação (ex: `jump`, `run`, `duck`, `slide`).
   - `--fps`: taxa de quadros (normalmente `5.5` a `6.0` para corrida/pulo, `4.0` para agachamento).
   - `--loop`: `true` para ciclos contínuos (corrida, agachado) ou `false` para ações pontuais (pulo, dano).

### Passo 3: Atualizar o Player (`player.gd`)
1. Adicione as constantes geradas no topo do arquivo (ex: `JUMP_SCALE` e `JUMP_OFFSET`).
2. Adicione ou substitua o bloco da animação dentro do método `_setup_animations()`.
3. Adicione o caso correspondente na função `_update_sprite_transform_for_anim()`.

### Passo 4: Conectar à Máquina de Estados
- **Para aprimoramento de comportamento existente** (ex: novo pulo):
  - Abra o estado correspondente em `scenes/player/states/` (ex: `jump_state.gd`).
  - Verifique se a duração de animação e o temporizador de término (`_jump_timer`) conferem com os novos frames.
- **Para novos comportamentos** (ex: `slide`, `hurt`):
  - Crie um novo script em `scenes/player/states/<novo_estado>_state.gd`.
  - Registre o novo estado no método `_ensure_child_nodes()` do `player.gd`.
  - Conecte a transição no estado anterior e/ou no input do jogador.

### Passo 5: Verificação e Validação
1. Execute o Godot em modo headless ou rode a suíte de testes para garantir integridade do projeto:
   ```powershell
   & "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless scenes/main/main.tscn -- --test
   ```
2. Abra o jogo para checar o alinhamento visual e a resposta dos controles.
