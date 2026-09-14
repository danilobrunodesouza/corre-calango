#!/usr/bin/env node

/**
 * palette_tool.js — Ferramenta de linha de comando para gerenciamento de paletas de cores no Corre Calango.
 * 
 * Uso:
 *   node palette_tool.js --list
 *   node palette_tool.js --apply <preset_id>
 *   node palette_tool.js --set-custom <dark_hex> <light_hex> [nome]
 *   node palette_tool.js --test
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const LEGACY_ALIASES = {
  default: 'cangaco',
  classic: 'xilogravura',
  gameboy: 'mandacaru',
  cyberpunk: 'sol_de_rachar',
  matrix: 'palma',
  sepia: 'poeira',
  vaporwave: 'flor_mandacaru',
  crimson: 'acerola',
  pimenta: 'acerola',
  solarized: 'velho_chico',
  caju: 'rapadura',
  azeite_de_dende: 'dende'
};

const PRESETS = {
  cangaco: {
    id: 'cangaco',
    name: 'Cangaço',
    dark: '#85472e',
    light: '#f9dcba',
    desc: 'Tons de couro e sol do agreste inspirados no cangaço nordestino.'
  },
  xilogravura: {
    id: 'xilogravura',
    name: 'Xilogravura',
    dark: '#1a1a1a',
    light: '#f5f5f5',
    desc: 'Preto no branco clássico dos folhetos de cordel e xilogravura.'
  },
  mandacaru: {
    id: 'mandacaru',
    name: 'Mandacaru',
    dark: '#0f380f',
    light: '#8bac0f',
    desc: 'Tons de verde cacto do lendário mandacaru que floresce na seca.'
  },
  sol_de_rachar: {
    id: 'sol_de_rachar',
    name: 'Sol de Rachar',
    dark: '#120c02',
    light: '#ffb000',
    desc: 'Âmbar radiante e dourado do sol escaldante do sertão ao meio-dia.'
  },
  palma: {
    id: 'palma',
    name: 'Palma & Juazeiro',
    dark: '#051405',
    light: '#00ff41',
    desc: 'Verde vivo e resistente da palma forrageira e da árvore sagrada da caatinga.'
  },
  poeira: {
    id: 'poeira',
    name: 'Poeira da Estrada',
    dark: '#2b1d0c',
    light: '#e8d8b8',
    desc: 'Tons terrosos de barro seco, poeira de vaquejada e estradas do interior.'
  },
  flor_mandacaru: {
    id: 'flor_mandacaru',
    name: 'Flor de Mandacaru',
    dark: '#282a36',
    light: '#ff79c6',
    desc: 'Rosa magenta da flor noturna do sertão e o colorido das festas juninas.'
  },
  acerola: {
    id: 'acerola',
    name: 'Acerola do Sertão',
    dark: '#1a0000',
    light: '#ff3333',
    desc: 'Vermelho vibrante da acerola cultivada nos vales e polos irrigados do sertão.'
  },
  velho_chico: {
    id: 'velho_chico',
    name: 'Velho Chico',
    dark: '#002b36',
    light: '#93a1a1',
    desc: 'Tons azulados e prateados das águas e do luar sobre o Rio São Francisco.'
  },
  praia: {
    id: 'praia',
    name: 'Praias do Nordeste',
    dark: '#0c3b5e',
    light: '#fce4b8',
    desc: 'Azul marinho profundo dos arrecifes e areia dourada das praias nordestinas.'
  },
  lencois: {
    id: 'lencois',
    name: 'Lençóis Maranhenses',
    dark: '#05445e',
    light: '#e4f1f4',
    desc: 'Dunas de areia alva e lagoas cristalinas de água doce do Maranhão.'
  },
  rapadura: {
    id: 'rapadura',
    name: 'Engenho & Rapadura',
    dark: '#3b1808',
    light: '#fec84d',
    desc: 'Marrom escuro da rapadura artesanal e amarelo dourado do melaço de cana.'
  },
  frevo: {
    id: 'frevo',
    name: 'Frevo & Olinda',
    dark: '#2e0854',
    light: '#ffe600',
    desc: 'Roxo dos estandartes e maracatus com o amarelo vibrante do frevo pernambucano.'
  },
  caruaru: {
    id: 'caruaru',
    name: 'Barro de Caruaru',
    dark: '#381a0e',
    light: '#e3c7b1',
    desc: 'Terracota queimada e argila crua da arte figurativa de Mestre Vitalino.'
  },
  dende: {
    id: 'dende',
    name: 'Azeite de Dendê',
    dark: '#260801',
    light: '#ff7b25',
    desc: 'Marrom profundo da panela de barro e o laranja-dourado reluzente do azeite de dendê.'
  }
};

function getSavePath() {
  const appData = process.env.APPDATA || path.join(process.env.USERPROFILE || '', 'AppData', 'Roaming');
  return path.join(appData, 'Godot', 'app_userdata', 'Corre Calango', 'palette_settings.json');
}

function normalizeHex(hex) {
  return hex.replace(/^#/, '').toLowerCase();
}

function listPresets() {
  console.log('\n=== PALETAS DISPONÍVEIS (CORRE CALANGO) ===\n');
  let currentId = 'classic';
  const savePath = getSavePath();
  if (fs.existsSync(savePath)) {
    try {
      const data = JSON.parse(fs.readFileSync(savePath, 'utf8'));
      if (data && data.preset_id) {
        currentId = LEGACY_ALIASES[data.preset_id] || data.preset_id;
      }
    } catch (e) {}
  }

  for (const [id, p] of Object.entries(PRESETS)) {
    const isCurrent = id === currentId ? ' [ATIVO]' : '';
    console.log(`• ID: ${id.padEnd(14)} | Nome: ${p.name.padEnd(20)} | Dark: ${p.dark} | Light: ${p.light}${isCurrent}`);
    console.log(`  └─ ${p.desc}`);
  }
  console.log('\nPara aplicar: node palette_tool.js --apply <preset_id>');
  console.log('Para cor customizada: node palette_tool.js --set-custom <dark_hex> <light_hex> [nome]\n');
}

function applyPreset(id) {
  if (LEGACY_ALIASES[id]) {
    id = LEGACY_ALIASES[id];
  }
  const preset = PRESETS[id];
  if (!preset) {
    console.error(`[ERRO] Preset '${id}' não encontrado. Use --list para ver as opções.`);
    process.exit(1);
  }

  const savePath = getSavePath();
  const dir = path.dirname(savePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const data = {
    preset_id: preset.id,
    name: preset.name,
    dark: normalizeHex(preset.dark),
    light: normalizeHex(preset.light)
  };

  fs.writeFileSync(savePath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`[SUCESSO] Paleta '${preset.name}' (${preset.id}) configurada como padrão!`);
  console.log(`  Dark : #${data.dark}`);
  console.log(`  Light: #${data.light}`);
}

function setCustomColors(darkHex, lightHex, customName) {
  if (!darkHex || !lightHex) {
    console.error('[ERRO] Especifique as cores dark e light em hexadecimal. Ex: --set-custom "#0f380f" "#8bac0f"');
    process.exit(1);
  }

  const savePath = getSavePath();
  const dir = path.dirname(savePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const name = customName || 'Custom';
  const data = {
    preset_id: 'custom',
    name: name,
    dark: normalizeHex(darkHex),
    light: normalizeHex(lightHex)
  };

  fs.writeFileSync(savePath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`[SUCESSO] Cores customizadas salvas com sucesso!`);
  console.log(`  Nome : ${name}`);
  console.log(`  Dark : #${data.dark}`);
  console.log(`  Light: #${data.light}`);
}

function runTests() {
  const godotExe = 'C:\\Users\\notebook\\develop\\Godot\\Godot_v4.6-stable_win64_console.exe';
  console.log('[TESTE] Executando testes automatizados com Godot 4.6 Console...');
  try {
    const out = execSync(`& "${godotExe}" --headless scenes/main/main.tscn -- --test`, {
      shell: 'powershell.exe',
      stdio: 'inherit'
    });
  } catch (err) {
    console.error('[FALHA] Erro durante a execução dos testes.');
    process.exit(1);
  }
}

// CLI args parsing
const args = process.argv.slice(2);
if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
  console.log('Uso:');
  console.log('  node palette_tool.js --list');
  console.log('  node palette_tool.js --apply <preset_id>');
  console.log('  node palette_tool.js --set-custom <dark_hex> <light_hex> [nome]');
  console.log('  node palette_tool.js --test');
  process.exit(0);
}

if (args.includes('--list')) {
  listPresets();
} else if (args.includes('--apply')) {
  const idx = args.indexOf('--apply');
  const id = args[idx + 1];
  if (!id) {
    console.error('[ERRO] Informe o id do preset. Exemplo: node palette_tool.js --apply mandacaru');
    process.exit(1);
  }
  applyPreset(id);
} else if (args.includes('--set-custom')) {
  const idx = args.indexOf('--set-custom');
  const dark = args[idx + 1];
  const light = args[idx + 2];
  const name = args[idx + 3] || 'Custom';
  setCustomColors(dark, light, name);
} else if (args.includes('--test')) {
  runTests();
} else {
  console.error('[ERRO] Comando desconhecido. Use --help para ver as instruções.');
  process.exit(1);
}
