# Workflow: Export Web & Playtest no Navegador

Este workflow descreve o procedimento passo a passo para gerar o pacote Web (HTML5) do **Corre Calango** e testá-lo em um navegador local com touch/desktop.

---

## Pré-Requisitos

- Godot Console Executable: `C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe`
- Node.js instalado (para servir os arquivos estáticos)
- Pasta de destino: `export/web/`

---

## Passos do Workflow

### Passo 1: Executar Testes Automatizados Headless
Antes de qualquer export, garanta que a suíte de testes passa 100%:
```powershell
& "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless scenes/main/main.tscn -- --test
```
*Critério de Sucesso*: A saída deve conter `--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---` com código de saída `0`.

---

### Passo 2: Exportar para Web
Crie o diretório de export caso não exista e dispare a exportação oficial:
```powershell
New-Item -ItemType Directory -Force -Path "export\web"
& "C:\Users\notebook\develop\Godot\Godot_v4.6-stable_win64_console.exe" --headless --export-release "Web" export\web\index.html
```
*Validação*: Verifique que os arquivos `index.html`, `index.js`, `index.wasm` e `index.pck` foram gerados na pasta `export/web/`.

---

### Passo 3: Iniciar Servidor HTTP Local
Aplicações WebAssembly não podem ser abertas diretamente como `file:///` devido a políticas CORS do navegador. Inicie um servidor local:
```powershell
npx -y serve export/web -l 8080
```

---

### Passo 4: Playtest e Inspeção Visual
1. Acesse `http://localhost:8080` no navegador (ou use o `browser_subagent`).
2. Teste os controles:
   - Barra de Espaço ou Seta Cima / W: Pulo
   - Seta Baixo / S: Agachar
   - Toque / Clique na tela: Iniciar e Pular
3. Verifique se o FPS se mantém cravado em 60 FPS e se o ciclo dia/noite transita suavemente.
