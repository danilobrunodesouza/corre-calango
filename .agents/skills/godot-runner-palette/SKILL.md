---
name: godot-runner-palette
description: >-
  Specialist skill for managing, customizing, and programmatically swapping duotone and 1-bit color palettes in Godot 4 2D endless runners. Use whenever you need to adjust dark and light color themes, register new palette presets, expose player color selection options, or propagate palette changes across shaders and UI.
---

# Godot Runner Palette Specialist

Esta skill guia o gerenciamento, customização e troca programática de paletas de cores no **Corre Calango**. Ela permite alterar as cores `dark` e `light` em tempo de execução com propagação imediata para todo o jogo, tela inicial, HUD e shaders de pós-processamento, além de oferecer seleção interativa para os jogadores.

---

## 1. Arquitetura do Sistema de Cores

O sistema é construído sobre três pilares desacoplados:

1. **Autoload `PaletteManager` (`autoloads/palette_manager.gd`)**:
   - Ponto central da verdade cromática.
   - Armazena as cores ativas `current_dark` e `current_light`.
   - Gerencia presets cadastrados (`cangaco`, `xilogravura`, `mandacaru`, `sol_de_rachar`, `palma`, `poeira`, `flor_mandacaru`, `acerola`, `velho_chico`, `praia`, `lencois`, `rapadura`, `frevo`, `caruaru`, `dende`).
   - Salva a preferência do jogador automaticamente em `user://palette_settings.json`.
   - Emite o sinal `palette_changed(dark_color: Color, light_color: Color)`.

2. **Shader Fullscreen Parametrizado (`scenes/effects/day_night_cycle.gd`)**:
   - Um CanvasLayer de pós-processamento que intercepta toda a tela.
   - Converte os pixels dos assets (0.0 = preto, 1.0 = branco) nas cores da paleta ativa:
     - **Dia**: Fundo = `color_light`, Silhuetas/Sprites = `color_dark`.
     - **Noite**: Fundo = `color_dark`, Silhuetas/Sprites = `color_light`.
   - Atualiza seus uniforms instantaneamente ao receber `palette_changed`.

3. **Interface e Interação do Jogador**:
   - **Tela Inicial (`StartScreen`)**: Botão `StartThemeButton` permite escolher o visual antes de começar.
   - **HUD Durante a Corrida (`HUD`)**: Botão `ThemeButton` (`🎨 TEMA`) permite alternar entre os temas a qualquer momento.
   - **Atalho Global de Teclado**: Pressionar a tecla **`C`** avança ciclicamente para a próxima paleta cadastrada.

Para ver a lista completa de cores e detalhes matemáticos, consulte o [Catálogo de Paletas](./references/palettes.md).

---

## 2. Como Alterar Cores Programaticamente (GDScript API)

### A. Trocar para Cores Customizadas Diretas
Se você deseja aplicar um par arbitrário de cores `dark` e `light`:

```gdscript
# Exemplo: Tema Floresta Noturna
var dark := Color("#0b1d13")
var light := Color("#73c991")

PaletteManager.set_colors(dark, light, "Floresta Noturna")
```
*A alteração é propagada instantaneamente para a tela, HUD e preferências salvas.*

### B. Aplicar um Preset pelo ID
```gdscript
PaletteManager.set_palette("mandacaru")
# Opções padrão: "cangaco", "xilogravura", "mandacaru", "sol_de_rachar", "palma", "poeira", "flor_mandacaru", "acerola", "velho_chico", "praia", "lencois", "rapadura", "frevo", "caruaru", "dende"
```

### C. Avançar Ciclicamente para a Próxima Paleta
```gdscript
var novo_id: String = PaletteManager.next_palette()
```

### D. Cadastrar um Novo Preset Dinamicamente
```gdscript
PaletteManager.register_preset(
    "outono",
    "Outono Dourado",
    Color("#2e1c0c"),
    Color("#f4a261")
)
```

### E. Conectar Nós Customizados à Mudança de Paleta
```gdscript
func _ready() -> void:
    PaletteManager.palette_changed.connect(_on_palette_changed)

func _on_palette_changed(dark: Color, light: Color) -> void:
    # Atualize estilos ou elementos que não usem o shader se necessário
    pass
```

---

## 3. Automação via Linha de Comando (CLI)

A skill inclui a ferramenta `scripts/palette_tool.js` (Node.js) para gerenciar e inspecionar paletas via terminal:

```bash
# Listar todas as paletas e identificar a ativa
node .agents/skills/godot-runner-palette/scripts/palette_tool.js --list

# Aplicar um preset como padrão
node .agents/skills/godot-runner-palette/scripts/palette_tool.js --apply mandacaru

# Configurar cores hexadecimais customizadas
node .agents/skills/godot-runner-palette/scripts/palette_tool.js \
  --set-custom "#1a0033" "#ff00aa" "Neon Roxo"

# Executar a suíte completa de testes no Godot
node .agents/skills/godot-runner-palette/scripts/palette_tool.js --test
```

---

## 4. Validação e Testes Automatizados

Para testar a estabilidade do sistema de cores e a conformidade do jogo:

```powershell
& "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless scenes/main/main.tscn -- --test
```

O teste verifica:
1. Existência e inicialização do Autoload `PaletteManager`.
2. Presença de todos os presets pré-configurados.
3. Propagação dos parâmetros de shader no `DayNightCycle`.
4. Atualização dos botões da interface no `StartScreen` e `HUD`.
5. Troca de cores arbitrárias via `set_colors()`.
6. Ciclo ininterrupto via `next_palette()`.
