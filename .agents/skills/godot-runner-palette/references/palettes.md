# Catálogo de Paletas e Teoria de Renderização Duotone

Este documento detalha o sistema de cores do **Corre Calango**, a teoria matemática da interpolação de luminância e um catálogo de paletas recomendadas para runners 2D estilo 1-bit.

---

## 1. Princípio da Renderização Duotone (1-bit com Pós-processamento)

Todos os sprites e camadas de fundo do jogo são originalmente desenhados em **preto e branco puro** com transparência:
- `rgb(0, 0, 0)`: Fundo / espaço vazio.
- `rgb(255, 255, 255)`: Silhuetas de sprites (jogador, cactos, sol, lua, montanhas, chão, fogueiras).
- Valores intermediários (`0.0 < rgb < 1.0`): Bordas com antialiasing ou efeitos de transparência/profundidade (como montanhas distantes).

O shader fullscreen (`scenes/effects/day_night_cycle.gd`) lê a tela como uma textura (`hint_screen_texture`) e faz a conversão direta:

```glsl
vec4 screen_color = texture(screen_texture, SCREEN_UV);

// Dia: invert_progress = 1.0 -> Fundo claro (color_light), Elementos escuros (color_dark)
vec3 day_color = mix(color_light.rgb, color_dark.rgb, screen_color.r);

// Noite: invert_progress = 0.0 -> Fundo escuro (color_dark), Elementos claros (color_light)
vec3 night_color = mix(color_dark.rgb, color_light.rgb, screen_color.r);

// Transição suave entre dia e noite
COLOR = vec4(mix(night_color, day_color, invert_progress), screen_color.a);
```

### Vantagens Desta Arquitetura:
1. **Propagação Instantânea**: Alterar `color_dark` e `color_light` modifica 100% dos visuais do jogo em tempo real sem precisar re-importar texturas nem alterar materiais individuais de cada nó.
2. **Zero Sobrecarga de Draw Calls**: Um único passe fullscreen no CanvasLayer layer 10 consome custo de GPU desprezível em qualquer dispositivo mobile ou desktop.
3. **Preservação do Ciclo Dia/Noite**: A transição suave dia/noite continua funcionando automaticamente em qualquer paleta de cores.

---

## 2. Catálogo de Paletas Nordestinas Curadas

| ID | Nome | Dark (Hex) | Light (Hex) | Razão de Contraste | Sensação / Temática Nordestina |
|---|---|---|---|---|---|
| `cangaco` | Cangaço | `#85472e` | `#f9dcba` | 5.2:1 | Couro do vaqueiro, cangaço e sol ardente do agreste |
| `xilogravura` | Xilogravura | `#1A1A1A` | `#F5F5F5` | 16.4:1 | Preto no branco clássico da xilogravura e livretos de cordel |
| `mandacaru` | Mandacaru | `#0F380F` | `#8BAC0F` | 4.8:1 | Verde cacto do mandacaru que floresce na seca |
| `sol_de_rachar` | Sol de Rachar | `#120C02` | `#FFB000` | 11.2:1 | Âmbar reluzente do sol forte do meio-dia no sertão |
| `palma` | Palma & Juazeiro | `#051405` | `#00FF41` | 13.5:1 | Verde vivo e resistente da palma forrageira e do juazeiro |
| `poeira` | Poeira da Estrada | `#2B1D0C` | `#E8D8B8` | 9.8:1 | Barro seco, chão batido e poeira de vaquejada |
| `flor_mandacaru` | Flor de Mandacaru | `#282A36` | `#FF79C6` | 7.1:1 | Rosa magenta da flor noturna do cacto e festa junina |
| `acerola` | Acerola do Sertão | `#1A0000` | `#FF3333` | 5.9:1 | Vermelho vibrante da acerola cultivada nos polos irrigados do sertão |
| `velho_chico` | Velho Chico | `#002B36` | `#93A1A1` | 7.5:1 | Águas profundas do Rio São Francisco e luar sobre a caatinga |
| `praia` | Praias do Nordeste | `#0C3B5E` | `#FCE4B8` | 6.8:1 | Azul marinho dos arrecifes e areia dourada das praias nordestinas |
| `lencois` | Lençóis Maranhenses | `#05445E` | `#E4F1F4` | 7.5:1 | Lagoas cristalinas turquesa e dunas de areia alva de quartzo |
| `rapadura` | Engenho & Rapadura | `#3B1808` | `#FEC84D` | 7.2:1 | Marrom escuro da rapadura artesanal e amarelo dourado do melaço de cana |
| `frevo` | Frevo & Olinda | `#2E0854` | `#FFE600` | 9.6:1 | Roxo profundo dos estandartes e amarelo elétrico das sombrinhas de frevo |
| `caruaru` | Barro de Caruaru | `#381A0E` | `#E3C7B1` | 6.4:1 | Terracota escura e argila crua da arte figurativa de Mestre Vitalino |
| `dende` | Azeite de Dendê | `#260801` | `#FF7B25` | 6.8:1 | Marrom profundo da panela de barro e laranja reluzente do azeite de dendê |

---

## 3. Guia de Criação de Novas Paletas

Ao criar um novo par de cores para o jogo, siga estas diretrizes:
1. **Contraste Mínimo Recomendado**: Garanta que o contraste entre `dark` e `light` seja no mínimo de **4.5:1** (padrão WCAG AA), para que os obstáculos permaneçam nítidos em alta velocidade (`game_speed > 600`).
2. **Luminância Relativa**: A cor `dark` deve possuir luminância significativamente menor que a cor `light`.
3. **Saturação**: Evite cores ultra saturadas e conflitantes que possam causar cansaço visual rápido.
