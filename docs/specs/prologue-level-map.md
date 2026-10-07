# Spec: Prólogo e mapa de fases

## Objetivo

Introduzir a campanha de Pindorama com uma cutscene curta e apresentar suas sete fases em um mapa de regiões florestais.

## Direção aprovada para este incremento

- O fluxo inicial é menu → prólogo → mapa → fase selecionada.
- O prólogo apresenta a investigação do historiador nas ruínas de Ratanabá, os primeiros artefatos encontrados, a passagem para o passado e a ameaça do Corpo Seco.
- Cada momento do prólogo é uma cena ilustrada e animada, com caminhada, descoberta, travessia temporal, combate contra inimigo comum e revelação da ameaça.
- As cenas avançam automaticamente e também podem ser aceleradas por entrada do jogador; pular leva diretamente ao mapa.
- A implementação usa animações e cenários já presentes no projeto, sem depender de novos assets.
- O mapa contém sete etapas, seguindo a ordem narrativa já descrita em `game-overview.md`.
- Somente Ratanabá fica jogável neste incremento. As outras seis etapas aparecem bloqueadas.
- A etapa disponível leva ao protótipo jogável atual. A separação da fase tutorial e da luta contra Boitatá é uma unidade posterior.
- O jogador pode avançar ou pular o prólogo; a cena seguinte é sempre o mapa.

## Critérios de aceitação

- Iniciar pelo menu abre o prólogo, não diretamente a fase.
- O prólogo apresenta cinco momentos narrativos com animações visíveis e pode ser avançado ou pulado por botão ou Escape.
- Concluir ou pular o prólogo abre o mapa sem criar cenas de transição concorrentes.
- O mapa apresenta sete marcos nomeados pela campanha, indica a primeira etapa como disponível e bloqueia as demais.
- Selecionar a fase 1 carrega o protótipo atual.
- O layout permanece legível em redimensionamentos da janela.

## Fora de escopo

- Desbloqueio persistente por drops, salvamento da campanha e escolha de fases posteriores.
- Implementação das fases, dos bosses Iara/Cuca/Corpo Seco e de suas mecânicas.
- Divisão da cena de combate atual entre o tutorial e a fase da Boitatá.
- Arte inédita para o historiador, Cuca ou Corpo Seco; a sequência usa o sprite atual do protagonista, Boitatá existente e uma silhueta para o Corpo Seco.

## Narrativa do prólogo

O historiador investiga Ratanabá séculos após seu desaparecimento. Os artefatos recolhidos despertam uma passagem temporal; no passado, o protagonista descobre que a Cuca pretende trazer o Corpo Seco ao mundo e parte para impedir o ritual. Esta formulação segue a direção registrada no README e em `game-overview.md`.
