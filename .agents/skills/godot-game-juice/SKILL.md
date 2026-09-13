---
name: godot-game-juice
description: >-
  Specialist skill for enhancing game feel, tactile feedback, and visual polish in Godot 4 2D games. Use when implementing screen shake, squash & stretch animations on jumps/landings, CPUParticles2D dust effects, hit-stop impact freezes, or score milestone visual flashes.
---

# Godot Game Juice Specialist

Esta skill fornece receitas práticas, templates e técnicas comprovadas para transformar mecânicas básicas em uma experiência dinâmica, com impacto e satisfação imediata ao jogar.

---

## 1. O que é "Game Juice"?

Game Juice é o conjunto de respostas visuais e táteis imediatas a cada ação do jogador:
- **Salto com peso**: O calango estica ao subir e achata suavemente ao tocar o solo.
- **Poeira no chão**: Patas deixam pequenas nuvens de poeira seca.
- **Impacto no Game Over**: Uma fração de segundo de pausa dramática (*hit-stop*) seguida de leve tremor de tela (*screen shake*).
- **Conquista de Pontuação**: O placar pisca em dourado a cada 100 metros percorridos.

Para códigos completos e configurações de nós, consulte as [Receitas de Game Juice](./references/juice_recipes.md).

---

## 2. Templates Disponíveis

A skill fornece um helper pronto para câmera:
- [templates/screen_shake.gd](./templates/screen_shake.gd): Adicione este nó à cena principal ou à câmera para disparar `start_shake(intensity, decay)` em colisões ou eventos especiais.

---

## 3. Regras de Desempenho para Web/Mobile

1. **Nunca use GPUParticles2D**: Sempre use `CPUParticles2D` para compatibilidade total com navegadores e renderizador Compatibility.
2. **Tweens em vez de AnimationPlayers pesados**: Para micro-animações como *squash & stretch* ou piscadas de cor, `create_tween()` é muito mais performático e consome menos memória.
3. **Mantenha os efeitos sutis**: O objetivo do juice é realçar a jogabilidade, nunca obstruir a visão do próximo cacto.
