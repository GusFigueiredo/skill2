# Parallax e ambientação das fases 1–4

Refinamento de 2026-10-15, a pedido do usuário, aplicando a profundidade visual da fase 5 às fases já existentes.

## Profundidade e composição

`StageScenery.gd` é instalado por `Level1.gd` somente nas fases 1–4. O fundo desloca-se horizontalmente em 13% do deslocamento da câmera ativa, dando a sensação de maior distância em relação ao chão e aos personagens. A referência inicial permanece fixa durante trocas de câmera, aproximações e retorno das cutscenes.

A configuração ocorre de forma adiada para respeitar os ajustes que a fase da Iara faz depois da inicialização herdada, incluindo a posição vertical do fundo e a composição especial de margem e rio. As coordenadas, escalas, regiões e texturas do chão continuam fixas no mundo, assim como buracos, arenas e colisões.

Fundo e chão comum usam repetição espelhada da arte para reduzir emendas verticais, com filtragem nearest. O chão mantém as cores e a transparência originais. O `BossGround` da Iara conserva seu material e orientação para preservar a margem e a água. O fundo recebe um ajuste discreto de cores e uma névoa de profundidade entre ele e o chão.

## Identidade dos ambientes

- Fase 1: tons quentes nas ruínas de Ratanabá, luz difusa, vagalumes com pulsos independentes e folhas lentas.
- Fase 2: floresta com tons mais verdes e oliva, mantendo o contraste da Boitatá e dos sinais de ataque.
- Fases 3–4: fundo azul e iluminação fria, chuva em três planos com variações de velocidade, comprimento e vento, névoa mais translúcida, reflexos e respingos discretos. Os respingos de chão respeitam buracos e o limite da margem da Iara; a água conserva seus efeitos próprios.

Partículas fora da visão são descartadas do desenho quando aplicável. Os efeitos ficam abaixo do HUD, dos diálogos e das teclas do transe. Seus relógios avançam com o jogo e congelam durante a pausa.

A fase 5 mantém `CucaForestScenery.gd` e seu parallax próprio; ela não recebe uma segunda camada de cenário.

## Validação

`stage_scenery_checks.gd` move uma câmera real e verifica o deslocamento do fundo, continuidade ao trocar para uma câmera de cutscene, retorno ao enquadramento original, pausa e retomada. Também compara posições do chão, margem especial, atores, buracos e colisões, e confirma que a fase 5 mantém seu cenário próprio.

`stage_scenery_preview.gd` gera capturas das quatro fases, pares antes/depois de um movimento de câmera, trechos distantes, apresentação da Boitatá e entrada/arena da Iara, em `teste/.validation/parallax-previews/`.

`rio_rain_checks.gd`, `boitata_entrance_checks.gd` e `iara_entrance_checks.gd` cobrem as regressões de clima, controles, HUD, pausa e apresentações dos bosses. As verificações usam APPDATA isolado para preservar os saves do jogador.
