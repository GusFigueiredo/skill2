# Caminho até a Cuca — fases 5 e 6

Direção narrativa definida pelo usuário em 2026-10-15. A fase 5 está implementada em `teste/floresta5.tscn`, com três trechos e um buraco entre o primeiro e o segundo, conforme [cuca-forest-stage5.md](cuca-forest-stage5.md). A fase 6 possui percurso de três trechos, estalactites no teto e bossfight no laboratório em `teste/caverna6.tscn`, conforme [cuca-cave-stage6.md](cuca-cave-stage6.md) e [cuca-boss-fight.md](cuca-boss-fight.md). A cutscene final do ritual aguarda o roteiro do usuário. As tochas foram retiradas por solicitação posterior. Esta direção atualiza a distribuição dos cenários e o resultado do ritual descritos anteriormente em `game-overview.md`.

## Fase 5 — floresta até a caverna

- A fase acontece na floresta, depois dos acontecimentos do Rio Negro.
- O protagonista segue em direção ao esconderijo da Cuca indicado pela Vitória-Régia.
- A entrada da caverna aparece no final da fase e estabelece o destino da fase seguinte.
- O laboratório fica para a fase 6.

## Fase 6 — caverna e laboratório

- A fase acontece dentro da caverna da Cuca.
- No final do percurso, o jogador encontra o laboratório de poções, onde a Cuca prepara a ressurreição do Corpo Seco.
- A luta contra a Cuca acontece no laboratório. O objetivo narrativo do protagonista é impedi-la de concluir o ritual.
- O protagonista derrota a Cuca, mas ela consegue realizar o ritual mesmo derrotada. O Corpo Seco é ressuscitado.
- A sequência final estabelece a perseguição ao Corpo Seco, que leva à fase 7, na floresta, conforme o destino já planejado para o confronto final.

## Continuidade

A vitória sobre a Cuca e o sucesso do ritual são dois acontecimentos distintos: derrotá-la conclui a luta da fase 6, mas não impede a ressurreição. Diálogos, cutscene de encerramento e transição para a fase 7 devem deixar essa relação clara.

A região antes chamada Caverna da Cuca passa a incluir sua aproximação externa pela floresta na fase 5 e o interior da caverna na fase 6. O nome definitivo dessa região no mapa pode ser ajustado junto da implementação.

## Detalhamento pendente

- Encenação da derrota, conclusão do ritual e saída do Corpo Seco.
- Roteiro da cutscene final a ser enviado pelo usuário após a mecânica da bossfight.
- Transição da ressurreição para a fase 7.

O pedido de 2026-10-16 acrescenta as estalactites com dano de metade da vida máxima e o buraco entre os trechos 2 e 3. A revisão seguinte remove as tochas e prende as armadilhas no topo, fazendo-as cair na profundidade em que o jogador passar. A bossfight aprovada usa caveiras rebatidas com K, sobrecarga do caldeirão, poças, ondas e quedas do teto em três momentos. O ritual final permanece para o roteiro posterior do usuário.
