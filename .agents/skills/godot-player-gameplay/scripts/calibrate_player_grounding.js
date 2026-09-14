#!/usr/bin/env node

/**
 * calibrate_player_grounding.js
 * 
 * Ferramenta CLI de alta precisão para calibração de Ground Anchor (origem de solo)
 * e alinhamento de spritesheets do Calango no Godot 4.
 * 
 * Sem dependências externas (Node.js nativo + zlib).
 */

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

// Constantes padrão da física do Calango
const DEFAULT_GROUND_Y = 22.4; // Base da CapsuleShape2D no solo
const DEFAULT_SPRITE_SCALE = 0.245;
const ALPHA_THRESHOLD = 15;

/**
 * Decodifica arquivo PNG em RGBA 8-bit com descompressão zlib e desfiltragem de scanlines
 */
function decodePNG(filePath) {
  const buf = fs.readFileSync(filePath);
  if (buf.readUInt32BE(0) !== 0x89504E47) {
    throw new Error(`Arquivo não é um PNG válido: ${filePath}`);
  }
  const width = buf.readUInt32BE(16);
  const height = buf.readUInt32BE(20);
  const bitDepth = buf.readUInt8(24);
  const colorType = buf.readUInt8(25);

  let offset = 8;
  const idatChunks = [];
  while (offset < buf.length) {
    const len = buf.readUInt32BE(offset);
    const type = buf.toString('ascii', offset + 4, offset + 8);
    if (type === 'IDAT') {
      idatChunks.push(buf.subarray(offset + 8, offset + 8 + len));
    }
    offset += 12 + len;
  }

  const decompressed = zlib.inflateSync(Buffer.concat(idatChunks));
  const bytesPerPixel = colorType === 6 ? 4 : (colorType === 2 ? 3 : (colorType === 4 ? 2 : 1));
  const stride = width * bytesPerPixel;
  const pixels = Buffer.alloc(width * height * 4);

  let srcPos = 0;
  const prevRow = Buffer.alloc(stride);
  const currRow = Buffer.alloc(stride);

  function paeth(a, b, c) {
    const p = a + b - c;
    const pa = Math.abs(p - a);
    const pb = Math.abs(p - b);
    const pc = Math.abs(p - c);
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  }

  for (let y = 0; y < height; y++) {
    const filter = decompressed[srcPos++];
    for (let i = 0; i < stride; i++) {
      const raw = decompressed[srcPos++];
      const a = i >= bytesPerPixel ? currRow[i - bytesPerPixel] : 0;
      const b = prevRow[i];
      const c = i >= bytesPerPixel ? prevRow[i - bytesPerPixel] : 0;
      let val = raw;
      if (filter === 1) val = (raw + a) & 0xFF;
      else if (filter === 2) val = (raw + b) & 0xFF;
      else if (filter === 3) val = (raw + Math.floor((a + b) / 2)) & 0xFF;
      else if (filter === 4) val = (raw + paeth(a, b, c)) & 0xFF;
      currRow[i] = val;
    }

    for (let x = 0; x < width; x++) {
      const dstIdx = (y * width + x) * 4;
      const srcIdx = x * bytesPerPixel;
      if (bytesPerPixel === 4) {
        pixels[dstIdx] = currRow[srcIdx];
        pixels[dstIdx + 1] = currRow[srcIdx + 1];
        pixels[dstIdx + 2] = currRow[srcIdx + 2];
        pixels[dstIdx + 3] = currRow[srcIdx + 3];
      } else if (bytesPerPixel === 3) {
        pixels[dstIdx] = currRow[srcIdx];
        pixels[dstIdx + 1] = currRow[srcIdx + 1];
        pixels[dstIdx + 2] = currRow[srcIdx + 2];
        pixels[dstIdx + 3] = 255;
      }
    }
    currRow.copy(prevRow);
  }

  return { width, height, pixels };
}

/**
 * Analisa uma região retangular e obtém o bounding box de pixels não-transparentes
 */
