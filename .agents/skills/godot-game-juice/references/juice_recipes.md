# Receitas de Game Juice (Polimento Visual) — Godot 4

Padrões de micro-animações e feedback visual para maximizar a satisfação do jogador.

---

## 1. Squash & Stretch no Salto e Aterrissagem

Dá peso e elasticidade orgânica ao calango.

```gdscript
# Ao saltar (alongar verticalmente):
func apply_jump_stretch(sprite: CanvasItem) -> void:
    var tw := create_tween()
    tw.tween_property(sprite, "scale", Vector2(0.85, 1.25), 0.08)
    tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

# Ao aterrissar (achatar contra o chão):
func apply_land_squash(sprite: CanvasItem) -> void:
    var tw := create_tween()
    tw.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.08)
    tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
```

---

## 2. Poeira de Corrida e Aterrissagem (`CPUParticles2D`)

```gdscript
# Configuração recomendada para partículas leves de poeira da caatinga:
var dust := CPUParticles2D.new()
dust.amount = 6
dust.lifetime = 0.35
dust.explosiveness = 0.2
dust.gravity = Vector2(-200.0, -50.0) # Sopra para trás do calango
dust.initial_velocity_min = 20.0
dust.initial_velocity_max = 50.0
dust.scale_amount_min = 2.0
dust.scale_amount_max = 4.0
dust.color = Color(0.85, 0.75, 0.55, 0.7) # Tom terra seca
```

---

## 3. Hit-Stop / Congelamento de Impacto (Micro Freeze)

Adiciona impacto visceral à morte do calango:

```gdscript
func trigger_hit_stop() -> void:
    Engine.time_scale = 0.05
    await get_tree().create_timer(0.08, true, false, true).timeout # Ignora time_scale
    Engine.time_scale = 1.0
```

---

## 4. Flash de Marco de Pontuação (Score Milestone)

Quando o jogador atinge múltiplos de 100 pontos:

```gdscript
func flash_score_milestone(label: Label) -> void:
    var tw := create_tween().set_loops(3)
    tw.tween_property(label, "modulate", Color.GOLD, 0.1)
    tw.tween_property(label, "modulate", Color.WHITE, 0.1)
```
