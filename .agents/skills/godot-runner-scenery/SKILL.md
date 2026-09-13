---
name: godot-runner-scenery
description: >-
  Specialist skill for adding and managing non-interactive decorative scenery elements in Godot 4 2D endless runners (such as trees, bushes, rocks on the ground, or clouds and balloons in the air). Use whenever you need to enrich game visuals without player collisions, implement or tune endless recycling/pooling mechanics, or register new visual assets dynamically via automation scripts or GDScript APIs.
---

# Godot Runner Scenery Specialist

Esta skill guia a adição e gestão de elementos cenográficos decorativos para jogos 2D Endless Runner no Godot 4, garantindo enriquecimento visual dinâmico, taxa de quadros (FPS) estável com reciclagem contínua (pooling) e zero interferência na física do jogador.

---

## 1. Princípios Essenciais

1. **Zero Colisão**:
   - Elementos de cenário decorativo nunca recebem nós de colisão (`CollisionShape2D`, `Area2D`).
   - São estritamente nós de renderização (`Node2D` + `Sprite2D`), operando em camadas de fundo (`z_index` entre `-4` e `-1`).
2. **Ciclo de Vida do Runner**:
   - Elementos nascem à direita do viewport (`x > 960 + margin`).
   - Movem-se continuamente para a esquerda com base em `GameManager.game_speed` (100% para o solo; fracionário para efeito parallax no ar).
   - Ao saírem pela esquerda (`x < -200`), são **reciclados** para a fila à direita, evitando descarte e recriação de memória (GC Spikes).
3. **Dois Tipos de Elementos**:
   - **Solo (Ground)**: Árvores (`arvore`), arbustos (`arbusto`), pedras (`pedra`), tufos de grama (`grama`). Ancorados no chão (`GROUND_Y = 460.0`).
   - **Ar (Aerial)**: Nuvens (`nuvem`, `nuvem2`), balões (`balao`). Flutuam em faixas de altitude com velocidades de parallax e suporte a oscilação suave (bobbing).

Para aprofundamento na teoria arquitetural, consulte:
- [Arquitetura de Cenários](./references/architecture.md)
- [Tabela de Presets e Cálculos](./references/asset_presets.md)

---

## 2. Automação: Função para Adicionar Novos Assets de Cenário

A skill inclui um script de automação executável diretamente no projeto:
`scripts/add_decoration.js` (executado com Node.js).

### Sintaxe Básica

```bash
# Listar todos os elementos cadastrados
node .agents/skills/godot-runner-scenery/scripts/add_decoration.js --list

# Adicionar elemento de SOLO
node .agents/skills/godot-runner-scenery/scripts/add_decoration.js \
  --asset assets/nova_arvore.png \
  --type ground \
  --scale 0.32 \
  --y-offset -60.0

# Adicionar elemento AÉREO (com oscilação senoidal suave)
node .agents/skills/godot-runner-scenery/scripts/add_decoration.js \
  --asset assets/novo_balao.png \
  --type aerial \
  --scale 0.28 \
  --speed-factor 0.3 \
  --y-min 80.0 \
  --y-max 220.0 \
  --bobbing
```

### O que a função faz:
1. Analisa as dimensões originais da imagem PNG sem dependências externas.
2. Calcula a ancoragem de pivô ou faixa de altitude recomendada.
3. Registra a definição no arquivo `scenes/world/scenery_config.json`.
4. O `SceneryManager` recarrega ou instancia o elemento automaticamente nas próximas passagens.

---

## 3. Adição Dinâmica via GDScript (Runtime API)

Além do script CLI, novos elementos podem ser registrados programaticamente via GDScript em tempo de execução no `SceneryManager`:

```gdscript
# Exemplo: Adicionar um novo elemento de solo via código
SceneryManager.register_element("cacto_decorativo", {
    "texture": "res://assets/cacto_bonito.png",
    "scale": 0.30,
    "y_offset": -40.0,
    "z_index": -1,
    "weight": 1.0,
    "random_flip": true
})

# Exemplo: Adicionar um novo elemento aéreo via código
SceneryManager.register_element("passaro_decorativo", {
    "texture": "res://assets/passaro.png",
    "scale": 0.25,
    "speed_factor": 0.60,
    "y_min": 50.0,
    "y_max": 150.0,
    "z_index": -2,
    "weight": 0.8,
    "bobbing": true,
    "bob_speed": 3.0,
    "bob_amplitude": 8.0
})
```

---

## 4. Passo a Passo: Integrando uma Nova Decoração

Quando o usuário solicitar adicionar um novo elemento ao jogo:

1. **Localizar o Asset**: Certifique-se de que o arquivo de imagem está na pasta `assets/` (ex: `assets/minha_pedra.png`).
2. **Definir se é Solo ou Ar**:
   - Se for solo, descubra a altura da imagem e estime o `y_offset = -(altura * escala * 0.5)`.
   - Se for ar, escolha a faixa de altitude (`y_min` a `y_max`) e o fator de velocidade parallax (`0.2` a `0.5`).
3. **Executar a Função**:
   Execute `node .agents/skills/godot-runner-scenery/scripts/add_decoration.js --asset ...` com as opções adequadas.
4. **Verificar a Configuração**:
   Confira `scenes/world/scenery_config.json` para assegurar que os parâmetros foram gravados com precisão.
5. **Validar no Jogo**:
   Execute o jogo e verifique visualmente que o elemento surge à direita, viaja suavemente e é reciclado sem quedas de FPS.

---

## 5. Verificação e Testes

Para garantir que a integração do cenário está 100% correta:
- Execute a listagem: `node .agents/skills/godot-runner-scenery/scripts/add_decoration.js --list`
- Verifique que o Godot compila a cena sem erros de script:
  `& "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless --script scenes/main/main.gd`
