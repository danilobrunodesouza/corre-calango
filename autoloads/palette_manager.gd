## PaletteManager — gerenciamento global de paletas de cores programáticas (estilo duotone / 1-bit).
## Mantém as cores dark e light ativas, cataloga presets e emite sinais quando a paleta muda.
extends Node

signal palette_changed(dark_color: Color, light_color: Color)

const SAVE_PATH: String = "user://palette_settings.json"

## Mapeamento de compatibilidade para IDs antigos/legados
const LEGACY_ALIASES: Dictionary = {
	"default": "cangaco",
	"classic": "xilogravura",
	"gameboy": "mandacaru",
	"cyberpunk": "sol_de_rachar",
	"matrix": "palma",
	"sepia": "poeira",
	"vaporwave": "flor_mandacaru",
	"crimson": "acerola",
	"pimenta": "acerola",
	"solarized": "velho_chico",
	"caju": "rapadura",
	"azeite_de_dende": "dende"
}

## Estrutura de um preset:
## id: String, name: String, dark: Color, light: Color
var presets: Dictionary = {
	"cangaco": {
		"id": "cangaco",
		"name": "Cangaço",
		"dark": Color("#85472e"),
		"light": Color("#f9dcba")
	},
	"xilogravura": {
		"id": "xilogravura",
		"name": "Xilogravura",
		"dark": Color("#1a1a1a"),
		"light": Color("#f5f5f5")
	},
	"mandacaru": {
		"id": "mandacaru",
		"name": "Mandacaru",
		"dark": Color("#0f380f"),
		"light": Color("#8bac0f")
	},
	"sol_de_rachar": {
		"id": "sol_de_rachar",
		"name": "Sol de Rachar",
		"dark": Color("#120c02"),
		"light": Color("#ffb000")
	},
	"palma": {
		"id": "palma",
		"name": "Palma & Juazeiro",
		"dark": Color("#051405"),
		"light": Color("#00ff41")
	},
	"poeira": {
		"id": "poeira",
		"name": "Poeira da Estrada",
		"dark": Color("#2b1d0c"),
		"light": Color("#e8d8b8")
	},
	"flor_mandacaru": {
		"id": "flor_mandacaru",
		"name": "Flor de Mandacaru",
		"dark": Color("#282a36"),
		"light": Color("#ff79c6")
	},
	"acerola": {
		"id": "acerola",
		"name": "Acerola do Sertão",
		"dark": Color("#1a0000"),
		"light": Color("#ff3333")
	},
	"velho_chico": {
		"id": "velho_chico",
		"name": "Velho Chico",
		"dark": Color("#002b36"),
		"light": Color("#93a1a1")
	},
	"praia": {
		"id": "praia",
		"name": "Praias do Nordeste",
		"dark": Color("#0c3b5e"),
		"light": Color("#fce4b8")
	},
	"lencois": {
		"id": "lencois",
		"name": "Lençóis Maranhenses",
		"dark": Color("#05445e"),
		"light": Color("#e4f1f4")
	},
	"rapadura": {
		"id": "rapadura",
		"name": "Engenho & Rapadura",
		"dark": Color("#3b1808"),
		"light": Color("#fec84d")
	},
	"frevo": {
		"id": "frevo",
		"name": "Frevo & Olinda",
		"dark": Color("#2e0854"),
		"light": Color("#ffe600")
	},
	"caruaru": {
		"id": "caruaru",
		"name": "Barro de Caruaru",
		"dark": Color("#381a0e"),
		"light": Color("#e3c7b1")
	},
	"dende": {
		"id": "dende",
		"name": "Azeite de Dendê",
		"dark": Color("#a22c16"),
		"light": Color("#fee68d")
	}
}

var preset_order: Array[String] = [
	"cangaco",
	"xilogravura",
	"mandacaru",
	"sol_de_rachar",
	"palma",
	"poeira",
	"flor_mandacaru",
	"acerola",
	"velho_chico",
	"praia",
	"lencois",
	"rapadura",
	"frevo",
	"caruaru",
	"dende"
]

var current_preset_id: String = "cangaco"
var current_dark: Color = Color("#85472e")
var current_light: Color = Color("#f9dcba")
var current_palette_name: String = "Cangaço"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_saved_palette()

## Altera programaticamente as duas cores (dark e light)
func set_colors(dark: Color, light: Color, custom_name: String = "Custom") -> void:
	current_dark = dark
	current_light = light
	current_palette_name = custom_name
	current_preset_id = "custom"
	palette_changed.emit(current_dark, current_light)
	_save_current_palette()

## Aplica um preset cadastrado pelo ID (com suporte a aliases legados)
func set_palette(preset_id: String) -> bool:
	if LEGACY_ALIASES.has(preset_id):
		preset_id = LEGACY_ALIASES[preset_id]

	if not presets.has(preset_id):
		push_warning("[PaletteManager] Preset não encontrado: %s" % preset_id)
		return false

	var data: Dictionary = presets[preset_id]
	current_preset_id = preset_id
	current_palette_name = data["name"]
	current_dark = data["dark"]
	current_light = data["light"]

	palette_changed.emit(current_dark, current_light)
	_save_current_palette()
	return true

## Avança ciclicamente para a próxima paleta cadastrada
func next_palette() -> String:
	var idx := preset_order.find(current_preset_id)
	var next_idx := (idx + 1) % preset_order.size() if idx != -1 else 0
	var next_id := preset_order[next_idx]
	set_palette(next_id)
	return next_id

## Retorna os dados da paleta atual
func get_current_palette() -> Dictionary:
	return {
		"id": current_preset_id,
		"name": current_palette_name,
		"dark": current_dark,
		"light": current_light
	}

## Retorna a lista de todos os presets disponíveis
func get_presets() -> Dictionary:
	return presets

## Cadastra um novo preset em tempo de execução
func register_preset(id: String, preset_name: String, dark: Color, light: Color) -> void:
	presets[id] = {
		"id": id,
		"name": preset_name,
		"dark": dark,
		"light": light
	}
	if not preset_order.has(id):
		preset_order.append(id)

func _save_current_palette() -> void:
	var data := {
		"preset_id": current_preset_id,
		"name": current_palette_name,
		"dark": current_dark.to_html(false),
		"light": current_light.to_html(false)
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_saved_palette() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		set_palette("cangaco")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		set_palette("cangaco")
		return

	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		var pid: String = parsed.get("preset_id", "cangaco")
		if LEGACY_ALIASES.has(pid):
			pid = LEGACY_ALIASES[pid]
		if presets.has(pid):
			set_palette(pid)
		elif parsed.has("dark") and parsed.has("light"):
			var d := Color(parsed["dark"])
			var l := Color(parsed["light"])
			var n: String = parsed.get("name", "Custom")
			set_colors(d, l, n)
		else:
			set_palette("cangaco")
	else:
		set_palette("cangaco")
