# Regras de Colisão e Hitbox / Hurtbox

Este documento define os padrões anatômicos para o sistema de colisão e dano do jogador no **Corre Calango**, assegurando que obstáculos (cactos, fogueiras) e o terreno interajam de forma justa e matematicamente estável.

---

## 1. Dois Sistemas de Colisão Independentes

O personagem possui duas formas de colisão distintas que **nunca devem ser misturadas**:

1. **`CollisionShape2D` (Física com o Cenário)**:
   - Pertence diretamente ao `CharacterBody2D`.
   - Colide exclusivamente com a camada do chão (`StaticBody2D` do terreno).
   - Impede que o personagem atravesse o solo.
   - Determina se `is_on_floor()` é verdadeiro.

2. **`HurtboxArea` (`Area2D` - Detecção de Dano)**:
   - Filho do `CharacterBody2D` com grupo `"player_hurtbox"`.
   - Monitora colisões contra as hitboxes dos obstáculos (`cacto`, `fogueira`).
   - Levemente mais permissiva (área ~15% menor) para evitar mortes frustrantes em raspões visuais.

---

## 2. Parâmetros Anatômicos

| Parâmetro | Em Pé (`Normal`) | Agachado (`Duck`) | Justificativa |
|---|---|---|---|
| **Altura da Cápsula Física** | `44.8 px` | `22.4 px` | Reduz pela metade para passar sob obstáculos altos. |
| **Raio da Cápsula Física** | `14.0 px` | `14.0 px` | Largura do corpo do Calango. |
| **Posição $Y$ do Centro Físico** | `0.0 px` | `+11.2 px` | Mantém a base da cápsula rigorosamente ancorada em $+22.4\text{ px}$. |
| **Base de Contato com o Chão** | `+22.4 px` | `+22.4 px` | **Idêntica em todos os estados.** |
| **Altura da Hurtbox (Dano)** | `38.08 px` ($85\%$) | `19.04 px` ($85\%$) | Evita colisões punitivas nas bordas do chapéu e cauda. |
| **Raio da Hurtbox** | `12.6 px` ($90\%$) | `12.6 px` | Margem de perdão (*coyote hitbox*). |
| **Posição $Y$ da Hurtbox** | `0.0 px` | `+11.2 px` | Acompanha a descida do corpo. |

---

## 3. Preservação do Solo no Agachamento (`Duck`)

Um erro comum em jogos 2D é alterar apenas a altura da cápsula sem reposicionar seu centro.
Como a cápsula do Godot se estende a partir do centro $(0, 0)$:
- Ao reduzir de $44.8$ para $22.4$, a base subiria de $+22.4$ para $+11.2$, fazendo o personagem flutuar acima do solo por um instante.

### Implementação Correta:

```gdscript
func duck_start() -> void:
    # 1. Ajusta colisão física
    if collision and collision.shape is CapsuleShape2D:
        var shape := collision.shape as CapsuleShape2D
        shape.height = DUCK_HEIGHT
        # Move o centro para baixo para que a base continue em +22.4
        collision.position.y = (NORMAL_HEIGHT - DUCK_HEIGHT) * 0.5

    # 2. Ajusta hurtbox
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
```

---

## 4. Diagnóstico e Visualização de Debug

Para validar o alinhamento em tempo de desenvolvimento:
- No Godot Editor: Ative **Debug > Visible Collision Shapes**.
- Em execução: As cápsulas azul e vermelha devem tocar perfeitamente a linha branca do solo sem descer nem subir ao agachar ou correr.
