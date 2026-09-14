#!/usr/bin/env node
/**
 * manage_player_spritesheet.js
 * 
 * Utilitário de automação para fatiar, calcular proporções/offsets
 * e gerar código GDScript para spritesheets do personagem principal (Player)
 * no jogo Corre Calango (Godot 4).
 * 
 * Uso:
 *   node manage_player_spritesheet.js --inspect assets/calango-spritesheet-pulando.png
 *   node manage_player_spritesheet.js --inspect assets/calango-spritesheet-pulando.png --cols 4 --anim jump --fps 6.0 --loop false --generate-gdscript
 */

const fs = require('fs');
const path = require('path');

// Constantes de referência da física e do Calango no jogo
const REF_NORMAL_HEIGHT = 44.8;
const REF_RUN_SCALE = 0.20417;
const REF_RUN_FRAME_HEIGHT = 425.0; // calango-correndo.png altura
const REF_RUN_OFFSET_Y = 43.0;

function getPngDimensions(filePath) {
  try {
    const buffer = fs.readFileSync(filePath);
    if (buffer.length > 24 && buffer.toString('ascii', 1, 4) === 'PNG') {
      const width = buffer.readUInt32BE(16);
      const height = buffer.readUInt32BE(20);
      return { width, height };
    }
  } catch (err) {
    console.error(`Erro ao ler arquivo PNG em ${filePath}:`, err.message);
  }
  return null;
}

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    cols: 0,
    rows: 1,
    fps: 6.0,
    loop: false,
    anim: 'custom_anim',
    marginLeft: 0,
    marginTop: 0,
    marginRight: 0,
    marginBottom: 0,
    spacingX: 0,
    spacingY: 0,
    generateGdscript: false,
    json: false,
    help: false
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--inspect' || arg === '-i') {
      options.asset = args[++i];
    } else if (arg === '--cols' || arg === '-c') {
      options.cols = parseInt(args[++i], 10);
    } else if (arg === '--rows' || arg === '-r') {
      options.rows = parseInt(args[++i], 10);
    } else if (arg === '--fps') {
      options.fps = parseFloat(args[++i]);
    } else if (arg === '--loop') {
      options.loop = args[++i].toLowerCase() === 'true';
    } else if (arg === '--anim') {
      options.anim = args[++i];
    } else if (arg === '--margin-left') {
      options.marginLeft = parseInt(args[++i], 10);
    } else if (arg === '--margin-top') {
      options.marginTop = parseInt(args[++i], 10);
    } else if (arg === '--margin-right') {
      options.marginRight = parseInt(args[++i], 10);
    } else if (arg === '--margin-bottom') {
      options.marginBottom = parseInt(args[++i], 10);
    } else if (arg === '--generate-gdscript') {
      options.generateGdscript = true;
    } else if (arg === '--json') {
      options.json = true;
    } else if (arg.startsWith('--') && i + 1 < args.length) {
      const key = arg.slice(2);
      options[key] = args[++i];
    }
  }
  return options;
}

function printHelp() {
  console.log(`
Godot Player Spritesheet Manager (Corre Calango)
================================================
Comandos e opções:
  --inspect, -i <caminho>     Inspeciona um spritesheet PNG (dimensões e análise)
  --cols, -c <número>         Número de colunas (frames horizontais) [default: auto ou 4]
  --rows, -r <número>         Número de linhas [default: 1]
  --anim <nome>               Nome da animação no SpriteFrames (ex: jump, run, slide)
  --fps <número>              Taxa de quadros por segundo da animação [default: 6.0]
  --loop <true|false>         Se a animação entra em loop contínuo [default: false]
  --generate-gdscript         Gera o bloco de código GDScript pronto para _setup_animations()
  --json                      Gera saída dos dados em formato JSON puro
  --help, -h                  Exibe esta ajuda

Exemplos:
  node manage_player_spritesheet.js --inspect assets/calango-spritesheet-pulando.png
  node manage_player_spritesheet.js --inspect assets/calango-spritesheet-pulando.png --cols 4 --anim jump --fps 6.0 --loop false --generate-gdscript
`);
}

