# Workflow: Esteira de Ingestão de Assets (Asset Ingestion Pipeline)

Este workflow descreve o processo padronizado para incorporar novos arquivos visuais ou sonoros adicionados à pasta `assets/`.

---

## Árvore de Decisão: O que é o novo asset?

```
Novo Asset na pasta assets/
         │
         ├─── Formato de Imagem (.png, .svg)
         │       │
         │       ├── É decorativo (não afeta o jogador)?
         │       │     └── Chamar Skill `godot-runner-scenery`:
         │       │           node .agents/skills/godot-runner-scenery/scripts/add_decoration.js ...
         │       │
         │       ├── É um perigo/obstáculo que causa dano?
         │       │     └── Chamar Skill `godot-runner-obstacles`:
         │       │           node .agents/skills/godot-runner-obstacles/scripts/add_obstacle.js ...
         │       │
         │       └── É parte do Calango ou UI?
         │             └── Atualizar Spritesheet do Player ou Nós da UI em scenes/ui/
         │
         └─── Formato de Áudio (.ogg, .wav, .mp3)
                 └── Chamar Skill `godot-audio-sfx` (registrar no AudioManager)
```

---

## Passos de Execução

### Passo 1: Inspeção do Arquivo
Identifique as dimensões do arquivo (px) e sua proporção em relação ao calango (~80px de altura aparente).

### Passo 2: Execução da Ferramenta Adequada
Use a ferramenta CLI da skill apropriada. Exemplos:
- Se for elemento de solo cenográfico:
  ```bash
  node .agents/skills/godot-runner-scenery/scripts/add_decoration.js --asset assets/novo_elemento.png --type ground
  ```
- Se for um novo obstáculo perigoso:
  ```bash
  node .agents/skills/godot-runner-obstacles/scripts/add_obstacle.js --asset assets/novo_perigo.png --type ground --height 90
  ```

### Passo 3: Verificação de Compilação
Sempre execute o teste rápido do Godot para certificar que nenhum erro foi introduzido:
```powershell
& "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless scenes/main/main.tscn -- --test
```