function analyzeRegion(pngData, rect) {
  const { x: rx, y: ry, w: rw, h: rh } = rect;
  let minX = rw, maxX = -1, minY = rh, maxY = -1;

  for (let y = 0; y < rh; y++) {
    const py = ry + y;
    if (py >= pngData.height) continue;
    for (let x = 0; x < rw; x++) {
      const px = rx + x;
      if (px >= pngData.width) continue;
      const alpha = pngData.pixels[(py * pngData.width + px) * 4 + 3];
      if (alpha > ALPHA_THRESHOLD) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX === -1) {
    return null; // Quadro vazio
  }

  return {
    frameRect: rect,
    usedRect: { x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1 },
    footY: maxY + 1, // Posição Y da sola em relação ao topo do frame
    headY: minY,
    bottomMargin: rh - (maxY + 1)
  };
}

/**
 * Calcula o offset vertical calibrado para posicionar a sola da pata em groundY
 */
function calculateGroundOffset(frameHeight, footY, scaleY, groundY) {
  const frameCenterY = frameHeight / 2.0;
  const deltaFromCenter = footY - frameCenterY;
  const scaledDelta = deltaFromCenter * scaleY;
  const offsetY = groundY - scaledDelta;
  return Number(offsetY.toFixed(2));
}

// Configurações canônicas padrão do jogo Corre Calango
const DEFAULT_PRESETS = {
  run: {
    file: 'assets/calango-correndo.png',
    frames: [
      { x: 6, y: 0, w: 384, h: 425 },
      { x: 391, y: 0, w: 384, h: 425 },
      { x: 777, y: 0, w: 378, h: 425 },
      { x: 1152, y: 0, w: 384, h: 425 }
    ]
  },
  jump: {
    file: 'assets/calango-spritesheet-pulando.png',
    frames: [
      { x: 0, y: 0, w: 384, h: 379 },
      { x: 384, y: 0, w: 384, h: 379 },
      { x: 768, y: 0, w: 384, h: 379 },
      { x: 1152, y: 0, w: 384, h: 379 }
    ]
  },
  duck: {
    file: 'assets/spritesheet (2).png',
    frames: [
      { x: 40, y: 835, w: 360, h: 155 },
      { x: 500, y: 835, w: 360, h: 155 }
    ]
  }
};

function runCLI() {
  const args = process.argv.slice(2);

  let mode = 'calibrate';
  let inspectFile = null;
  let cols = 4;
  let groundY = DEFAULT_GROUND_Y;
  let scaleY = DEFAULT_SPRITE_SCALE;
  let jsonOutput = false;
  let generateGDScript = false;

  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--inspect') {
      mode = 'inspect';
      inspectFile = args[++i];
    } else if (a === '--cols') {
      cols = parseInt(args[++i], 10);
    } else if (a === '--ground-y') {
      groundY = parseFloat(args[++i]);
    } else if (a === '--scale') {
      scaleY = parseFloat(args[++i]);
    } else if (a === '--json') {
      jsonOutput = true;
    } else if (a === '--generate-gdscript') {
      generateGDScript = true;
    } else if (a === '--help' || a === '-h') {
      printHelp();
      process.exit(0);
    }
  }

  if (mode === 'inspect') {
    handleInspect(inspectFile, cols, scaleY, groundY, jsonOutput, generateGDScript);
  } else {
    handleCalibrateAll(scaleY, groundY, jsonOutput, generateGDScript);
  }
}

function printHelp() {
  console.log(`
Uso: node calibrate_player_grounding.js [opções]

Opções:
  --calibrate              (Padrão) Executa calibração completa das animações do jogo (run, jump, duck)
  --inspect <arquivo.png>  Analisa e calibra um arquivo PNG específico
  --cols <n>               Número de quadros horizontais ao inspecionar (padrão: 4)
  --ground-y <val>         Coordenada Y física do chão no Player (padrão: 22.4)
  --scale <val>            Escala vertical do sprite (padrão: 0.245)
  --generate-gdscript      Gera o bloco de código GDScript pronto para o player.gd
  --json                   Retorna a análise estruturada em JSON
  --help, -h               Exibe esta mensagem de ajuda
  `);
}

