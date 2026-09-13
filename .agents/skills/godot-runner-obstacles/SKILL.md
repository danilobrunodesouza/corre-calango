---
name: godot-runner-obstacles
description: >-
  Specialist skill for creating and configuring hazards and obstacles (cacti, campfires, flying obstacles) in Godot 4 2D endless runners. Use whenever you need to introduce new dangerous entities with fair hitboxes, manage object pooling for obstacles, or adjust obstacle spawn parameters.
---

# Godot Runner Obstacles Specialist

Esta skill guia a criação, configuração de colisões seguras e pooling de obstáculos perigosos para o **Corre Calango**.

---

## 1. Princípios de Criação de Obstáculos

1. **Herança e Nós**:
   - Todo obstáculo deve ser uma `Area2D` com um `Sprite2D` e um `CollisionShape2D`.
   - Deve implementar métodos de ciclo de vida `on_spawn()` e `on_despawn()`.
2. **Hitbox Justa (85% Rule)**:
   - O colisor retangular deve cobrir apenas o miolo do obstáculo, deixando 15% de margem livre nas bordas visuais para evitar mortes frustrantes.
3. **Pooling Mandatório**:
   - Nunca instancie ou destrua obstáculos em runtime durante a corrida. Sempre use o `ObjectPool`.

Para detalhes aprofundados, consulte a [Arquitetura de Obstáculos](./references/obstacle_architecture.md).

---

## 2. Automação: Registrar Novo Obstáculo

A skill inclui o script de automação `scripts/add_obstacle.js`.

### Comandos:

```bash
# Listar obstáculos existentes
node .agents/skills/godot-runner-obstacles/scripts/add_obstacle.js --list

# Cadastrar novo obstáculo
node .agents/skills/godot-runner-obstacles/scripts/add_obstacle.js \
  --asset assets/cacto_novo.png \
  --id cacto_novo \
  --scale 0.35 \
  --weight 1.0

# Remover um obstáculo
node .agents/skills/godot-runner-obstacles/scripts/add_obstacle.js --remove cacto_novo
```

---

## 3. Passo a Passo para Novos Obstáculos

1. Coloque a imagem PNG em `assets/` (ex: `assets/tatu_bola.png`).
2. Execute o script `add_obstacle.js` passando a escala adequada.
3. Se o obstáculo exigir uma classe customizada no `obstacle_spawner.gd`, adicione o pool correspondente usando `ObjectPool.init_pool()`.
4. Valide a integridade do jogo com a suíte de testes:
   ```powershell
   & "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless scenes/main/main.tscn -- --test
   ```
