# Onça-pintada — emboscadas na fase 5

Mecânica acrescentada à [Floresta da Cuca](cuca-forest-stage5.md) em 2026-10-16, conforme a direção do usuário. O percurso mantém os três trechos e o buraco entre os dois primeiros; a onça introduz uma surpresa seguida de combate próprio.

## Moitas e emboscada

Há cinco moitas distribuídas pelo percurso, em `x=520`, `950`, `1840`, `3060` e `3490`. Todas apoiam a base em `y=420`, junto à borda superior do chão, integradas à vegetação do cenário. Duas escondem onças: uma no primeiro trecho e outra no terceiro. As três restantes usam a mesma vegetação, sem gerar inimigos. Uma onça só fica ativa no seu encontro; derrotar o grupo anterior continua necessário para avançar.

Ao se aproximar de uma moita ocupada, o jogador vê a vegetação se mexer e o rosto aparecer antes do salto. A onça emerge sozinha e salta em arco para derrubá-lo. O alcance de 165 pixels em profundidade permite que o bote parta da borda do caminho e alcance o jogador na faixa de caminhada. Essa emboscada acontece uma vez por onça e seu primeiro bote sempre alcança o jogador: acompanha o deslocamento durante o arco, mesmo se ele correr, mudar de faixa, saltar ou esquivar. Durante esse primeiro bote, a onça não recebe dano e a aterrissagem inicia a disputa de K, encerrando o salto ou a esquiva do protagonista. Morte, queda no buraco, controles bloqueados por outro evento ou encerramento da fase impedem a disputa de interromper esses estados. Seus saltos posteriores permanecem evitáveis, têm destino fixo e não reiniciam o evento de apertar K.

## Disputa no chão

Após a aterrissagem da emboscada, a composição mostra o protagonista deitado, segurando e empurrando a onça pelo pescoço. O jogador precisa dar **12 toques em K em até 8 segundos** para afastá-la. Cada pressionamento novo conta uma vez; manter K segurado ou receber a repetição automática do teclado não aumenta o progresso.

Um único botão grande de **K**, sem card, barra ou texto adicional, indica a ação. Ele se move para incentivar os toques e alterna entre as texturas normal e pressionada. A cada pressionamento válido, abaixa cerca de 12 pixels e se comprime, retornando à posição de repouso ao soltar a tecla. A intensidade da animação do botão e a pose de esforço dos personagens acompanham o avanço da disputa. A movimentação e os ataques comuns ficam temporariamente bloqueados.

A câmera aproxima a disputa, com tremor intenso e pequenas rotações. Cada toque válido de K acrescenta um impulso imediato ao tremor para reforçar o impacto do empurrão. Outras teclas, a repetição automática e manter K segurado não geram novos impulsos nem avançam a disputa. A composição dos personagens se movimenta com o esforço, enquanto folhas, poeira e efeitos de impacto acompanham a ação. O botão permanece legível, independentemente do tremor do mundo.

Ao completar os 12 toques, o protagonista empurra a onça para trás e recupera o controle. Se o tempo acabar, ele recebe **2 pontos de dano pelo sistema normal de dano** e também se solta; a luta continua caso sobreviva. O evento não reduz os 5 pontos de vida da onça automaticamente.

Pausar congela o cronômetro, a animação, os efeitos e a câmera. Sucesso, tempo esgotado, morte ou saída da cena restauram o controle, a visibilidade do protagonista, o HUD e a câmera anterior, sem manter bloqueios da disputa.

## Combate depois do empurrão

A onça tem **5 pontos de vida**. Ela persegue o protagonista no plano do chão e alterna entre três ataques, todos com preparação visível, compromisso de direção e intervalo de recuperação:

| Ataque | Preparação | Ação |
| --- | --- | --- |
| Patada | Cerca de 0,42 s; ergue a parte dianteira para preparar a pata. | Golpe curto com o efeito de garra da própria arte. |
| Mordida | Cerca de 0,53 s; abaixa a cabeça e prepara a investida. | Avanço curto em direção ao jogador. |
| Salto | Cerca de 0,62 s; agacha e recua antes de se lançar. | Arco mais longo até a posição escolhida para a aterrissagem. |

Os golpes causam 1 ponto de dano e respeitam esquiva, invulnerabilidade e altura do salto do protagonista. Encostar no corpo da onça não causa dano contínuo. As janelas de recuperação permitem contra-atacar; a direção anunciada evita que ela vire instantaneamente durante um golpe.

## Percurso e checkpoints

As onças fazem parte das listas de inimigos dos trechos 1 e 3. Uma onça escondida ainda viva mantém o encontro aberto; vencer somente os outros inimigos não libera a passagem. O segundo trecho mantém o encontro anterior, sem uma terceira onça.

Os checkpoints seguem a ordem `start`, `trecho_2`, `trecho_3` e `caverna`. Retomar um trecho não repete onças de encontros já concluídos. A onça do trecho atual recomeça em sua moita, permitindo uma nova tentativa completa após morrer. A disputa não cria um checkpoint intermediário.

A entrada automática da caverna continua em `x=3700`, depois de concluir todo o último encontro, incluindo sua onça. O checkpoint `caverna` preserva essa conclusão; a aproximação, a caminhada e o encerramento da fase permanecem sob o mesmo fluxo.

## Arte e verificação

`sprites/Personagens/sprite sheet onça.png` fornece as moitas, a revelação, a emergência, o salto, a locomoção, a patada, a mordida, a queda e a composição da disputa. `JaguarFrames.gd` recorta os quadros com transparência, mantém uma escala constante e alinha os pés em um canvas comum. O recurso de quadros é compartilhado em cache por tamanho; cada ator controla sua própria reprodução.

`sprites/hud/Ícones Pixelados de Teclas K.png` fornece as duas versões do botão. `JaguarMashPrompt.gd` remove em memória apenas o fundo preto externo da imagem, preserva os detalhes internos e compartilha as texturas processadas. Os arquivos de arte originais não são modificados.

`jaguar_checks.gd` cobre a distribuição das moitas, o primeiro bote seguindo corrida, esquiva e salto sem teletransporte, a proteção de estados de morte/queda/outros eventos, os pressionamentos de K, o desfecho da disputa, os ataques normais evitáveis, a pausa, a restauração do estado e a progressão. `jaguar_preview.gd` produz capturas da apresentação usando APPDATA isolado, sem alterar o progresso real do jogador.
