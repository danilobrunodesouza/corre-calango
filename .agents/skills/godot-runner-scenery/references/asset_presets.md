# Presets Recomendados para Assets de Cenário — Corre Calango

Tabela de calibração para os assets disponíveis no projeto.

---

## 1. Elementos de Solo (Ground)

O chão do jogo fica posicionado em `GROUND_Y = 460.0`.

| Asset | Resolução Nativa | Escala Recomendada | Y-Offset Recomendado | Flip Aleatório | Descrição |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `assets/arvore.png` | 256×384 px | `0.32` | `-60.0 px` | Sim | Árvore da caatinga / mandacaru seco |
| `assets/arbusto.png` | 384×256 px | `0.28` | `-36.0 px` | Sim | Arbusto rasteiro |
| `assets/pedra.png` | 96×96 px | `0.35` | `-17.0 px` | Sim | Pedra decorativa (sem colisão) |
| `assets/grama.png` | 128×192 px | `0.24` | `-23.0 px` | Sim | Tufo de vegetação seca |

---

## 2. Elementos Aéreos (Aerial)

A área do céu útil no viewport (960×540) fica entre `Y = 60.0` e `Y = 260.0`.

| Asset | Resolução Nativa | Escala | Speed Factor | Faixa Y | Bobbing | Descrição |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `assets/nuvem.png` | 384×192 px | `0.35` | `0.35` | `[120.0 .. 180.0]` | Não | Nuvem média com deslocamento moderado |
| `assets/nuvem2.png` | 512×256 px | `0.35` | `0.22` | `[70.0 .. 130.0]` | Não | Nuvem grande ao fundo com movimento lento |
| `assets/balao.png` | 128×192 px | `0.26` | `0.28` | `[90.0 .. 230.0]` | Sim (`amp: 12, spd: 1.5`) | Balão de São João / ar quente decorativo |

---

## 3. Como Calcular Parâmetros para Novos Assets

Ao criar uma nova arte de imagem para o jogo:
1. **Identifique a categoria**: Se encosta no chão, é `ground`. Se flutua no céu, é `aerial`.
2. **Defina a escala**: Ajuste para que a altura aparente na tela fique proporcional ao calango (~60 a 90px de altura visual).
3. **Calcule o Y-Offset (para solo)**:
   - Se o sprite tem o ponto de pivô (`offset`) no centro da imagem (padrão do `Sprite2D`), o centro deve ficar a uma distância correspondente a metade da altura renderizada acima do chão.
   - `y_offset = -(altura_original * escala * 0.5)`
4. **Defina a velocidade (para aéreo)**:
   - Fatores entre `0.1` e `0.2` dão sensação de horizonte distante.
   - Fatores entre `0.3` e `0.6` parecem voar no mesmo plano de profundidade das nuvens médias e balões.
