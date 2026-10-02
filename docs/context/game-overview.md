# Game Overview

Preencha este arquivo com os quatro eixos estruturais do projeto (Ritmo, Unidade de jogo, Controle, Fim) e outras decisões de fundação.

- Ritmo: ação em tempo real, com combates curtos e repetição de encontros em sequência
- Unidade de jogo: partida/trecho de exploração + combate contra criaturas do folclore
- Controle: direto sobre um avatar principal, com movimentação, ataque e esquiva em tempo real
- Fim: tem fim definido, com progressão narrativa e derrotas sucessivas de criaturas para revelar a história
- Plataforma: beat ?em up 2D de rolagem lateral, com movimento horizontal e em profundidade na arena, para facilitar a leitura do espaço, o posicionamento do jogador e a reação aos inimigos com comportamentos distintos
- Visão: perspectiva lateral com câmera fixa/seguimento discreto para manter o campo de ação legível
- Justificativa da escolha: 2D lateral maximiza a percepção do comportamento dos inimigos, favorece a leitura do ataque e da esquiva e reforça o ritmo de combate rápido inspirado em God of War e Hades.

<!-- A S0 depende deste documento. -->

- Inspira??es: God of War, Hades, Dark Souls, TMNT cl?ssicos e TMNT: Shredder?s Revenge.
- Combate atual: ataque a cada 1s; dano por contato a cada 0,7s; rolada de 120px em 0,22s, invulner?vel durante a execu??o, com cooldown de 0,8s.

- Travessia: rua de 3800px com dois buracos sinalizados; o jogador precisa pular para continuar. Cair causa morte imediata e mostra a tela de derrota, com op??o de reiniciar a fase.
