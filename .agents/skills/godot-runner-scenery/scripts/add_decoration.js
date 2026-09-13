#!/usr/bin/env node
/**
 * add_decoration.js — Script de automação para registrar novos assets de cenário no Corre Calango.
 * 
 * Uso:
 *   node add_decoration.js --list
 *   node add_decoration.js --asset assets/pedra.png --type ground --scale 0.35 --y-offset -17
 *   node add_decoration.js --asset assets/balao.png --type aerial --scale 0.28 --speed-factor 0.3 --bobbing
 */

const fs = require('fs');
const path = require('path');

// Resolve o caminho para o arquivo scenery_config.json
const PROJECT_ROOT = path.resolve(__dirname, '../../../../');
const CONFIG_PATH = path.join(PROJECT_ROOT, 'scenes', 'world', 'scenery_config.json');

// Função utilitária para ler dimensões de PNG puro sem pacotes externos
function getPngDimensions(filePath) {
  try {
    const buffer = fs.readFileSync(filePath);
    // Assinatura PNG: 89 50 4E 47 0D 0A 1A 0A
    if (buffer.length > 24 && buffer.toString('ascii', 1, 4) === 'PNG') {
      const width = buffer.readUInt32BE(16);
      const height = buffer.readUInt32BE(20);
      return { width, height };
    }
  } catch (err) {
    // Silencioso se não for possível ler arquivo
  }
  return null;
}

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--list') {
      options.list = true;
    } else if (arg === '--bobbing') {
      options.bobbing = true;
    } else if (arg === '--no-flip') {
      options.randomFlip = false;
    } else if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const val = args[++i];
      options[key] = val;
    }
  }
  return options;
}

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    return { ground_elements: {}, aerial_elements: {} };
  }
  try {
    const content = fs.readFileSync(CONFIG_PATH, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    console.error('Erro ao ler scenery_config.json:', err.message);
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
    console.log('\n=== ELEMENTOS DE CENÁRIO REGISTRADOS ===\n');
    console.log('--- SOLO (Ground Elements) ---');
    for (const [id, data] of Object.entries(config.ground_elements || {})) {
      console.log(`• [${id}] -> texture: ${data.texture} | scale: ${data.scale} | y_offset: ${data.y_offset} | weight: ${data.weight}`);
    }
    console.log('\n--- AR (Aerial Elements) ---');
    for (const [id, data] of Object.entries(config.aerial_elements || {})) {
      console.log(`• [${id}] -> texture: ${data.texture} | scale: ${data.scale} | speed_factor: ${data.speed_factor} | y: [${data.y_min}..${data.y_max}] | bobbing: ${!!data.bobbing}`);
    }
    console.log('\n=========================================\n');
    return;
  }

  if (options.remove) {
    const targetId = options.remove;
    let found = false;
    if (config.ground_elements && config.ground_elements[targetId]) {
      delete config.ground_elements[targetId];
      found = true;
    }
    if (config.aerial_elements && config.aerial_elements[targetId]) {
      delete config.aerial_elements[targetId];
      found = true;
    }
    if (found) {
      saveConfig(config);
      console.log(`✓ Elemento [${targetId}] removido com sucesso.`);
    } else {
      console.log(`Elemento [${targetId}] não encontrado.`);
    }
    return;
  }

  if (!options.asset) {
    console.log(`
Uso do add_decoration:
  node add_decoration.js --asset <caminho> --type <ground|aerial> [opções]

Opções:
  --list                     Lista todos os elementos cadastrados
  --asset <arquivo>          Caminho relativo do asset (ex: assets/minha_arvore.png)
  --type <ground|aerial>     Tipo do elemento (solo ou aéreo)
  --id <identificador>       ID único (padrão: nome do arquivo sem extensão)
  --scale <valor>            Escala uniforme do sprite (ex: 0.32)
  --weight <valor>           Peso relativo de spawn (padrão: 1.0)
  --no-flip                  Desativa o flip horizontal aleatório

Opções para Solo:
  --y-offset <valor>         Deslocamento vertical em relação a GROUND_Y (460.0)

Opções para Ar:
  --speed-factor <valor>     Fator de velocidade relativo ao runner (ex: 0.3)
  --y-min <valor>            Altitude mínima em Y (ex: 80.0)
  --y-max <valor>            Altitude máxima em Y (ex: 200.0)
  --bobbing                  Ativa oscilação senoidal suave (ideal para balões)
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
  const type = (options.type || 'ground').toLowerCase();
  const godotResPath = `res://${assetRel.startsWith('assets/') ? assetRel : 'assets/' + path.basename(assetRel)}`;

  const dimensions = getPngDimensions(fullAssetPath);
  if (dimensions) {
    console.log(`Detectada imagem PNG: ${dimensions.width}x${dimensions.height} px`);
  }

  const scale = options.scale ? parseFloat(options.scale) : 0.30;
  const weight = options.weight ? parseFloat(options.weight) : 1.0;
  const randomFlip = options.randomFlip !== false;

  if (type === 'ground') {
    if (!config.ground_elements) config.ground_elements = {};

    // Sugestão de y_offset baseado na altura se não especificado
    let yOffset = -20.0;
    if (options['y-offset']) {
      yOffset = parseFloat(options['y-offset']);
    } else if (dimensions) {
      // Metade da altura renderizada para ancorar no chão
      const renderedHeight = dimensions.height * scale;
      yOffset = -Math.round(renderedHeight * 0.5);
    }

    config.ground_elements[id] = {
      texture: godotResPath,
      scale: scale,
      y_offset: yOffset,
      z_index: -1,
      weight: weight,
      random_flip: randomFlip
    };

    console.log(`\n✓ Registrado elemento de SOLO [${id}]:`);
    console.log(`  - Textura: ${godotResPath}`);
    console.log(`  - Escala: ${scale}`);
    console.log(`  - Y Offset: ${yOffset}px`);
    console.log(`  - Peso: ${weight}`);
  } else if (type === 'aerial') {
    if (!config.aerial_elements) config.aerial_elements = {};

    const speedFactor = options['speed-factor'] ? parseFloat(options['speed-factor']) : 0.30;
    const yMin = options['y-min'] ? parseFloat(options['y-min']) : 80.0;
    const yMax = options['y-max'] ? parseFloat(options['y-max']) : 200.0;
    const bobbing = !!options.bobbing;

    config.aerial_elements[id] = {
      texture: godotResPath,
      scale: scale,
      speed_factor: speedFactor,
      y_min: yMin,
      y_max: yMax,
      z_index: bobbing ? -2 : -3,
      weight: weight,
      bobbing: bobbing,
      random_flip: randomFlip
    };

    if (bobbing) {
      config.aerial_elements[id].bob_speed = 1.5;
      config.aerial_elements[id].bob_amplitude = 12.0;
    }

    console.log(`\n✓ Registrado elemento AÉREO [${id}]:`);
    console.log(`  - Textura: ${godotResPath}`);
    console.log(`  - Escala: ${scale}`);
    console.log(`  - Speed Factor: ${speedFactor}`);
    console.log(`  - Faixa Y: [${yMin}..${yMax}]`);
    console.log(`  - Bobbing: ${bobbing}`);
  } else {
    console.error(`Tipo desconhecido: "${type}". Use "ground" ou "aerial".`);
    process.exit(1);
  }

  saveConfig(config);
}

main();