function handleInspect(filePath, numCols, scaleY, groundY, jsonOutput, generateGDScript) {
  if (!filePath || !fs.existsSync(filePath)) {
    console.error(`Erro: Arquivo não encontrado: ${filePath}`);
    process.exit(1);
  }

  const png = decodePNG(filePath);
  const frameWidth = Math.floor(png.width / numCols);
  const frameHeight = png.height;

  const frames = [];
  for (let c = 0; c < numCols; c++) {
    frames.push({ x: c * frameWidth, y: 0, w: frameWidth, h: frameHeight });
  }

  const analysis = frames.map(f => analyzeRegion(png, f)).filter(Boolean);
  // Usa o primeiro frame ou o frame mais próximo do chão para a ancoragem
  const maxFootY = Math.max(...analysis.map(a => a.footY));
  const suggestedOffset = calculateGroundOffset(frameHeight, maxFootY, scaleY, groundY);

  const result = {
    file: filePath,
    width: png.width,
    height: png.height,
    numFrames: numCols,
    frameDimensions: { w: frameWidth, h: frameHeight },
    maxFootY,
    scaleY,
    groundY,
    suggestedOffsetY: suggestedOffset,
    frames: analysis
  };

  if (jsonOutput) {
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  console.log(`\n=== INSPEÇÃO: ${path.basename(filePath)} ===`);
  console.log(`Dimensões: ${png.width}x${png.height} (${numCols} frames de ${frameWidth}x${frameHeight})`);
  console.log(`Linha de apoio (Pata mais baixa): y = ${maxFootY} px`);
  console.log(`Escala Y: ${scaleY} | Chão físico Y: ${groundY}`);
  console.log(`-> Offset Y Sugerido para o sprite: Vector2(0.0, ${suggestedOffset})`);

  if (generateGDScript) {
    console.log('\n--- Bloco GDScript Gerado ---');
    console.log(`const CUSTOM_SCALE: Vector2 = Vector2(${scaleY}, ${scaleY})`);
    console.log(`const CUSTOM_OFFSET: Vector2 = Vector2(0.0, ${suggestedOffset})`);
  }
}

function handleCalibrateAll(scaleY, groundY, jsonOutput, generateGDScript) {
  const results = {};

  for (const [animName, preset] of Object.entries(DEFAULT_PRESETS)) {
    if (!fs.existsSync(preset.file)) {
      results[animName] = { error: `Arquivo não encontrado: ${preset.file}` };
      continue;
    }
    const png = decodePNG(preset.file);
    const frameAnalysis = preset.frames.map(f => analyzeRegion(png, f)).filter(Boolean);

    // Na corrida e agachamento usamos o frame de maior apoio no chão.
    // No salto usamos o Frame 0 (decolagem) para ancorar a física de decolagem sem teleport.
    let footYToAnchor;
    if (animName === 'jump') {
      footYToAnchor = frameAnalysis[0] ? frameAnalysis[0].footY : frameAnalysis[0].footY;
    } else {
      footYToAnchor = Math.max(...frameAnalysis.map(a => a.footY));
    }

    const frameHeight = preset.frames[0].h;
    const offsetY = calculateGroundOffset(frameHeight, footYToAnchor, scaleY, groundY);

    results[animName] = {
      file: preset.file,
      frameHeight,
      footY: footYToAnchor,
      offsetY,
      framesCount: frameAnalysis.length
    };
  }

  if (jsonOutput) {
    console.log(JSON.stringify(results, null, 2));
    return;
  }

  console.log('\n======================================================');
  console.log('   CALIBRAÇÃO DE GROUND ANCHOR DO CALANGO (GODOT 4)   ');
  console.log('======================================================');
  console.log(`Parâmetros Globais: Ground Y = ${groundY} px | Escala = ${scaleY}\n`);

  for (const [anim, data] of Object.entries(results)) {
    if (data.error) {
      console.log(`- [${anim.toUpperCase()}]: ${data.error}`);
    } else {
      console.log(`- [${anim.toUpperCase()}]:`);
      console.log(`    Arquivo: ${data.file}`);
      console.log(`    Altura do frame: ${data.frameHeight} px | Linha de pata: ${data.footY} px`);
      console.log(`    Offset Y Compensado: ${data.offsetY} px`);
    }
  }

  console.log('\n======================================================');

  if (generateGDScript || !jsonOutput) {
    console.log('\n--- CÓDIGO GDSCRIPT GERADO PARA PLAYER.GD ---');
    console.log('const ANIMATION_OFFSETS: Dictionary = {');
    for (const [anim, data] of Object.entries(results)) {
      if (!data.error) {
        console.log(`\t"${anim}": Vector2(0.0, ${data.offsetY}),`);
      }
    }
    console.log('}');
    console.log(`
func _on_animation_changed() -> void:
\t_update_sprite_transform()

func _update_sprite_transform() -> void:
\tif sprite == null:
\t\treturn
\tvar anim := sprite.animation
\tif ANIMATION_OFFSETS.has(anim):
\t\tsprite.position = ANIMATION_OFFSETS[anim]
\telse:
\t\tsprite.position = Vector2.ZERO
`);
  }
}

runCLI();
