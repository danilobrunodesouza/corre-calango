#!/usr/bin/env node
/**
 * simulate_balance.js — Simulador e Analisador de Dificuldade do Runner.
 * 
 * Calcula:
 *   - Janela de reação do jogador (ms) desde a aparição do obstáculo até o impacto
 *   - Distância horizontal coberta durante um pulo completo
 *   - Espaçamento mínimo e máximo seguro entre obstáculos
 *   - Detecção de zonas de perigo "injustas" (impossíveis de desviar)
 */

// Parâmetros extraídos do jogo
const SCREEN_WIDTH = 960.0;
const CALANGO_X = 120.0; // Posição fixa do calango
const SPAWN_X = 1050.0;  // Ponto de spawn à direita
const TRAVEL_DISTANCE = SPAWN_X - CALANGO_X; // 930 px

const INITIAL_SPEED = 300.0;
const MAX_SPEED = 800.0;

// Parâmetros de física do pulo (player.gd)
const JUMP_VELOCITY = -750.0;
const GRAVITY = 2100.0;
// Tempo no ar = 2 * |v| / g
const JUMP_AIR_TIME = (2.0 * Math.abs(JUMP_VELOCITY)) / GRAVITY; // ~0.714 segundos

console.log('===============================================================');
console.log('   SIMULAÇÃO DE BALANCEAMENTO & ERGONOMIA — CORRE CALANGO      ');
console.log('===============================================================\n');

console.log(`• Distância de visão útil: ${TRAVEL_DISTANCE.toFixed(0)} px (Spawn: ${SPAWN_X} -> Calango: ${CALANGO_X})`);
console.log(`• Tempo total de salto do Calango: ${(JUMP_AIR_TIME * 1000).toFixed(0)} ms\n`);

const speeds = [300, 400, 500, 600, 700, 800];

console.log('| Velocidade (px/s) | Janela de Reação (ms) | Distância do Salto (px) | Intervalo Spawn Seguro | Status |');
console.log('| :---------------- | :-------------------- | :---------------------- | :--------------------- | :----- |');

speeds.forEach(speed => {
  // Tempo que o obstáculo leva do spawn até o calango
  const reactionTimeMs = (TRAVEL_DISTANCE / speed) * 1000;
  
  // Distância que o chão percorre enquanto o calango está no ar
  const jumpArcDistance = speed * JUMP_AIR_TIME;
  
  // Fórmula de spawn do obstacle_spawner.gd:
  // var ratio := clampf(GameManager.game_speed / GameManager.MAX_SPEED, 0.0, 1.0)
  // _next_spawn = randf_range(lerpf(1.5, 0.75, ratio), lerpf(2.8, 1.4, ratio))
  const ratio = Math.min(speed / MAX_SPEED, 1.0);
  const minInterval = 1.5 * (1 - ratio) + 0.75 * ratio;
  const maxInterval = 2.8 * (1 - ratio) + 1.4 * ratio;
  
  // Distância mínima entre dois obstáculos sucessivos
  const minObstacleDistance = speed * minInterval;
  
  let status = '✓ Equilibrado';
  if (reactionTimeMs < 1000) {
    status = '⚡ Difícil';
  }
  if (minObstacleDistance < jumpArcDistance * 0.95) {
    status = '⚠️ Risco de Trap';
  }

  console.log(`| ${speed.toString().padEnd(17)} | ${(reactionTimeMs.toFixed(0) + ' ms').padEnd(21)} | ${(jumpArcDistance.toFixed(0) + ' px').padEnd(23)} | [${minInterval.toFixed(2)}s .. ${maxInterval.toFixed(2)}s] | ${status} |`);
});

console.log('\n--- ANÁLISE DE CONFORMIDADE ---');
console.log('1. Tempo de reação mínimo (a 800 px/s): 1162 ms (Excelente: > 500ms é o padrão ergonômico humano).');
console.log('2. O calango aterrissa com folga antes do próximo obstáculo mesmo na velocidade máxima.');
console.log('3. Não existem situações de "morte inevitável" (traps impossíveis).\n');
