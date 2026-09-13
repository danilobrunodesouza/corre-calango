---
name: godot-runner-balancer
description: >-
  Specialist skill for calibrating speed progression, reaction windows, and spawn intervals in Godot 4 2D endless runners. Use whenever you need to adjust game speed curves, analyze obstacle spacing fairness, or prevent impossible jump traps using mathematical simulations.
---

# Godot Runner Balancer Specialist

Esta skill fornece as ferramentas e fórmulas para calibrar a progressão de dificuldade, garantir que o jogo seja desafiador sem ser injusto e simular tempos de reação em milissegundos.

---

## 1. Regras Fundamentais de Balanceamento

1. **Janela de Reação Mínima**: Garanta sempre $\ge 500\text{ms}$ desde o surgimento do obstáculo até o impacto.
2. **Prevenção de Traps Injustas**: O intervalo entre dois obstáculos sucessivos nunca deve ser menor que a distância de salto do calango + folga de aterrissagem.
3. **Escalonamento Suave**: A velocidade deve subir gradualmente a partir da pontuação (`GameManager.game_speed`), nunca em saltos bruscos que quebrem a inércia do jogador.

Consulte a [Modelagem Matemática e Curvas](./references/difficulty_curves.md) para fórmulas detalhadas.

---

## 2. Automação: Simulador de Balanceamento

A skill inclui um simulador executável via Node.js: `scripts/simulate_balance.js`.

### Execução:

```bash
node .agents/skills/godot-runner-balancer/scripts/simulate_balance.js
```

O script avaliará a tabela de velocidades (300 a 800 px/s), calculando:
- Tempo de reação da visão útil
- Distância horizontal percorrida no ar durante o pulo
- Alerta de "Risco de Trap" se os intervalos de spawn ficarem curtos demais.

---

## 3. Onde Ajustar os Parâmetros no Jogo

- **Velocidade Inicial e Máxima**: `autoloads/game_manager.gd` (`INITIAL_SPEED = 300.0`, `MAX_SPEED = 800.0`, `SPEED_ACCEL`).
- **Física do Pulo**: `scenes/player/player.gd` (`JUMP_VELOCITY = -750.0`, `GRAVITY = 2100.0`).
- **Intervalo de Spawn Adaptativo**: `scenes/obstacles/obstacle_spawner.gd` (`_schedule_next()`).
