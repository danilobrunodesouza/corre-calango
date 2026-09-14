# Arquitetura de Ancoragem Canônica no Solo (Ground Anchor)

Este documento detalha o modelo matemático e estrutural para garantir que o personagem principal (**Player / Calango**) mantenha contato visual e físico rigorosamente estável com o chão em todas as animações (corrida, salto, agachamento e novos movimentos).

---

## 1. O Problema das Origens Heterogêneas

No Godot 2D, o nó `CharacterBody2D` define a origem local `(0, 0)` do personagem no espaço do jogo.
A colisão física com o chão é definida pelo `CollisionShape2D`.

No projeto **Corre Calango**:
- O chão físico está em uma superfície plana horizontal.
- A colisão em pé do Calango usa uma cápsula de altura $H_{col} = 44.8$ e raio $R = 14.0$, centrada em $(0, 0)$.
- O ponto mais baixo da cápsula (onde toca o chão quando `is_on_floor() == true`) fica exatamente em:
  $$Y_{ground} = +\frac{H_{col}}{2} = +22.4\text{ px}$$

### Por que ocorrem "saltos" e "afundamentos"?
O nó `AnimatedSprite2D` usa por padrão `centered = true`. Isso significa que o Godot posiciona o **centro do retângulo recortado do frame** na posição `sprite.position`.

Quando diferentes animações vêm de spritesheets com alturas ou margens diferentes:
1. `calango-correndo.png`: recorte de $425\text{ px}$ de altura.
2. `calango-spritesheet-pulando.png`: recorte de $379\text{ px}$ de altura.
3. `spritesheet (2).png` (duck): recorte de $155\text{ px}$ de altura.

Se aplicarmos um deslocamento arbitrário ou fixo (como `position.y = 50.0` ou `0.0`), as patas do personagem terminam em alturas locais completamente diferentes, fazendo o Calango trepidar, flutuar ou afundar no chão ao trocar de estado.

---

## 2. A Fórmula da Ancoragem de Solo (Ground Anchor)

Para qualquer animação, queremos que a sola da pata desenhada no sprite coincida **exatamente** com a linha de contato do solo $Y_{ground} = +22.4\text{ px}$.

### Parâmetros de Entrada:
- $H$: Altura total do recorte do frame (em pixels da imagem).
- $Y_{foot}$: Posição $Y$ da sola da pata dentro do frame (em pixels, medida do topo $0$ até a base dos pixels visíveis de contato).
- $S_y$: Escala vertical do sprite (ex: $0.245$).
- $Y_{ground}$: Posição de solo da física ($+22.4$).

### Dedução:
1. Como o sprite é centrado (`centered = true`), o centro do frame fica em:
   $$Y_{center} = \frac{H}{2}$$
2. A distância da sola da pata em relação ao centro do frame (em pixels originais) é:
   $$\Delta Y_{frame} = Y_{foot} - \frac{H}{2}$$
3. Em coordenadas de mundo (aplicando a escala $S_y$):
   $$\Delta Y_{scaled} = \left(Y_{foot} - \frac{H}{2}\right) \times S_y$$
4. Para que a posição final da pata seja $Y_{ground}$, o nó `AnimatedSprite2D` deve ser posicionado em:
   $$SpriteY_{offset} = Y_{ground} - \Delta Y_{scaled} = Y_{ground} - \left(Y_{foot} - \frac{H}{2}\right) \times S_y$$

---

## 3. Calibração Prática das Animações Atuais

Utilizando a escala $S_y = 0.245$ e $Y_{ground} = +22.4$:

| Animação | Altura Frame ($H$) | Centro ($H/2$) | Linha da Pata ($Y_{foot}$) | $\Delta Y_{frame}$ | $\Delta Y_{scaled}$ | Offset $Y$ Calculado |
|---|---|---|---|---|---|---|
| **run** | $425\text{ px}$ | $212.5\text{ px}$ | $392\text{ px}$ | $+179.5\text{ px}$ | $+43.98\text{ px}$ | **$-21.58\text{ px}$** |
| **jump** (contato) | $379\text{ px}$ | $189.5\text{ px}$ | $348\text{ px}$ | $+158.5\text{ px}$ | $+38.83\text{ px}$ | **$-16.43\text{ px}$** |
| **duck** | $155\text{ px}$ | $77.5\text{ px}$ | $155\text{ px}$ | $+77.5\text{ px}$ | $+18.99\text{ px}$ | **$+3.41\text{ px}$** |

> [!IMPORTANT]
> Observe que com esta formulação matemática, o ponto de contato com o chão é **100% idêntico** em qualquer estado, sem discrepâncias, trepidações ou teletransportes verticais.

---

## 4. Estrutura de Implementação em GDScript

No script do Player, os offsets devem ser armazenados em um dicionário canônico e aplicados no sinal `animation_changed`:

```gdscript
const GROUND_Y_LOCAL: float = 22.4
const BASE_SCALE: Vector2 = Vector2(0.245, 0.245)

## Matriz de calibração de ancoragem de solo
const ANIMATION_OFFSETS: Dictionary = {
    "run": Vector2(0.0, -21.6),
    "jump": Vector2(0.0, -16.4),
    "duck": Vector2(0.0, 3.4)
}

func _on_animation_changed() -> void:
    _update_sprite_transform()

func _update_sprite_transform() -> void:
    if sprite == null:
        return
    var anim_name := sprite.animation
    if ANIMATION_OFFSETS.has(anim_name):
        sprite.position = ANIMATION_OFFSETS[anim_name]
    else:
        sprite.position = Vector2.ZERO
```
