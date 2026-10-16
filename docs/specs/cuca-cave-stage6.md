# Fase 6 — interior da caverna da Cuca

Incremento de 2026-10-16: percurso jogável de três trechos em `teste/caverna6.tscn`, usando os sprites fornecidos em `sprites/cenario/Fases6/`. Mantém movimentação, combate, salto, esquiva, HUD, pausa e derrota existentes.

## Percurso

| Trecho | Entrada | Encontro | Continuação |
| --- | --- | --- | --- |
| 1 | `(180, 450)` | Três inimigos comuns e duas estalactites instáveis. | Após vencer o grupo, avanço contínuo até `x=1500`. |
| 2 | `x=1500` | Três inimigos e duas estalactites instáveis. | Vencer libera o único buraco, em `x=2700–2810`, atravessando toda a profundidade do caminho. |
| 3 | `x=2940`, após aterrissar | Quatro inimigos e duas estalactites instáveis. | Após o combate, caminhar até `x=4200` inicia a apresentação e a bossfight da Cuca no laboratório. |

O mapa tem 5200 pixels, incluindo o laboratório no final do terceiro trecho. Cada encontro permanece fechado até a derrota de seus inimigos. O seguinte só começa ao alcançar sua entrada em terra firme. O salto normal atravessa o buraco entre os trechos 2 e 3; caminhar ou rolar sobre ele causa queda e morte.

## Apresentação

- `background.png`: parede da caverna em parallax, com profundidade fria e escura.
- `chão.png`: caminho rochoso fixo, independente do movimento do fundo.
- As tochas e suas luzes foram retiradas do mapa. A iluminação ambiente é suave e uniforme para preservar a leitura dos inimigos e do chão dentro da caverna escura.
- `estalactite.png`: rochas penduradas, rachadura, queda e estilhaçamento, recortados do sheet sem alterar a arte original.

Uma modulação ambiente escurece o mundo, preservando o HUD em seu próprio CanvasLayer. Névoa baixa e poeira mineral completam a caverna. A trilha reutiliza `Fase3.mp3`, em volume reduzido. A pausa congela a poeira e as armadilhas.

## Estalactites

Há doze no teto: seis decorativas e seis instáveis, duas por trecho. As rochas são menores e suas bases ficam acima da borda visível, presas ao teto. As instáveis são ativadas ao passar diretamente embaixo delas no trecho ativo. O ponto de impacto captura a profundidade atual do jogador, em qualquer parte da faixa caminhável, e fica fixo durante o aviso e a queda. O aviso de 0,85 segundo mostra rachadura, tremor, poeira e uma marca nesse local. A rocha então cai com aceleração, atinge o chão e se quebra em uma animação com detritos e som.

O impacto real contra o corpo tira **50% da vida máxima**: 5 dos 10 pontos atuais. A queda verifica todo o caminho percorrido pelo sprite para evitar atravessar o personagem em frames lentos. O jogador pode sair lateralmente, mudar de profundidade ou usar a invulnerabilidade da esquiva. Cada rocha tenta causar dano uma única vez; os fragmentos no chão e as rochas decorativas são inofensivos. A armadilha pode matar caso a vida restante seja insuficiente, abrindo a tela de derrota normal.

## Campanha e checkpoints

A caminhada de entrada da fase 5 conclui a floresta e carrega a caverna diretamente. A fase 6 fica disponível no mapa após a fase 5. Os checkpoints `start`, `trecho_2` e `trecho_3` restauram a vida e o encontro atual, removem os grupos anteriores e reiniciam as armadilhas. O terceiro fica em segurança depois do buraco. O checkpoint `boss` antecede a apresentação da Cuca e reinicia apenas a luta, preservando os três grupos da travessia já vencidos.

O laboratório e o combate estão implementados conforme [cuca-boss-fight.md](cuca-boss-fight.md). A cutscene final do ritual será fornecida pelo usuário depois da mecânica. Até lá, a derrota da Cuca mantém o checkpoint da luta e oferece tentar novamente ou voltar ao mapa. A fase 6 não é concluída na campanha e a fase 7 permanece bloqueada até implementar a continuidade narrativa de [cuca-stages.md](cuca-stages.md).

## Verificação

`teste/cuca_cave_checks.gd` cobre desbloqueio, três encontros, portões, salto com input, mortes por caminhada e rolada no buraco, retomada dos checkpoints, ausência de tochas/luzes locais, ambiente e parallax, teto, ativação nas diferentes profundidades, alvo fixo, pausa, dano de 50%, esquiva do impacto por posição, colisão em frames lentos, morte por estalactite e encerramento sem falsa conclusão da campanha. `cuca_cave_preview.gd` renderiza os três trechos, buraco, teto, aviso, queda e estilhaçamento em `teste/.validation/cave6-ceiling-previews/`. Os checks de campanha e floresta cobrem a ligação entre as duas fases. Todos usam APPDATA isolado para preservar o save real.
