# Arquitetura de Obstáculos — Corre Calango

Documento técnico sobre como os obstáculos operam no runner, detecção de colisões e integração com pools.

---

## 1. Ciclo de Vida do Obstáculo

1. **Pooling Obrigatório**:
   - Todo obstáculo deriva de `Obstacle` (`Area2D`).
   - O `ObstacleSpawner` mantém pools independentes (`ObjectPool`) para cada variação.
   - Quando um obstáculo sai pela esquerda (`x < -100`), ele emite `returned_to_pool` e é desativado via `process_mode = PROCESS_MODE_DISABLED` e `set_deferred("monitoring", false)`.

2. **Detecção de Colisão com o Calango**:
   - `Obstacle` escuta `area_entered`.
   - Se colidir com o Player (ou com sua Hurtbox), emite `EventBus.player_hit.emit()` ou chama `GameManager.trigger_game_over()`.

3. **Hitboxes Justas (Anti-Frustração)**:
   - Para garantir jogabilidade satisfatória, os colisores retangulares devem ter no máximo **85%** da dimensão do sprite.
   - Isso permite ao jogador passar tangenciando os espinhos do cacto sem ser punido injustamente.

---

## 2. Obstáculos Animados (Ex: Fogueira)

Para obstáculos com animação de múltiplos frames:
- Armazene as texturas em um `Array[Texture2D]`.
- No `_process(delta)`, avance o timer `_anim_timer += delta`.
- Quando `_anim_timer >= ANIM_FRAME_TIME`, atualize `sprite.texture = textures[frame]` ciclicamente.
