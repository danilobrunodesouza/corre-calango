# Regra de Tipagem Estática e Arquitetura GDScript 4

Esta regra define os padrões inegociáveis de código para o projeto **Corre Calango**. Todos os agentes que gerarem ou modificarem código GDScript devem seguir estas diretrizes.

---

## 1. Tipagem Estática Obrigatória

Todas as declarações de variáveis, constantes, parâmetros de funções e valores de retorno devem ter tipagem estática explícita:

```gdscript
# CORRETO:
var speed: float = 300.0
var items: Array[Node2D] = []
func calculate_jump_velocity(gravity: float, height: float) -> float:
    return -sqrt(2.0 * gravity * height)

# INCORRETO:
var speed = 300.0
var items = []
func calculate_jump_velocity(gravity, height):
    return -sqrt(2.0 * gravity * height)
```

Use inferência estática (`:=`) apenas quando o tipo for 100% evidente a partir do lado direito:
```gdscript
var rect := RectangleShape2D.new() # OK
var speed := 300.0                # OK
```

---

## 2. Preload vs ClassName em Cenas e Scripts

Para garantir que execuções headless no terminal, compilações automáticas de testes e exportações funcionem sem depender do arquivo `.godot/global_script_class_cache.cfg`:

1. Sempre use `const CustomScript = preload("res://caminho/do/script.gd")` ao instanciar nós customizados.
2. Em anotações de tipo de variáveis membro que referenciam outros nós customizados, prefira tipos nativos do Godot (`Node2D`, `Node`, `CanvasLayer`, `CharacterBody2D`) em vez do identificador de `class_name` não-nativo, garantindo ausência de erros de ciclo de carregamento.

---

## 3. Comunicação Entre Nós: "Call Down, Signal Up"

- **Nós Pai chamam métodos diretamente em seus filhos** (`player.take_damage()`).
- **Nós Filhos emitem sinais para seus pais** (`signal died`).
- **Comunicação desacoplada entre sistemas distantes** (ex: HUD, Áudio, Ciclo Dia/Noite, Game Over): deve passar exclusivamente pelo singleton `EventBus` (`EventBus.player_died.emit()`) ou `GameManager`.
- **Nunca use caminhos absolutos no `get_node()`** (ex: `get_node("/root/Main/World/Player")`), pois isso quebra testes unitários isolados.
