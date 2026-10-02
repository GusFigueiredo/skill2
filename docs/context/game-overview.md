# Game Overview

Preencha este arquivo com os quatro eixos estruturais do projeto (Ritmo, Unidade de jogo, Controle, Fim) e outras decisões de fundação.

- Ritmo: ação em tempo real, com combates curtos e repetição de encontros em sequência
- Unidade de jogo: partida/trecho de exploração + combate contra criaturas do folclore
- Controle: direto sobre um avatar principal, com movimentação, ataque e esquiva em tempo real
- Fim: tem fim definido, com progressão narrativa e derrotas sucessivas de criaturas para revelar a história
- Plataforma: beat ?em up 2D de rolagem lateral, com movimento horizontal e em profundidade na arena, para facilitar a leitura do espaço, o posicionamento do jogador e a reação aos inimigos com comportamentos distintos
- Visão: perspectiva lateral com câmera fixa/seguimento discreto para manter o campo de ação legível
- Justificativa da escolha: 2D lateral maximiza a percepção do comportamento dos inimigos, favorece a leitura do ataque e da esquiva e reforça o ritmo de combate rápido inspirado em God of War e Hades.

## Estrutura narrativa planejada

A campanha está planejada para ter pelo menos 7 fases, agrupadas em 4 mapas/regiões. A estrutura atual prevê estas sete fases; novos trechos podem ser acrescentados durante o desenvolvimento.

| Mapa/região | Fase | Conteúdo planejado |
| --- | --- | --- |
| Floresta da Ratanaba | 1 | Tutorial de combate na cidade perdida de Ratanaba. Ensina os controles e as mecânicas básicas. |
| Floresta da Ratanaba | 2 | Trecho pela floresta amazônica e boss fight tutorial contra a Boitatá. Ela ataca por acreditar que o protagonista é um inimigo; ao ser derrotada, percebe que ele é do bem e explica o que Cuca e Iara estão fazendo no mundo. |
| Rio Negro | 3 | Avanço para a direita enfrentando uma única onda de inimigos. |
| Rio Negro | 4 | Boss fight contra a Iara. Durante a luta, ela prende o protagonista e começa a afogá-lo; a Vitória Régia intervém para ajudar a derrotá-la, entrega um item ainda sem nome e revela a localização da Cuca. |
| Caverna da Cuca | 5 | Uma onda de inimigos durante o avanço para a direita; conforme o jogador progride, o cenário transiciona para o laboratório rústico de poções da Cuca. |
| Caverna da Cuca | 6 | Boss fight contra a Cuca, que está realizando um ritual para invocar o Corpo Seco. Ao derrotá-la, o ritual é interrompido; o Corpo Seco deixa a caverna e segue para a floresta. |
| Floresta Amazônica | 7 | O jogador atravessa uma onda de inimigos até alcançar o Corpo Seco. A derrota dele encerra o jogo. |

Esta é a direção narrativa planejada, não uma declaração de que as sete fases já estão implementadas. O primeiro incremento jogável continua sendo um protótipo de combate e progressão.

<!-- A S0 depende deste documento. -->

- Inspira??es: God of War, Hades, Dark Souls, TMNT cl?ssicos e TMNT: Shredder?s Revenge.
- Combate atual: ataque a cada 1s; dano por contato a cada 0,7s; rolada de 120px em 0,22s, invulner?vel durante a execu??o, com cooldown de 0,8s.

- Travessia: rua de 3800px com dois buracos sinalizados; o jogador precisa pular para continuar. Cair causa morte imediata e mostra a tela de derrota, com op??o de reiniciar a fase.
