# Regra de Restrições Técnicas: Web e Mobile (Godot 4)

O **Corre Calango** é projetado especificamente para rodar em navegadores desktop e celulares (HTML5/WebAssembly). Esta regra estabelece diretrizes para evitar travamentos, picos de Garbage Collector e incompatibilidades com WebGL.

---

## 1. Zero Alocações em Loops por Frame (`_process` / `_physics_process`)

- É expressamente proibido chamar `.new()` ou `.instantiate()` dentro de `_process` ou `_physics_process`.
- Todas as instâncias dinâmicas frequentes (obstáculos, itens de cenário, projéteis, partículas temporárias) **devem ser pré-alocadas em `ObjectPool`** ou recicladas ao sair da tela (`x < -220`).
- Chamar `queue_free()` repetidamente durante a corrida causa congelamentos momentâneos (stutter) perceptíveis em smartphones.

---

## 2. Compatibilidade de Renderização (Mobile / Compatibility)

- O projeto utiliza o renderizador `gl_compatibility` (WebGL 2.0 na web).
- **Partículas**: Use sempre `CPUParticles2D` em vez de `GPUParticles2D`. `GPUParticles2D` causa falhas ou incompatibilidade em dispositivos móveis antigos e certos navegadores.
- **Resolução e Viewport**:
  - Resolução base: `960x540`
  - Stretch Mode: `canvas_items`
  - Aspect: `expand`
  - Todos os elementos de UI devem usar âncoras relativas do `Control` para se adaptarem a telas 16:9, 18:9 ou 20:9.

---

## 3. Políticas de Áudio na Web (Autoplay Policy)

- Navegadores modernos bloqueiam qualquer reprodução de áudio iniciada antes da primeira ação do usuário (clique ou toque na tela).
- Ao implementar áudio, certifique-se de que a primeira música ou som só toque a partir do evento `gui_input` ou no botão de iniciar do `StartScreen`.
