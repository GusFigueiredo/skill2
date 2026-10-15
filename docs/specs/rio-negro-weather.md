# Chuva e apresentação do Rio Negro

As fases 3 e 4 recebem chuva em diferentes distâncias, névoa baixa e cores frias de tempestade. As gotas criam pequenos respingos e ondulações no chão e na água. A ambientação substitui os vaga-lumes e os focos de luz quente dessas duas fases.

A chuva acompanha a tela e a névoa mantém o cenário legível. O HUD, os retratos e os diálogos ficam acima do clima. A câmera conserva o zoom e os limites normais do jogo; o transe mantém seu efeito próprio. A pausa também congela a animação do clima.

No refinamento de 2026-10-15, o fundo das fases do rio passa a ter parallax horizontal, acompanhando 13% do deslocamento da câmera ativa. A chuva ganha variações discretas de velocidade, comprimento e vento; a névoa fica mais translúcida. Reflexos e respingos de chão são menos uniformes e respeitam os buracos e a margem da Iara. A água continua com os efeitos próprios do combate. O chão e a composição especial de margem/água ficam ancorados no mundo. Os detalhes compartilhados com as fases da floresta estão em [stage-scenery-presentation.md](stage-scenery-presentation.md).

Os ataques da Iara combinam energia turquesa, corações, partículas e ondulações na água. Preparação, lançamento e transe conservam seus tempos, danos e opções de resistência. O último canto e o resgate da Vitória-Régia continuam seguindo a sequência existente.

`teste/rio_rain_checks.gd` verifica a aplicação do clima somente nas fases do rio, a prioridade visual em relação ao HUD, a passagem dos comandos, a pausa, a câmera e o ciclo normal do transe. `teste/rio_rain_preview.gd` captura as duas fases e os estados do ataque da Iara em `teste/.validation/rio-weather-*.png` com renderização normal.
