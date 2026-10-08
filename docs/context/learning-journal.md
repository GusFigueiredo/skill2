# Diário de Aprendizado

## Apresentação da sedução e teclas do transe — 2026-10-08

- O início da luta ganhou 1,25s em idle. Preparação e lançamento são estados separados, para mostrar os sprites do ataque e o trajeto do feitiço antes de aplicar a hipnose.
- As quatro versões de A/D do sheet fornecido são usadas por atlas. O indicador acompanha a cabeça em coordenadas de tela, treme só a próxima tecla e troca para a imagem pressionada com a entrada real ou feedback de uma ação aceita.
- A câmera aproxima para 2,43 durante o transe, acompanha o corpo do jogador e volta suavemente ao zoom padrão 1,8 e à posição original ao terminar o efeito.
- A apresentação mágica foi separada em `IaraSpellEffects.gd`, com carga, lançamento e hipnose visualmente distintos. O cooldown de 0,2s, as oito entradas, o perseguidor e as regras de dano permanecem no controlador do combate.
- `iara_checks.gd` passou incluindo sequência idle/ataque/lançamento, sprites pressionados, tremor alternado, zoom e restauração, além de capangas, hitboxes, afogamento, vitória e reinício. Capturas renderizadas dos estados foram conferidas; tempo e legibilidade ainda dependem de playtest manual.

## Distância do perseguidor e início na margem — 2026-10-08

- O inimigo do transe agora surge 100px à esquerda do personagem, na mesma altura.
- O jogador passou a iniciar em `(440, 460)`, ainda 180px antes da zona de água. Com o zoom padrão e a câmera existente, esse ponto permite ver a Iara desde o início.

## Posição do inimigo e cadência do transe — 2026-10-08

- Por solicitação do usuário, o perseguidor agora surge exatamente 50px à esquerda do jogador, na mesma altura.
- O cooldown entre entradas de resistência passou de 0,5s para 0,2s; a instrução do HUD e os checks existentes foram atualizados para essa cadência.

## Revisão da luta da Iara após feedback — 2026-10-08

- O enquadramento amplo tornava os atores menores que nas outras fases. A câmera voltou ao zoom 1,8 e ao acompanhamento padrão do jogador.
- A resistência agora tem 0,5s entre entradas alternadas aceitas; a tolerância antes de perder progresso foi ajustada a 1,25s para permitir essa cadência. Segurar a tecla continua sem acumular pontos.
- O inimigo invocado no transe segue a 30px/s e causa dano por contato. Se estiver vivo ao quebrar o encanto, participa da proteção da Iara junto dos capangas.
- A água deixou de causar dano gradual: uma única contagem de 3s na zona ativa resulta em morte normal. Sair da zona reinicia a contagem; a rolada não evita a morte ambiental ao completar o tempo.
- A hitbox anterior derivava apenas da pose em pé e ficava centralizada no ator. Recortes do atlas e suas margens agora determinam a área real de cada pose, corrigindo a posição do rosto na queda sem alterar a colisão de movimento.
- Validação: checks de Iara e ataque direcional passaram; golpes reais atingiram rosto e cauda, cooldown foi conferido em 0,49/0,5s e morte por água em 2,99/3s. Capturas das fases do combate foram conferidas no zoom padrão.

## Boss fight da Iara — 2026-10-08

- Separar o ciclo da Iara do controlador de ondas permite exigir resistência e eliminação de capangas antes de aceitar dano no boss.
- O mesmo ataque do jogador foi mantido: a consulta de colisão real acertou a Iara caída e retirou exatamente 1 de seus 6 pontos de vida.
- O transe conta alternância de direção, não teclas mantidas ou repetição automática. Ataque, rolada e pulo são bloqueados durante o efeito; o movimento reduzido e o arrasto preservam a ameaça da água.
- A composição da arena foi ajustada ao asset: margem seca à esquerda, água à direita e boss deslocada à margem na queda. Regiões específicas do atlas evitam fragmentos de poses vizinhas.
- A cena reutilizável de inimigo não possuía a barra exigida por `Enemy.gd`; adicioná-la permitiu invocações com animação e vida consistentes.
- Um check antigo de contato usava inimigos desativados pelo tutorial; o fixture foi corrigido para ativar o inimigo antes de verificar rolada e dano ao reencontro.
- Checks de ciclo da Iara, fluxo de Rio Negro, Ratanabá, rolada, contato e ataque direcional passaram. Capturas de canto, sedução, queda, brecha e submersão foram conferidas. O ambiente mantém os avisos conhecidos de certificados e recursos no encerramento dos checks.
- A derrota normal foi priorizada a pedido do usuário; Vitória Régia e feitiço impossível permanecem para o próximo incremento narrativo. Dificuldade e ritmo ainda exigem playtest manual.

## Fases do Rio Negro — 2026-10-08

- Cenas herdadas permitem trocar a arte de uma região sem copiar controles, HUD e transições.
- A configuração de encontros foi extraída para um método substituível; o Rio Negro usa uma onda por fase, com três e quatro inimigos respectivamente.
- Identificar a fase pelo índice e pelo caminho da cena evita confundir todas as fases sem tutorial com a fase 2 ao salvar progresso ou reiniciar.
- A fase 4 prepara a região com inimigos existentes. A Iara e a intervenção da Vitória Régia permanecem como trabalho posterior previsto na narrativa.
- Validação no Godot 4.7.2: checks de Ratanabá, campanha, saída de fase e Rio Negro passaram. Foram verificados dano, bloqueio de vitória com inimigos vivos, reinício nas duas fases, desbloqueio sequencial, escolha pelo mapa e a sequência 3 → 4 → mapa.
- Revisão visual: capturas renderizadas das duas fases confirmaram alinhamento do chão, cobertura do fundo e enquadramento dos atores e do HUD. Playtest manual de ritmo e dificuldade continua pendente.
- O ambiente emite aviso de certificados do Windows e os checks apresentam avisos de objetos/recursos em uso ao encerrar, também observados nas verificações existentes; não houve erro de script na execução final dos checks.

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

## Centralização da logo do menu

- A logo ganhou um contêiner de centralização próprio, mantendo o alinhamento horizontal independente da largura dos botões.
- A sombra existente foi ampliada discretamente e seu retângulo continua com o tamanho integral, deslocado para trás/baixo em relação à imagem.
- As verificações do menu agora validam o centro horizontal da logo e a geometria da sombra; a revisão visual em janela ainda é recomendada.
