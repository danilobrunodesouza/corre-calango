#!/usr/bin/env node
/**
 * add_obstacle.js — Script de automação para registrar novos obstáculos no Corre Calango.
 * 
 * Uso:
 *   node add_obstacle.js --list
 *   node add_obstacle.js --asset assets/novo_cacto.png --id cacto_novo --scale 0.35 --weight 1.0
 *   node add_obstacle.js --remove cacto_novo
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '../../../../');
const CONFIG_PATH = path.join(PROJECT_ROOT, 'scenes', 'obstacles', 'obstacle_config.json');

function getPngDimensions(filePath) {
  try {
    const buffer = fs.readFileSync(filePath);
    if (buffer.length > 24 && buffer.toString('ascii', 1, 4) === 'PNG') {
      const width = buffer.readUInt32BE(16);
      const height = buffer.readUInt32BE(20);
      return { width, height };
    }
  } catch (err) {}
  return null;
}

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {};
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--list') {
      options.list = true;
    } else if (arg.startsWith('--')) {
      const key = arg.slice(2);
      options[key] = args[++i];
    }
  }
  return options;
}

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) return { obstacles: {} };
  try {
    return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  } catch (e) {
    console.error('Erro ao ler obstacle_config.json:', e.message);
    process.exit(1);
  }
}

function saveConfig(config) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2), 'utf8');
  console.log(`✓ Configuração salva com sucesso em: ${CONFIG_PATH}`);
}

function main() {
  const options = parseArgs();
  const config = loadConfig();

  if (options.list) {
    console.log('\n=== OBSTÁCULOS REGISTRADOS ===\n');
    for (const [id, data] of Object.entries(config.obstacles || {})) {
      console.log(`• [${id}] -> texture: ${data.texture || data.textures} | scale: ${data.scale} | colisor: ${data.collider_size[0]}x${data.collider_size[1]} | peso: ${data.weight}`);
    }
    console.log('\n==============================\n');
    return;
  }

  if (options.remove) {
    const targetId = options.remove;
    if (config.obstacles && config.obstacles[targetId]) {
      delete config.obstacles[targetId];
      saveConfig(config);
      console.log(`✓ Obstáculo [${targetId}] removido.`);
    } else {
      console.log(`Obstáculo [${targetId}] não encontrado.`);
    }
    return;
  }

  if (!options.asset) {
    console.log(`
Uso do add_obstacle:
  node add_obstacle.js --asset <arquivo> [opções]

Opções:
  --list                     Lista os obstáculos cadastrados
  --remove <id>              Remove um obstáculo
  --asset <arquivo>          Caminho do asset (ex: assets/cacto_novo.png)
  --id <nome>                Identificador único
  --scale <valor>            Escala uniforme (padrão: 0.35)
  --collider-w <largura>     Largura do colisor (padrão: 85% do sprite)
  --collider-h <altura>      Altura do colisor (padrão: 85% do sprite)
  --ground-y <altura>        Posição Y de chão (padrão: 404.0)
  --weight <peso>            Frequência de spawn (padrão: 1.0)
`);
    process.exit(0);
  }

  const assetRel = options.asset.replace(/\\/g, '/');
  const fullAssetPath = path.isAbsolute(assetRel) ? assetRel : path.join(PROJECT_ROOT, assetRel);

  if (!fs.existsSync(fullAssetPath)) {
    console.error(`Erro: Arquivo não encontrado: ${fullAssetPath}`);
    process.exit(1);
  }

  const baseName = path.basename(assetRel, path.extname(assetRel));
  const id = options.id || baseName;
  const scale = options.scale ? parseFloat(options.scale) : 0.35;
  const weight = options.weight ? parseFloat(options.weight) : 1.0;
  const groundY = options['ground-y'] ? parseFloat(options['ground-y']) : 404.0;
  const godotResPath = `res://${assetRel.startsWith('assets/') ? assetRel : 'assets/' + path.basename(assetRel)}`;

  const dims = getPngDimensions(fullAssetPath) || { width: 150, height: 260 };
  const renderedW = dims.width * scale;
  const renderedH = dims.height * scale;

  // Hitbox justa: 85% da largura e altura visíveis para evitar mortes injustas
  const colW = options['collider-w'] ? parseFloat(options['collider-w']) : Math.round(renderedW * 0.85);
  const colH = options['collider-h'] ? parseFloat(options['collider-h']) : Math.round(renderedH * 0.85);

  if (!config.obstacles) config.obstacles = {};
  config.obstacles[id] = {
    texture: godotResPath,
    scale: scale,
    collider_size: [colW, colH],
    collider_offset: [0.0, 0.0],
    ground_y: groundY,
    weight: weight,
    is_animated: false
  };

  console.log(`\n✓ Registrado novo obstáculo [${id}]:`);
  console.log(`  - Textura: ${godotResPath} (${dims.width}x${dims.height} px)`);
  console.log(`  - Escala: ${scale}`);
  console.log(`  - Colisor justo (85%): ${colW}x${colH} px`);
  console.log(`  - Posição Y no chão: ${groundY}`);
  console.log(`  - Peso de spawn: ${weight}`);

  saveConfig(config);
}

main();
