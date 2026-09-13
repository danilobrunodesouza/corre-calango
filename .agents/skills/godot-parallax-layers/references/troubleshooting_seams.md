# Resolução de Frestas (Seams) e Jitter em Parallax (Godot 4)

Guia prático para diagnosticar e eliminar problemas visuais clássicos em camadas de Parallax no Godot 4.

---

## 1. Problema 1: A Fresta Vertical de 1 Pixel (*Visible Seam*)

### Sintoma:
Uma linha vertical preta ou transparente pisca periodicamente entre as repetições do cenário espelhado.

### Causa Raiz:
O valor de `motion_mirroring.x` não é exatamente igual à largura total desenhada pelo sprite (geralmente decorrente de arredondamento de float ou escala decimal).

### Solução Definitiva:
Calcule sempre a largura com precisão matemática:
```gdscript
var rendered_width: float = texture.get_width() * sprite_scale.x
parallax_layer.motion_mirroring = Vector2(rendered_width, 0.0)
sprite.position = Vector2(rendered_width * 0.5, y_position)
```
*Dica de Ouro*: Use a ferramenta CLI `calculate_parallax.js` para obter os valores com precisão de float.

---

## 2. Problema 2: Tremulação em Alta Velocidade (*Floating Point Jitter*)

### Sintoma:
Conforme a corrida avança e a pontuação aumenta, as montanhas ou o chão começam a tremer ou dar pequenos "saltos" sutis.

### Causa Raiz:
`parallax.scroll_offset.x` acumula valores negativos gigantescos (`-50000.0`, `-100000.0`), perdendo precisão de mantissa no float de 32 bits.

### Solução:
Aplique um wrap com `fmod` ou reinicie periodicamente o offset quando ele ultrapassar o maior ciclo de repetição:
```gdscript
func _process(delta: float) -> void:
    var speed: float = GameManager.game_speed
    parallax.scroll_offset.x -= speed * delta
    
    # Previne overflow de float mantendo o offset dentro de um ciclo seguro
    if parallax.scroll_offset.x < -100000.0:
        parallax.scroll_offset.x = fmod(parallax.scroll_offset.x, 2688.0)
```

---

## 3. Problema 3: Repetição com Textura de Chão (`Texture2D` com Tile)

Para texturas horizontais contínuas como `assets/linha.png`:
- Ative o modo de repetição no CanvasItem ou use `region_enabled = true` com `region_rect.position.x = fmod(offset, largura)`.
- No Godot 4, defina o filtro de textura padrão como `Nearest` (`textures/canvas_textures/default_texture_filter=0`) em jogos com visual monocromático/pixel para evitar borramento de interpolação nas emendas.
