# Estudo de Caso: Integração de `calango-spritesheet-pulando.png`

Este documento serve como exemplo prático de ponta a ponta da utilização da skill para integrar ou aprimorar a animação de pulo do Calango utilizando a spritesheet dedicada `assets/calango-spritesheet-pulando.png`.

---

## 1. Dados do Asset

- **Caminho**: `res://assets/calango-spritesheet-pulando.png`
- **Dimensões do arquivo**: 1536 x 379 px
- **Formato**: PNG com canal alfa (fundo transparente)
- **Estrutura**: 4 quadros alinhados horizontalmente (1 linha de 4 colunas)
- **Dimensão de cada quadro**: $1536 / 4 = 384\text{ px}$ de largura por $379\text{ px}$ de altura

---

## 2. Execução do Script de Automação

Executando o script da skill:

```bash
node .agents/skills/godot-player-spritesheets/scripts/manage_player_spritesheet.js \
  --inspect assets/calango-spritesheet-pulando.png \
  --cols 4 \
  --anim jump \
  --fps 6.0 \
  --loop false \
  --generate-gdscript
```

### Saída gerada:
- **Frame 0**: `Rect2(0, 0, 384, 379)` — Preparação do pulo (calango flexionando patas)
- **Frame 1**: `Rect2(384, 0, 384, 379)` — Impulsão ascendente
- **Frame 2**: `Rect2(768, 0, 384, 379)` — Ápice do pulo com chapéu e corpo estendido
- **Frame 3**: `Rect2(1152, 0, 384, 379)` — Queda e preparação para o pouso
- **Escala recomendada**: `Vector2(0.22895, 0.22895)`
- **Offset Y recomendado**: `Vector2(0.0, 38.3)`

---

## 3. Comparativo: Antes vs. Depois

| Aspecto | Versão Antiga (spritesheet mista) | Nova Versão Dedicada (`calango-spritesheet-pulando.png`) |
| :--- | :--- | :--- |
| **Origem** | `res://assets/spritesheet (2).png` | `res://assets/calango-spritesheet-pulando.png` |
| **Resolução do frame** | 340 x 330 px (recorte em atlas compartilhado) | 384 x 379 px (resolução superior, sem sangria de outros sprites) |
| **Escala** | Fixa genérica (0.245) | Calibrada para linha de chão (0.22895) |
| **Offset** | (0, 0) | (0, 38.3) compensando altura do solo |
| **Qualidade visual** | Textura comprimida em folha única | Textura nítida dedicada com proporção idêntica à corrida |

---

## 4. Código Pronto para Injeção

Ao aplicar esta animação no `player.gd`, este é o trecho gerado:

```gdscript
# No topo do script player.gd:
const JUMP_SCALE: Vector2 = Vector2(0.22895, 0.22895)
const JUMP_OFFSET: Vector2 = Vector2(0.0, 38.3)

# Dentro de _setup_animations():
var jump_sheet: Texture2D = load("res://assets/calango-spritesheet-pulando.png")
if not jump_sheet:
    push_error("Player: não foi possível carregar calango-spritesheet-pulando.png")
else:
    frames.add_animation("jump")
    frames.set_animation_speed("jump", 6.0)
    frames.set_animation_loop("jump", false)
    var jump_rects: Array[Rect2] = [
        Rect2(0, 0, 384, 379),
        Rect2(384, 0, 384, 379),
        Rect2(768, 0, 384, 379),
        Rect2(1152, 0, 384, 379)
    ]
    for r in jump_rects:
        var atlas := AtlasTexture.new()
        atlas.atlas = jump_sheet
        atlas.region = r
        atlas.filter_clip = true
        frames.add_frame("jump", atlas)

# Em _update_sprite_transform_for_anim():
elif sprite.animation == "jump":
    sprite.scale = JUMP_SCALE
    sprite.offset = JUMP_OFFSET
```
