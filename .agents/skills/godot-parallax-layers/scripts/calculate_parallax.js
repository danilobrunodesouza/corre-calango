#!/usr/bin/env node
/**
 * calculate_parallax.js — Calculadora de Repetição Contínua e Snippet Generator para Parallax no Godot 4.
 * 
 * Uso:
 *   node calculate_parallax.js --asset assets/montes.png --scale 0.35 --motion-scale 0.1 --y-pos 360
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '../../../../');

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
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      options[key] = args[++i];
    }
  }
  return options;
}

function main() {
  const options = parseArgs();

  if (!options.asset) {
    console.log(`
Uso do calculate_parallax:
  node calculate_parallax.js --asset <arquivo> [opções]

Opções:
  --asset <arquivo>          Caminho do arquivo PNG (ex: assets/montes.png)
  --scale <valor>            Fator de escala do sprite (padrão: 1.0)
  --motion-scale <valor>     Velocidade relativa de scroll X (padrão: 0.1)
  --y-pos <valor>            Posição vertical Y do sprite (padrão: 360.0)
  --layer-name <nome>        Nome do nó ParallaxLayer (padrão derivado do arquivo)
`);
    process.exit(0);
  }

  const assetRel = options.asset.replace(/\\/g, '/');
  const fullAssetPath = path.isAbsolute(assetRel) ? assetRel : path.join(PROJECT_ROOT, assetRel);

  if (!fs.existsSync(fullAssetPath)) {
    console.error(`Erro: Arquivo não encontrado: ${fullAssetPath}`);
    process.exit(1);
  }

  const dims = getPngDimensions(fullAssetPath);
  if (!dims) {
    console.error(`Erro: Não foi possível ler as dimensões do PNG em: ${fullAssetPath}`);
    process.exit(1);
  }

  const baseName = path.basename(assetRel, path.extname(assetRel));
  const scale = options.scale ? parseFloat(options.scale) : 1.0;
  const motionScale = options['motion-scale'] ? parseFloat(options['motion-scale']) : 0.1;
  const yPos = options['y-pos'] ? parseFloat(options['y-pos']) : 360.0;
  const layerName = options['layer-name'] || `Layer${baseName.charAt(0).toUpperCase() + baseName.slice(1)}`;
  const godotRes = `res://${assetRel.startsWith('assets/') ? assetRel : 'assets/' + path.basename(assetRel)}`;

  const renderedW = Number((dims.width * scale).toFixed(2));
  const renderedH = Number((dims.height * scale).toFixed(2));
  const centerX = Number((renderedW * 0.5).toFixed(2));

  console.log('================================================================');
  console.log('       CÁLCULO EXATO DE PARALLAX & MOTION MIRRORING             ');
  console.log('================================================================\n');

  console.log(`• Arquivo: ${assetRel}`);
  console.log(`• Dimensões Nativas: ${dims.width} × ${dims.height} px`);
  console.log(`• Fator de Escala: ${scale}`);
  console.log(`• Dimensões Renderizadas: ${renderedW} × ${renderedH} px`);
  console.log(`• Motion Mirroring Exato: Vector2(${renderedW}, 0.0)`);
  console.log(`• Posição Central do Sprite: Vector2(${centerX}, ${yPos})`);
  console.log(`• Velocidade de Scroll (motion_scale): Vector2(${motionScale}, 0.0)\n`);

  console.log('----------------------------------------------------------------');
  console.log('   SNIPPET GDSCRIPT GERADO (Copie para seu script do World)     ');
  console.log('----------------------------------------------------------------\n');

  const snippet = `\t# Camada Parallax: ${layerName}
\tvar ${baseName}_layer := ParallaxLayer.new()
\t${baseName}_layer.name = "${layerName}"
\t${baseName}_layer.motion_scale = Vector2(${motionScale}, 0.0)
\t${baseName}_layer.motion_mirroring = Vector2(${renderedW}, 0.0)

\tvar ${baseName}_sprite := Sprite2D.new()
\t${baseName}_sprite.texture = load("${godotRes}")
\t${baseName}_sprite.scale = Vector2(${scale}, ${scale})
\t${baseName}_sprite.position = Vector2(${centerX}, ${yPos})
\t${baseName}_layer.add_child(${baseName}_sprite)
\tparallax.add_child(${baseName}_layer)`;

  console.log(snippet);
  console.log('\n================================================================\n');
}

main();
