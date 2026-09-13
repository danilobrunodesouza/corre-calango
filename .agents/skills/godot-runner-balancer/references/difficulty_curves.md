# Curvas de Dificuldade e Modelagem Matemática — Corre Calango

Diretrizes para calibrar a velocidade do jogo e o espaçamento de perigos.

---

## 1. Ergonomia do Tempo de Reação

Estudos de psicologia de jogos e reflexo humano estabelecem:
- **Tempo de reação visual puro**: ~200ms a 250ms.
- **Latência de input móvel/web (touch/60Hz)**: ~80ms a 150ms.
- **Janela mínima humana segura**: **450ms a 500ms**.

No **Corre Calango**:
$$\text{Tempo de Reação} = \frac{\text{Spawn X} - \text{Player X}}{\text{Velocidade Atual}}$$
Para `SPAWN_X = 1050`, `PLAYER_X = 120` ($\Delta X = 930\text{ px}$):
- A 300 px/s: $930 / 300 = \mathbf{3.10\text{ s}}$ (Início acolhedor para novos jogadores).
- A 500 px/s: $930 / 500 = \mathbf{1.86\text{ s}}$ (Ritmo confortável).
- A 800 px/s (Velocidade Máxima): $930 / 800 = \mathbf{1.16\text{ s}}$ (Desafiador, porém 100% justo).

---

## 2. A "Regra do Arco de Salto"

O calango salta com:
$$v_0 = -750\text{ px/s},\quad g = 2100\text{ px/s}^2 \implies t_{\text{ar}} = \frac{2 \cdot 750}{2100} \approx 0.714\text{ s}$$

A distância percorrida pelo solo durante o salto é:
$$D_{\text{salto}} = \text{Velocidade} \times 0.714\text{ s}$$
- A 300 px/s: $214\text{ px}$.
- A 800 px/s: $571\text{ px}$.

**Regra Inegociável**:
O intervalo mínimo entre o obstáculo $A$ e o obstáculo $B$ **nunca pode ser menor que o tempo de aterrissagem + 150ms de recuperação**. Caso contrário, o jogador aterrissa diretamente sobre o segundo obstáculo sem chance de resposta.
