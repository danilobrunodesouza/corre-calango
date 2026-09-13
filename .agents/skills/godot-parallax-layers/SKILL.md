---
name: godot-parallax-layers
description: >-
  Specialist skill for configuring, calculating, and optimizing 2D Parallax backgrounds and layers in Godot 4. Use when setting up multi-layered depth, calculating seamless motion mirroring without gaps, managing camera vs manual scroll offsets, or integrating dynamic sky/celestial transitions.
---

# Godot Parallax Layers Specialist

Esta skill fornece o guia definitivo para planejar, calcular matematicamente e implementar camadas de Parallax 2D no Godot 4, garantindo profundidade tridimensional fluida, espelhamento perfeito sem frestas (*seams*) e alto desempenho para Web e Mobile.

---

## 1. Princípios Fundamentais do Parallax no Godot 4

1. **ParallaxBackground e ParallaxLayer**:
   - `ParallaxBackground`: Nó raiz que coordena todas as camadas e recebe o deslocamento geral (`scroll_offset`).
   - `ParallaxLayer`: Cada plano de profundidade individual.
2. **As Duas Propriedades Cruciais**:
   - `motion_scale`: Quão rápido a camada se move em relação ao mundo. Ex: `Vector2(0.1, 0.0)` para montanhas distantes (10% da velocidade) e `Vector2(1.0, 0.0)` para o plano do chão.
   - `motion_mirroring`: Tamanho exato em pixels no qual a imagem se repete perfeitamente. **Deve ser rigorosamente igual a $\text{Largura da Imagem} \times \text{Escala}$**.
3. **Scroll em Endless Runners**:
   - Com câmera fixa, o scroll é impulsionado no `_process(delta)` através de:
     ```gdscript
     parallax.scroll_offset.x -= GameManager.game_speed * delta
     ```

Para tabela de velocidades por camada, consulte o [Plano de Profundidade](./references/parallax_depth_chart.md).  
Para evitar frestas e linhas de 1px entre repetições, consulte a [Resolução de Costuras e Jitter](./references/troubleshooting_seams.md).

---

## 2. Automação: Calculadora de Parallax

A skill inclui um utilitário CLI para analisar qualquer arte PNG e gerar o código GDScript com o `motion_mirroring` exato:

```bash
node .agents/skills/godot-parallax-layers/scripts/calculate_parallax.js \
  --asset assets/montes.png \
  --scale 0.35 \
  --motion-scale 0.1 \
  --y-pos 360.0
```

### O que o script retorna:
- Dimensões nativas e renderizadas da imagem.
- Valor de `motion_mirroring = Vector2(W_render, 0.0)`.
- Posição central do sprite `Vector2(W_render * 0.5, y_pos)`.
- Snippet GDScript pronto para colar no `world.gd`.

---

## 3. Passo a Passo: Adicionando uma Nova Camada de Parallax

1. **Identificar o Asset**:
   Coloque a imagem na pasta `assets/` (ex: `assets/dunas_distantes.png`).
2. **Definir a Profundidade**:
   Escolha o `motion_scale` adequado:
   - Céu / Astro: `0.0`
   - Silhueta Distante: `0.08` a `0.15`
   - Colinas / Nuvens: `0.2` a `0.4`
3. **Calcular o Espelhamento**:
   Execute `node .agents/skills/godot-parallax-layers/scripts/calculate_parallax.js` com a escala desejada.
4. **Adicionar ao `_build_parallax()` no `world.gd`**:
   Insira o `ParallaxLayer` no nó `ParallaxBackground`, garantindo o `z_index` correto.
5. **Validar no Jogo**:
   Execute o jogo e certifique-se de que a textura repete infinitamente sem linhas pretas ou sobreposições.

---

## 4. Verificação e Testes

Para garantir a estabilidade do Parallax:
1. Execute o script de cálculo para conferir dimensões.
2. Execute a suíte de testes headless do Godot para validar sintaxe e inicialização:
   ```powershell
   & "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless scenes/main/main.tscn -- --test
   ```
