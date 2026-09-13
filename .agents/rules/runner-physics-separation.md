# Regra de Separação de Física vs Cenário em Runners 2D

Esta regra estabelece os limites estritos entre elementos interativos (com colisão) e elementos decorativos (sem colisão) no **Corre Calango**.

---

## 1. Zero Colisão em Decorações (Strict Rule)

- Elementos decorativos (árvores, pedras, arbustos, tufos de grama, nuvens, balões, estrelas, sol e lua) **NUNCA** devem conter:
  - `CollisionShape2D`
  - `CollisionPolygon2D`
  - `Area2D`
  - `StaticBody2D`, `RigidBody2D` ou `CharacterBody2D`
- Devem ser estritamente nós visuais (`Node2D`, `Sprite2D`, `ColorRect`).
- Qualquer colisor encontrado em nós de cenário é considerado um **bug crítico**.

---

## 2. Apenas Obstáculos e Player Interagem

- O `Player` possui `CharacterBody2D` para movimento físico no chão e uma `Area2D` (Hitbox) para detecção de dano.
- Apenas nós do grupo `Obstacle` (cactos, fogueiras e perigos futuros) possuem `Area2D` que se conecta a `area_entered` para disparar colisão com o jogador.

---

## 3. Hitboxes Justas (Fair Collision Principle)

Em jogos no estilo runner de ritmo acelerado:
1. A caixa de colisão do obstáculo (`RectangleShape2D` ou `CircleShape2D`) deve ser **10% a 20% menor** que a arte visível do sprite.
2. É preferível que o jogador "passe de raspão" e sinta que escapou por pouco a ter uma morte injusta por colidir com pixels invisíveis ou a ponta externa de um espinho.
3. Desative a detecção (`monitoring = false`, `monitorable = false`) quando o obstáculo sair da tela ou for retornado ao pool.