function calculateGrid(dims, options) {
  let cols = options.cols;
  let rows = options.rows || 1;

  if (cols <= 0) {
    const ratio = dims.width / dims.height;
    if (ratio >= 3.5 && ratio <= 4.5) cols = 4;
    else if (ratio >= 1.8 && ratio <= 2.2) cols = 2;
    else if (ratio >= 5.5 && ratio <= 6.5) cols = 6;
    else if (ratio >= 7.5 && ratio <= 8.5) cols = 8;
    else cols = 4;
  }

  const usableWidth = dims.width - (options.marginLeft + options.marginRight);
  const usableHeight = dims.height - (options.marginTop + options.marginBottom);

  const cellWidth = Math.floor(usableWidth / cols);
  const cellHeight = Math.floor(usableHeight / rows);

  const frames = [];
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const x = options.marginLeft + (c * cellWidth);
      const y = options.marginTop + (r * cellHeight);
      frames.push({
        index: (r * cols) + c,
        x,
        y,
        width: cellWidth,
        height: cellHeight,
        rect2: `Rect2(${x}, ${y}, ${cellWidth}, ${cellHeight})`
      });
    }
  }

  // Cálculo de transformação recomendada para manter os pés no chão
  // No calango-correndo.png, a altura do frame é 425 px e a escala é 0.20417, com offset.y = 43.0
  const visualHeight = cellHeight;
  const recommendedScale = Number(((REF_RUN_FRAME_HEIGHT * REF_RUN_SCALE) / visualHeight).toFixed(5));
  
  // Offset Y proporcional para manter a base alinhada com o chão
  const baseGroundOffset = REF_RUN_OFFSET_Y * (REF_RUN_SCALE / (recommendedScale || REF_RUN_SCALE));
  const recommendedOffsetY = Number(baseGroundOffset.toFixed(1));

  return {
    imageWidth: dims.width,
    imageHeight: dims.height,
    cols,
    rows,
    frameCount: frames.length,
    cellWidth,
    cellHeight,
    frames,
    transform: {
      recommendedScale,
      scaleVector: `Vector2(${recommendedScale}, ${recommendedScale})`,
      recommendedOffsetY,
      offsetVector: `Vector2(0.0, ${recommendedOffsetY})`
    }
  };
}

function generateGdscriptSnippet(assetPath, animName, fps, loop, gridData) {
  const resPath = assetPath.replace(/^.*assets[\\/]/, 'res://assets/').replace(/\\/g, '/');
  const framesList = gridData.frames.map(f => `\t\t${f.rect2}`).join(',\n');
  const animUpper = animName.toUpperCase();

  return `
# ==============================================================================
# CONFIGURAÇÃO GERADA PARA ANIMAÇÃO "${animName.toUpperCase()}"
# Spritesheet: ${resPath} (${gridData.imageWidth}x${gridData.imageHeight}, ${gridData.frameCount} frames de ${gridData.cellWidth}x${gridData.cellHeight})
# ==============================================================================

# 1. Constantes de transformação (adicione no topo de player.gd se aplicável):
const ${animUpper}_SCALE: Vector2 = ${gridData.transform.scaleVector}
const ${animUpper}_OFFSET: Vector2 = ${gridData.transform.offsetVector}

# 2. Bloco para adicionar dentro de _setup_animations() em player.gd:
\tvar ${animName}_sheet: Texture2D = load("${resPath}")
\tif not ${animName}_sheet:
\t\tpush_error("Player: não foi possível carregar ${path.basename(assetPath)}")
\telse:
\t\tframes.add_animation("${animName}")
\t\tframes.set_animation_speed("${animName}", ${fps.toFixed(1)})
\t\tframes.set_animation_loop("${animName}", ${loop})
\t\tvar ${animName}_rects: Array[Rect2] = [
${framesList}
\t\t]
\t\tfor r in ${animName}_rects:
\t\t\tvar atlas := AtlasTexture.new()
\t\t\tatlas.atlas = ${animName}_sheet
\t\t\tatlas.region = r
\t\t\tatlas.filter_clip = true
\t\t\tframes.add_frame("${animName}", atlas)

# 3. Atualização em _update_sprite_transform_for_anim() em player.gd:
\telif sprite.animation == "${animName}":
\t\tsprite.scale = ${animUpper}_SCALE
\t\tsprite.offset = ${animUpper}_OFFSET
`;
}

function main() {
  const options = parseArgs();

  if (options.help || (!options.asset && !options.json)) {
    printHelp();
    process.exit(options.help ? 0 : 1);
  }

  const assetPath = path.resolve(process.cwd(), options.asset);
  if (!fs.existsSync(assetPath)) {
    console.error(`Arquivo não encontrado: ${assetPath}`);
    process.exit(1);
  }

  const dims = getPngDimensions(assetPath);
  if (!dims) {
    console.error(`Não foi possível decodificar dimensões do PNG em: ${assetPath}`);
    process.exit(1);
  }

  const gridData = calculateGrid(dims, options);

  if (options.json) {
    console.log(JSON.stringify({
      asset: options.asset,
      dimensions: dims,
      grid: gridData,
      animation: {
        name: options.anim,
        fps: options.fps,
        loop: options.loop
      }
    }, null, 2));
    return;
  }

  console.log(`\n=== ANÁLISE DE SPRITESHEET: ${path.basename(assetPath)} ===`);
  console.log(`Dimensões Totais : ${dims.width} x ${dims.height} px`);
  console.log(`Grid Detectado   : ${gridData.cols} colunas x ${gridData.rows} linhas (${gridData.frameCount} frames)`);
  console.log(`Tamanho do Frame : ${gridData.cellWidth} x ${gridData.cellHeight} px`);
  console.log(`Escala Sugerida  : ${gridData.transform.scaleVector}`);
  console.log(`Offset Sugerido  : ${gridData.transform.offsetVector}`);
  console.log(`------------------------------------------------------------`);
  console.log(`Frames calculados:`);
  gridData.frames.forEach(f => {
    console.log(`  Frame ${f.index}: ${f.rect2}`);
  });

  if (options.generateGdscript) {
    console.log(generateGdscriptSnippet(options.asset, options.anim, options.fps, options.loop, gridData));
  }
}

main();
