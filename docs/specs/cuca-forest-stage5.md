# Fase 5 — floresta até a caverna

Implementação de 2026-10-15, a partir da direção em [cuca-stages.md](cuca-stages.md) e do pedido de três trechos com um buraco entre o primeiro e o segundo. A cena é `teste/floresta5.tscn`; os controles, combate, vida, esquiva, queda e pausa usam os sistemas existentes.

## Percurso jogável

| Trecho | Entrada | Encontro | Saída |
| --- | --- | --- | --- |
| 1 | Início em `(180, 450)` | Três inimigos existentes e uma onça em emboscada; arena termina em `x=1120` enquanto há inimigos vivos. | O combate abre o caminho até o segundo trecho. O único buraco ocupa `x=1200–1310`, em toda a profundidade do caminho. |
| 2 | `x=1420`, depois de aterrissar após o salto | Três inimigos; checkpoint após o buraco. | Derrotar o grupo abre a continuação sem outro buraco. |
| 3 | `x=2780` | Quatro inimigos existentes e uma onça em emboscada, com checkpoint próprio. | Após limpar a área, o protagonista segue até a entrada da caverna. |

O mapa se estende por 4400 pixels. O salto normal permite atravessar o buraco; caminhar ou rolar por ele causa a mesma queda e morte das fases anteriores. Encontros posteriores só começam ao chegar às suas entradas e concluir o grupo anterior. O último inimigo abre o acesso à caverna, sem concluir a fase automaticamente.

Cinco moitas se repetem no percurso, todas com a base em `y=420`, junto à borda superior do chão. Duas delas são ocupadas por onças nos trechos 1 e 3. A emboscada, a disputa indicada por um único botão K animado e os ataques próprios estão descritos em [stage5-jaguar.md](stage5-jaguar.md).

## Cenário

Os três sprites fornecidos são usados diretamente, sem substituir a arte:

- `sprites/cenario/Fase5/background.png`: floresta densa, árvores grandes, cipós, ruínas e profundidade azulada, com parallax discreto.
- `sprites/cenario/Fase5/cha.png`: chão de terra e pedras cobertas de musgo, raízes e vegetação nas bordas.
- `sprites/cenario/Fase5/entrada caverna.png`: formação rochosa com raízes e abertura escura, posicionada à direita no final do percurso, seguindo a composição da referência.

O cenário usa repetição espelhada para reduzir emendas, filtragem nearest para preservar os pixels e cores gradualmente mais frias em direção à caverna. Névoa fina, vagalumes, folhas lentas e som ambiente completam a apresentação sem encobrir o combate. A trilha reutiliza `Fase1.mp3` enquanto não há música própria para essa fase.

A caverna começa em `(3960, 260)` na escala `0.3`, com a porta em `(4260, 467)`. A câmera e o chão mantêm a escala do gameplay existente.

## Entrada e conclusão

Depois de derrotar todos os inimigos do trecho 3, incluindo a onça, o protagonista inicia a entrada automática ao alcançar `x=3700`, em terra firme na faixa de caminhada, quando a formação rochosa já aparece à direita. Os controles são suspensos e o HUD se oculta. O personagem contorna as pedras por baixo, passando por `(3930, 535)`, `(4200, 530)` e `(4255, 490)`, com velocidade de 180 pixels por segundo. A câmera se desloca suavemente para mostrar a abertura. Em seguida, ele vira para a porta em `(4260, 467)` e desaparece no interior, antes do escurecimento da tela e do áudio.

O checkpoint `caverna` é salvo a partir de `x=3580`. Ao retomá-lo, o jogador reaparece antes do gatilho, inclusive ao carregar saves antigos que estavam mais próximos da porta. Saltar pela região aguarda o pouso antes de iniciar a cena.

Somente ao terminar essa caminhada a fase 5 é marcada como concluída e o jogo carrega diretamente `caverna6.tscn`, liberando a fase 6 no mapa. O percurso inicial da caverna está descrito em [cuca-cave-stage6.md](cuca-cave-stage6.md). A fase 5 aparece no mapa como Floresta da Cuca e é liberada após concluir a Iara.

## Checkpoints e verificação

Os checkpoints são `start`, `trecho_2`, `trecho_3` e `caverna`. Reiniciar mantém a fase e o trecho alcançado, restaura a vida e não repete os encontros já vencidos. O checkpoint do segundo trecho fica após o buraco.

`cuca_forest_checks.gd` verifica os três encontros, portões, salto real com input, queda ao andar/rolar, reinícios nos quatro checkpoints, HUD, pausa e conclusão pela entrada física, seguida do carregamento da fase 6. `cuca_forest_preview.gd` captura os três trechos, buraco, composição da caverna e caminhada de entrada em `teste/.validation/stage5-previews/`. As verificações de campanha cobrem o desbloqueio da fase 6 após concluir a floresta; Rio Negro e Iara verificam que ela permanece bloqueada antes disso.

Todos os scripts de validação usam APPDATA isolado, preservando o progresso real do jogador.
