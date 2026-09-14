# Alinhamento, Pivôs e Transformações de Spritesheets do Player

Este documento detalha os fundamentos matemáticos e as regras de transformação visual necessárias para integrar spritesheets no personagem principal (`Player`) do **Corre Calango**, garantindo que as patas do Calango permaneçam sempre em contato firme com a linha do chão (`GROUND_Y = 460.0`), sem trepidações verticais (jittering), sem flutuar e sem afundar no solo.

---

## 1. Arquitetura de Coordenadas do Player

O `Player` é um `CharacterBody2D` cuja posição global `global_position` marca o **centro** de sua física no Godot:
- **`NORMAL_HEIGHT = 44.8`**: Altura da cápsula de colisão padrão (em pé / correndo).
- **`DUCK_HEIGHT = 22.4`**: Altura da cápsula de colisão agachada.
- **Linha do Solo**: O chão físico encontra-se na posição vertical onde a base inferior da cápsula toca a superfície (`y = 460.0`).
- A base da cápsula fica exatamente a `NORMAL_HEIGHT / 2 = 22.4 px` abaixo da origem local `(0, 0)` do nó `Player`.

---

## 2. O Problema da Troca de Spritesheet

Diferentes ilustrações e animações geradas (como `calango-correndo.png` com altura 425 px, `calango-spritesheet-pulando.png` com altura 379 px, ou a spritesheet mista antiga com 330 px) possuem:
1. **Alturas brutas distintas**: Se a mesma escala for usada para todas, o Calango mudará de tamanho abruptamente na transição.
2. **Espaçamentos transparentes superiores/inferiores desiguais**: Um frame pode ter 20px de ar abaixo das patas, enquanto outro tem 0px.
3. **Pivô central do AnimatedSprite2D**: Por padrão, o Godot centraliza as texturas `SpriteFrames` em torno de `(0, 0)`. Se um frame for menor em altura, a textura sobe em relação à base da cápsula física.

---

## 3. Fórmulas de Normalização

Para manter consistência visual absoluta:

### 3.1. Escala Normalizada
Tomamos a animação de corrida calibrada (`calango-correndo.png`) como referência áurea:
- Altura do frame de corrida: $H_{run} = 425.0 \text{ px}$
- Escala de corrida: $S_{run} = 0.20417$
- Altura visual no mundo: $H_{world} = H_{run} \times S_{run} \approx 86.77 \text{ px}$

Para qualquer nova animação com altura de frame $H_{novo}$:
$$S_{novo} = \frac{H_{world}}{H_{novo}} = \frac{425.0 \times 0.20417}{H_{novo}} = \frac{86.77225}{H_{novo}}$$

**Exemplo (Pulo - 379 px):**
$$S_{jump} = \frac{86.77225}{379.0} \approx 0.22895$$

### 3.2. Compensação de Offset Y
Para que a sola das patas continue alinhada à mesma linha de chão relativa à cápsula de colisão:
$$Offset_{Y} = Offset_{run} \times \left(\frac{S_{run}}{S_{novo}}\right)$$

No script do Calango:
- `RUN_OFFSET = Vector2(0.0, 43.0)`
- No caso do pulo ($S = 0.22895$):
  $$Offset_{jump\_Y} = 43.0 \times \left(\frac{0.20417}{0.22895}\right) \approx 38.3 \text{ px}$$

---

## 4. Implementação Dinâmica em `player.gd`

Toda vez que a animação é alternada (`sprite.animation_changed`), o Calango aplica as constantes de escala e offset adequadas:

```gdscript
func _on_animation_changed() -> void:
    _update_sprite_transform_for_anim()

func _update_sprite_transform_for_anim() -> void:
    if sprite == null:
        return
    match sprite.animation:
        "run":
            sprite.scale = RUN_SCALE
            sprite.offset = RUN_OFFSET
        "jump":
            sprite.scale = JUMP_SCALE
            sprite.offset = JUMP_OFFSET
        "duck":
            sprite.scale = DUCK_SCALE
            sprite.offset = DUCK_OFFSET
        _:
            sprite.scale = SPRITE_SCALE
            sprite.offset = Vector2.ZERO
```

---

## 5. Checklist de Verificação Visual

- [ ] Na troca entre `run` e `jump`, o Calango não encolhe nem estica instantaneamente.
- [ ] No pouso do pulo, as patas tocam exatamente a linha do chão sem "afundar" 1 frame antes de voltar a correr.
- [ ] As caixas de colisão `CollisionShape2D` e `HurtboxArea` cobrem confortavelmente o corpo do Calango.
