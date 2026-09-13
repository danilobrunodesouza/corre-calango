# Tabela de Planos de Profundidade e Velocidades (Parallax Depth Chart)

Guia de calibração de `motion_scale` e `z_index` para jogos 2D no estilo Endless Runner.

---

## 1. Tabela de Camadas Padrão

| Camada | Tipo / Elemento | `motion_scale.x` | `z_index` | Comportamento | Exemplo no Corre Calango |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0. Fundo Infinito** | Cor base / Céu estático | `0.0` | `-10` | Sem movimento | `ColorRect` preto (dia/noite via shader) |
| **1. Astro Celeste** | Sol / Lua | `0.0` | `-9` | Movimento via Tween de dia/noite | `sol.png`, `lua.png` |
| **2. Céu Profundo** | Estrelas distantes | `0.02` a `0.05` | `-8` | Quase estático, visível à noite | `estrela1..5.png` |
| **3. Silhueta Distante** | Montes / Cordilheiras | `0.08` a `0.15` | `-7` | Movimento muito lento | `montes.png` (escala 0.35) |
| **4. Nuvens Altas** | Nuvens grandes / cirros | `0.20` a `0.25` | `-6` | Movimento lento no horizonte | `nuvem2.png` |
| **5. Nuvens Baixas / Ar** | Nuvens médias / Balões | `0.30` a `0.45` | `-5` | Movimento moderado | `nuvem.png`, `balao.png` (bobbing) |
| **6. Cenário Rasteiro** | Árvores distantes / Dunes | `0.50` a `0.70` | `-3` | Meio-termo entre montes e chão | Árvores ao fundo |
| **7. Cenário Imediato** | Arbustos / Pedras decorativas | `1.0` | `-1` | Sincronizado com o chão | `arvore.png`, `arbusto.png`, `pedra.png` |
| **8. Chão e Jogador** | Linha do chão, Cactos, Calango | `1.0` | `0` | Plano principal de colisão e jogo | `linha.png`, `cacto1.png`, Calango |
| **9. Primeiro Plano** | Folhas caindo / Vinheta frontal | `1.2` a `1.4` | `+1` | Passa na frente do jogador (profundidade) | Galhos ou poeira de primeiro plano |

---

## 2. Princípio da Progressão de Profundidade

$$\text{Velocidade Aparente} = \text{Game Speed} \times \text{motion\_scale.x}$$

- Quanto mais distante o objeto se encontra na linha de visão do jogador (horizonte infinito), mais próximo de `0.0` deve ser o seu `motion_scale.x`.
- Elementos com `motion_scale.x = 1.0` movem-se exatamente na velocidade física do jogador e dos obstáculos.
- Elementos com `motion_scale.x > 1.0` criam a ilusão de estarem mais próximos da câmera do que o próprio jogador (primeiro plano cinematográfico).
