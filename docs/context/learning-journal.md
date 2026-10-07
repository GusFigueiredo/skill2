# Diário de Aprendizado

## Prólogo e mapa de fases

- A navegação foi separada em cenas próprias para manter a apresentação narrativa independente do combate.
- O mapa apresenta a campanha planejada, mas deixa explícito que apenas a fase 1 está disponível; mostrar as outras fases não implica que já sejam jogáveis.
- A transição usa o serviço de carregamento de cena existente. Assim, menu, prólogo, mapa e jogo compartilham o mesmo fluxo de carregamento.
- Limitação identificada: a cena atual de jogo reúne o tutorial e a Boitatá, embora a campanha documentada distribua a luta na fase 2. A divisão deve ser validada e feita antes de vincular desbloqueios a derrotas e drops.
- Playtest manual ainda não realizado; as verificações headless foram executadas na revisão cinematográfica abaixo.

## Revisão cinematográfica do prólogo

- A primeira versão apresentava quadros narrados sobre uma composição quase estática. O incremento foi revisto para mostrar cinco cenas em movimento.
- O protagonista usa os `SpriteFrames` existentes para caminhar, pular, atacar e receber dano; o inimigo comum executa ataque, reação e derrota. A Boitatá aparece no prenúncio da ameaça.
- Os cenários combinam o fundo florestal existente com formas de ruínas e efeitos criados em Godot, evitando novos requisitos de arte.
- A timeline avança sozinha para preservar o ritmo cinematográfico, mas permite avançar cada trecho ou pular para o mapa.
- Verificação automatizada: import/parsing no Godot 4.7.2; verificações de prólogo/mapa, menu e inicialização sem erros; execução headless da cena por 2.100 frames.
- Ainda é necessário playtestar visualmente no editor para avaliar enquadramento, duração e legibilidade no jogo.
