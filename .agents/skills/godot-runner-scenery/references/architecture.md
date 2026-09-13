# Arquitetura de Cenários Não-Interativos em Endless Runners (Godot 4)

Este documento estabelece as diretrizes arquiteturais e padrões de engenharia para elementos cenográficos decorativos em jogos 2D endless runner.

---

## 1. Princípios Fundamentais

1. **Zero Colisão (No Colliders)**:
   - Elementos decorativos (árvores, arbustos, pedras no solo; nuvens e balões no céu) **nunca** devem possuir nós como `CollisionShape2D`, `Area2D` ou `StaticBody2D`.
   - São estritamente nós visuais (`Node2D` e `Sprite2D`), garantindo 0 overhead no motor de física e imunidade contra falsas colisões com o jogador.

2. **Hierarquia de Camadas e Z-Index**:
   - `z_index = -4`: Nuvens distantes (movimento lento, parallax baixo ~0.2x).
   - `z_index = -3`: Nuvens médias (movimento moderado ~0.35x).
   - `z_index = -2`: Elementos aéreos de primeiro plano, como balões com oscilação vertical suave (~0.3x a 0.5x).
   - `z_index = -1`: Elementos de solo (árvores, arbustos, pedras, grama) logo atrás do chão e dos obstáculos interativos (cactos/fogueira).
   - `z_index = 0`: Jogador, obstáculos e linha do chão.

3. **Reciclagem de Objetos (Object Pooling)**:
   - Em um runner infinito, instanciar (`instantiate()`) e descartar (`queue_free()`) nós repetidamente gera picos de Garbage Collector (GC spikes) e micro-engasgos (stutters) na taxa de quadros (FPS), especialmente no ambiente Web/Mobile.
   - O `SceneryManager` pré-aloca um pool de instâncias (`SceneryItem`). Conforme um item ultrapassa a margem esquerda da tela (`global_position.x < -200.0`), ele é recolocado na fila disponível ou imediatamente reposicionado à direita (`spawn_x + offset_aleatorio`), reaproveitando o mesmo nó.

---

## 2. Elementos de Solo vs Elementos Aéreos

### Solo (`Ground Elements`)
- **Velocidade**: Sincronizada 1:1 com a velocidade do chão (`GameManager.game_speed`).
- **Ancoragem Vertical**: Calculada a partir de `GROUND_Y` (460.0 px) com um `y_offset` negativo para que a base da imagem apoie no chão.
- **Variações Naturais**:
  - Inversão horizontal aleatória (`flip_h = randf() < 0.5`).
  - Variação sutil de escala (ex: escala base ± 10%).
  - Espaçamento randômico entre elementos sucessivos para evitar repetição geométrica mecânica.

### Ar (`Aerial Elements`)
- **Velocidade**: Fracionária em relação ao runner (`speed = GameManager.game_speed * speed_factor`), gerando profundidade e efeito parallax contínuo.
- **Faixa de Altitude**: Sorteadas entre `y_min` e `y_max` no céu (ex: 70 px a 220 px).
- **Oscilação Suave (Bobbing)**:
  - Balões de ar quente aplicam uma variação senoidal leve no eixo Y (`sin(time * bob_speed) * bob_amplitude`), conferindo leveza e sensação orgânica ao voo.

---

## 3. Fluxo de Execução no Ciclo de Jogo

```
[Início do Jogo / Ready]
       │
       ▼
SceneryManager carrega scenery_config.json
       │
       ▼
Pré-aloca pools (GroundPool e AerialPool)
       │
       ▼
[Durante o jogo (_process)]
  ├── Ground Elements: movem a (GameManager.game_speed * delta)
  │     └── Saiu à esquerda (x < -200) ──> Recicla para o final da fila à direita
  └── Aerial Elements: movem a (GameManager.game_speed * speed_factor * delta)
        └── Saiu à esquerda (x < -200) ──> Recicla com nova altitude e espaçamento
```
