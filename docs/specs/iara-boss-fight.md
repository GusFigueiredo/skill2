# Boss Fight: Iara

## Fase em três trechos e canto distante — 2026-10-13

- A fase 4 agora começa em `(180, 460)` com dois inimigos comuns. Após derrotá-los, o caminho abre para o único buraco, em `x=1060..1170`.
- A segunda área começa em `x=1500` e tem três inimigos. Cada um usa o sprite do Rio Negro.
- Derrotar a segunda onda abre um caminho contínuo até a Iara, sem outro buraco. O trecho 3 começa em `x=2700`; a cutscene dispara em `x=2850`, depois de 150px de caminhada em terra firme. O checkpoint da bossfight retoma essa apresentação.
- A bossfight conserva a composição e as mecânicas existentes, transladadas em 2700 pixels. O rio perigoso começa em `x=3320`; Iara fica em `(3480, 450)` e se aproxima da margem em `(3270, 450)`.
- `soundeffect/Iara/Canto.mp3` fica parado no trecho 1 e começa em loop ao entrar no trecho 2, em `x=1500`, inclusive enquanto seus inimigos estão vivos. Cresce de 0% nessa entrada a 85% em `x=2850`, sem ultrapassar esse limite. Recuar ao trecho 1 interrompe o canto.
- `Fase3.mp3` mantém o volume normal no trecho 1. A partir de `x=1500`, diminui linearmente até 15% desse volume em `x=2600`, 100px antes do fim do segundo trecho. Mantém 15% no caminho até a cutscene. A bossfight usa `Iara.mp3` no volume normal, após a apresentação.
- O canto distante para ao iniciar a cutscene, dando espaço ao beijo/risada e, depois, à trilha da bossfight. Pausa e morte suspendem o som do percurso.
- Cada trecho salva seu checkpoint. A segunda área retoma depois do buraco; a bossfight retoma a cutscene sem repetir as duas ondas anteriores.
- O último frame da risada fica na tela por mais 0,5s após terminar o áudio, antes do retorno de câmera de 0,5s.

Validação: `iara_course_checks.gd` cobre ondas, buraco, canto no trecho 2 com limite de 85%, música em 15% antes de sair do trecho 2, controle aos 149px e cutscene aos 150px, além dos checkpoints. `iara_entrance_checks.gd` verifica silêncio musical na cutscene e início de `Iara.mp3` ao terminar. `iara_course_preview.gd` captura o caminho e a arena.

## Apresentação e sons — 2026-10-13

- Antes do combate, a câmera aproxima do protagonista por 0,6s e mantém uma aproximação discreta por mais 0,6s. Depois viaja para a Iara por 1,8s e aproxima por 0,6s antes do beijo. Os planos deixam espaço na direção do olhar. O zoom começa em 1,4× sobre o zoom normal, abre levemente no meio do percurso para mostrar o rio e chega a 1,48× no começo da voz.
- Na aproximação da Iara, ela manda um beijo (três poses) e depois ri (seis poses) usando `Sprite Sheet Iara cutscene.png`. As poses preservam o tamanho visual e a linha dos pés do idle.
- `soundeffect/Iara/Cutscene.mp3` toca inteiro uma vez junto da animação. O beijo ocupa os primeiros 0,88s; a risada ocupa o restante do áudio, aproximadamente 1,48s.
- Uma aproximação contínua até 1,62× acompanha o beijo e a risada, sem corte entre os gestos. Partículas sutis saem da mão em direção ao protagonista. O overlay usa tons de água, vinheta leve, barras com entrada/saída suaves e o título discreto “IARA / ENCANTO DO RIO NEGRO”.
- O jogador e o combate ficam travados e sem dano durante a apresentação. A trilha para, o HUD se oculta e as barras cinematográficas usam a apresentação existente da Boitatá. Pausar também pausa a câmera, as poses e o áudio.
- Ao acabar a animação e o áudio, a última pose da risada permanece por mais 0,5s; depois a câmera volta ao enquadramento normal em 0,5s. O HUD e os controles retornam, a trilha `music/Iara.mp3` começa no volume normal e o idle inicial de 1,25s antecede o primeiro feitiço. Nenhuma música ou canto distante toca durante a cutscene; apenas seu áudio de beijo/risada.
- O checkpoint antes da Iara reinicia essa apresentação ao repetir a luta.
- `Preprando e soltando ataque.mp3` toca uma vez por ciclo, começando ao final da preparação para atravessar o lançamento. `hit.mp3` toca apenas quando um golpe aceito realmente tira vida da Iara.

Implementação: `IaraEntrance.gd`, `IaraCutsceneFrames.gd`, `IaraBossFight.gd`, `Iara.gd` e suporte a MP3 em `SoundEffects.gd`.

Validação: `iara_entrance_checks.gd` cobre enquadramentos, continuidade entre beijo/risada, áudio completo, pausa, proteção durante a cutscene, retorno ao combate, sons da luta, repetição após checkpoint e limpeza ao interromper a apresentação. `iara_entrance_preview.gd` gera capturas do jogador, percurso, Iara, beijo, risada, pausa final e retorno ao gameplay.

## Encerramento com Vitória-Régia — 2026-10-15

O encerramento usa o resgate pela Vitória-Régia com o sheet de três linhas da personagem: planta e transformação, idle e dash. Na metade da vida da Iara, a planta aparece no rio. Ao ficar a um golpe da derrota, Iara usa a preparação e o lançamento normais antes de um transe impossível de resistir. A/D aparecem e respondem, mas não quebram o encanto. O jogador caminha até o rio e afunda gradualmente; o resgate começa aos 90% do afogamento. A tela escurece durante 2,5 segundos até ficar quase preta; então o jogador ouve: “Ela pode dominar o canto das águas. Mas não toda a vida que existe nelas.” O retrato fica escurecido até a revelação da personagem. Depois que a última página dessa fala é encerrada, há uma espera de 1 segundo; os efeitos de soco e de hit da Iara tocam enquanto a imagem continua escura. O golpe acontece antes do resgate e substitui a antiga investida visível da Vitória-Régia.

A caixa exibe somente o retrato e o texto, sem nome. O novo sheet de rostos tem três expressões e quatro linhas; Vitória-Régia usa a quarta linha. Os retratos de 248×232 pixels e a fonte de 34 pixels seguem a apresentação compartilhada de `DialogueBox.gd`. Falas longas passam a páginas de até três linhas, preservando todos os caracteres e indicando a página atual. Enter ou Espaço revela a página e, no toque seguinte, avança.

A imagem clareia para o resgate, com Iara já derrotada e caída no chão. Sua última pose de queda permanece visível durante a conversa. Vitória-Régia e protagonista dividem a mesma folha: ela à esquerda e ele à direita. A escala da personagem se baseia na altura visível do protagonista. A planta aparece com subida curta, crescimento e transparência suaves. Durante a transformação, a própria animação desenha a folha uma única vez; a última pose passa por uma transição curta para a personagem em idle e uma plataforma sem flor. A folha se alarga gradualmente para acomodar os dois, sem encolher nem mudar sua base. Os pés se alinham à superfície da planta, usando as dimensões reais da arte. Ondulações e partículas discretas acompanham a subida e o repouso sobre a água.

O diálogo alterna os retratos do protagonista e da Vitória-Régia. Ele pergunta o que aconteceu e quem ela é. Ela se apresenta, explica que derrotou a Iara e que veio investigar sua aliança com a Cuca; também reconhece a coragem do protagonista. Ao ser questionada sobre o plano, revela a tentativa de ressuscitar o Corpo-Seco, um homem cuja maldade fez com que fosse rejeitado tanto no céu quanto no inferno. A conversa alerta para a ameaça do ritual e indica o próximo caminho: atravessar a floresta da fase 5 até a entrada da caverna da Cuca. O restante da orientação mantém esse objetivo claro. A fase 6, no interior da caverna e no laboratório, continua planejada conforme [cuca-stages.md](cuca-stages.md).

A apresentação de “Fase concluída” mantém o enquadramento do resgate, sem voltar à posição antiga da câmera na arena. A saída usa uma sequência de saltos para a direita, passando por outras vitórias-régias até a transição de fase. O enquadramento permanece estável durante a travessia. O resgate preserva a vida restante do jogador; drops não fazem parte desta etapa. Pausar suspende a espera do golpe, a transformação e a conversa. Durante a saída automática, os controles ficam bloqueados e apenas a travessia e a transição seguem ativas.

Durante o resgate, a câmera usa limites verticais ampliados e foco deslocado à esquerda para mostrar a folha inteira acima da caixa de diálogo e o corpo inteiro da Iara à esquerda. Somente nesse encerramento, `teste/shaders/rescue_river.gdshader` preserva a margem esquerda de `BossGround` e estende a água pela reflexão da seção direita da textura, evitando repetir terra seca sob as folhas. A pintura acompanha toda a largura da rota de saída.

Validação do refinamento de 2026-10-15: `vitoria_rescue_checks.gd` cobre a espera de 1 segundo após a fala misteriosa, os sons do golpe no escuro, a derrota da Iara antes da revelação, o resgate e a folha compartilhada, os diálogos alternados, a preservação de HP e a pausa. Também verifica o corpo inteiro da Iara no enquadramento, a folha acima do diálogo, a câmera preservada na conclusão, os arcos e pousos dos saltos e o retorno ao mapa. `vitoria_rescue_preview.gd` captura esses momentos. `iara_checks.gd` mantém a validação da luta completa e do resgate.

## Combate implementado

- Vida: 6 pontos, igual à Boitatá da fase 2. Cada golpe normal do jogador continua causando 1 de dano, sem multiplicador de burst.
- Arena: margem seca à esquerda e rio à direita, conforme o novo `chao boss fight Iara.png`. Esta composição resolve a divergência entre esquerda/direita citada abaixo usando o asset fornecido.
- A batalha começa com Iara em idle por 1,25s. Depois ela prepara a sedução com os sprites próprios desse ataque: 2,5s de preparação, ou 2s com metade da vida ou menos. As partículas surgem depois do início da pose. O lançamento tem 0,55s de trajeto visível antes de aplicar hipnose.
- Câmera: zoom padrão de 1,8 fora do transe; durante a hipnose, aproxima suavemente para 2,43 e centra o personagem. Quebrar o encanto ou morrer restaura o enquadramento normal. No encerramento, o enquadramento permanece no resgate e acompanha a saída pelas vitórias-régias.
- Entrada da bossfight: `x=2850`, após caminhar 150px pelo trecho 3, em terra firme. A fase começa em `(180, 460)`.
- Transe: arrasto crescente, movimento reduzido a 20%, bloqueio de ataque, pulo e rolada, escurecimento e filtro de áudio. O jogador tem 7 segundos para quebrá-lo.
- Resistência: 8 entradas alternadas A/D ou esquerda/direita, com cooldown compartilhado de 0,2 segundo entre ações aceitas. Segurar uma direção não acumula; parar por mais de 1,25 segundo reduz o progresso. Os ícones acima do jogador indicam a próxima tecla e a barra de resistência mostra o progresso, sem painel textual de instruções no canto superior direito.
- No transe, os sprites pixelados de A/D aparecem acima da cabeça, acompanhando a posição do personagem e o zoom. Só a próxima tecla indicada treme. Pressionar A ou D exibe a versão pressionada fornecida na imagem; uma ação aceita muda a indicação para a outra tecla. Ao terminar o efeito, os ícones desaparecem.
- Efeitos do feitiço: partículas de coração do próprio sheet (após a última pose da linha 3), arcos de energia e selo no chão durante a preparação; projétil com rastro e coração no lançamento; espiral, aura, pequenos corações e círculo nos pés durante a hipnose.
- Ao entrar em transe surge um inimigo 100 pixels à esquerda do jogador, na mesma altura, com velocidade de 30 pixels por segundo, que segue e causa dano por contato. Se sobreviver ao encanto, continua junto dos capangas e também precisa ser derrotado para abrir a brecha.
- Encanto quebrado: queda de 0,75 segundo e aproximação da Iara à margem, seguida do surgimento animado de 2 capangas; com metade da vida ou menos, 3.
- Iara só recebe dano depois que todos os capangas morrem. A janela dura exatamente 2 segundos; depois, o canto recomeça.
- A água não causa dano gradual. Durante canto/transe, permanecer nela por 3 segundos contínuos causa morte direta com a animação normal e tela de derrota, sem uma segunda contagem. Voltar à margem zera a exposição. Durante queda, capangas e brecha, o encanto se interrompe e a água se acalma.
- Apresentação do afogamento: ondulações e arco decrescente avisam a exposição à água; na sequência fatal, o personagem afunda sem deformação, com água em camadas onduladas, bolhas, arrasto suave e escurecimento/filtro de áudio progressivos. A superfície ondulada encobre progressivamente o corpo por shader; sair da água restaura o visual e a sombra. Após a morte, o corpo continua descendo e desaparece em 1,8s, mantendo a câmera e a superfície estáveis. As ondulações dissipam junto com o corpo.
- Falhar no transe inicia uma contagem fatal de 3 segundos; ao final, o jogador morre. O zoom do transe retorna ao padrão ao começar o afogamento.
- A área de dano da Iara acompanha os limites visíveis de cada frame, incluindo rosto e cauda na pose caída; a colisão dos pés permanece separada. A proteção fora da janela continua ativa.
- Na sequência final, Iara perde o último ponto de vida com o golpe ouvido no escuro e permanece caída durante o resgate. A conclusão da fase 4 aguarda o diálogo; depois, o protagonista salta pelas vitórias-régias até a transição para o mapa. Reiniciar recarrega a luta inteira.
- Os ataques adicionais de cabelo, onda com knockback e espelho/ilusão permanecem para outro incremento. O foco atual é canto, sedução, capangas e vulnerabilidade.
- Animações: a linha 1 do sheet tem os 4 frames de idle em loop; a linha 2 tem os 5 frames do ataque, tocados uma vez no lançamento e depois alternados nos 2 últimos (`4 → 5 → 4 → 5...`) durante o transe; a linha 3 alterna os 2 primeiros frames de preparação e termina no terceiro, seguido pelo primeiro frame de idle. A linha 4 anima a queda e mantém a última pose enquanto a Iara está caída; a linha 5 anima a derrota.

Implementação: `teste/scripts/IaraBossFight.gd`, `Iara.gd`, `IaraVisual.gd`, `IaraFrames.gd`, `TranceKeyPrompt.gd` e `IaraSpellEffects.gd`. Os sprites da personagem e das teclas são recortados por atlas, preservando as imagens originais fornecidas.

Validação: `teste/iara_checks.gd` cobre o ciclo completo, golpe real do jogador, vida/dano iguais à Boitatá, resistência, invocações, janela, afogamento, pausa, vitória e reinício. Capturas renderizadas conferem os estados principais. Ritmo e dificuldade exigem playtest manual.

## Visão geral

A batalha contra a Iara deve reforçar a lenda do rio: sedução, encantamento, afogamento e a perda da vontade. O combate não é sobre "bater na boss sem lógica"; é sobre resistir ao feitiço, abrir brechas, lidar com os capangas e, em momento final, sobreviver ao feitiço impossível.

A referência visual da arena segue a composição da imagem enviada:

- lado esquerdo: terreno seco e seguro, onde o jogador começa
- centro/direita: rio ou margem de água, que representa o território da Iara
- boss: posicionada na beira ou no centro da água, com presença dominante
- a água não é apenas cenário; é zona de risco de afogamento

A regra fundamental da batalha é:

- se o jogador entrar na zona da água ou ficar muito perto dela, ele começa a afogar
- a água empurra o personagem em direção à Iara e causa morte após 3 segundos contínuos, sem dano gradual
- o jogador precisa manter distância da margem ou quebrar o feitiço antes que seja puxado para o fundo

---

## Arena e posicionamento

### Composição da arena

- o jogador começa na margem da direita/na parte seca do terreno
- a Iara ocupa a borda do rio ou a parte mais profunda da água
- a água funciona como zona perigosa, não como simples fundo decorativo
- a camera deve mostrar claramente o limite entre o chão firme e a água

### Regra de perigo da água

- se o jogador entrar numa área de risco próxima da água, o efeito de afogamento começa imediatamente
- o afogamento deve ser progressivo e visível
- o personagem não pode ficar parado na beira do rio sem reação
- a Iara usa essa borda do rio para atrair e arrastar o jogador para as profundezas

### Sensação desejada

O jogador deve sentir que a água “puxa” ele, e que o ambiente está vivo contra ele. A borda da água não é um lugar seguro, é uma armadilha.

---

## Loop principal da batalha

### 1. Preparação do feitiço da sedução

A Iara se posiciona ao longo da margem do rio e começa a cantar.

- ela fica imóvel por 2 a 3 segundos
- a água começa a oscilar e a área de encantamento aparece
- o jogador pode ver o efeito dela antes de sofrer o feitiço
- a Iara está "preparando" a manipulação do jogador

### 2. Feitiço da sedução

Quando a onda de encantamento atinge o jogador:

- o personagem começa a andar lentamente em direção à Iara
- o movimento natural do jogador é reduzido
- a velocidade de deslocamento cai
- a câmera e o áudio ficam mais sombrios e abafados
- o jogador passa a ficar vulnerável ao afogamento na água e ao inimigo invocado durante o transe

O jogador não deve conseguir atacar livremente enquanto está sob esse efeito.

### 3. Resistência ao transe

Para sair do transe, o jogador precisa "quebrar o encanto".

- o jogador deve mover para esquerda e direita em sequência
- a ação deve ser constante, respeitando o cooldown de 0,2 segundo entre ações
- quanto mais o jogador se mexe, mais ele resiste ao efeito
- se o jogador parar, o arrasto para a água continua

### 4. Brecha de Iara

Se o jogador resiste o suficiente:

- a Iara cai / perde a postura
- o feitiço é interrompido
- os capangas da Iara entram em cena
- o jogador recebe uma janela clara para reagir

### 5. Capangas da Iara

Ao cair o feitiço, surgem 2 ou 3 capangas, dependendo do estágio da luta.

- os capangas atacam o jogador diretamente
- o jogador precisa eliminá-los
- se todos forem derrotados, a Iara fica aberta a um golpe

### 6. Janela de ataque

Quando os capangas são derrotados:

- a Iara fica momentaneamente atordoada / inconsciente
- o jogador tem 2 segundos para atacar
- esse golpe deve ser curto e forte, como um burst de dano
- ao fim do tempo, ela reativa o feitiço e o ciclo reinicia

---

## Dano e afogamento

### Afogamento básico

Quando o jogador está na beira da água ou entra na zona de risco:

- o personagem começa a afogar em progressão
- a vida permanece intacta até completar 3 segundos contínuos na água; então ocorre morte direta
- o arraste para a Iara aumenta
- ele não pode simplesmente "ficar parado" e esperar o efeito passar

### Afogamento completo

Quando o jogador falha na resistência do transe ou não sai da água:

- ele começa a se afogar de forma lenta e dramática
- a contagem fatal dura 3 segundos
- ao terminar a contagem, a morte usa a apresentação normal do jogo, mantendo o zoom padrão
- depois da contagem, o personagem morre completamente

Essa morte não deve ser instantânea; ela deve parecer a finalização da lenda do rio.

A sensação visual deve ser:

- água subindo nos pés
- água na cintura
- água no peito
- água na cabeça
- deslizar para o fundo
- morte por afogamento

---

## Ataques da Iara

### 1. Canto do rio

- a Iara se ergue e começa a cantar
- uma onda de sedução surge ao redor da borda da água
- o efeito atinge o jogador, começando o transe

### 2. Puxão das profundezas

- a água agarra o jogador
- ele perde velocidade e é empurrado para a margem da Iara
- funciona como pressão e preparação para o afogamento

### 3. Cabelo da água

- fios ou golpes de cabelo saem da água e atingem o jogador
- o golpe arrasta ou empurra o jogador para o rio
- funciona como dano e "manipulação de posicionamento"

### 4. Onda de afogamento

- uma onda de água avança pela arena
- pequenos picos de dano e knockback são aplicados
- afeta principalmente quem estiver perto da água

### 5. Espelho do rio

- Iara se reflete na superfície da água
- uma segunda ilusão é criada em uma parte da arena
- a verdadeira Iara pode atacar de outra direção, confundindo o jogador

---

## Regras de combate

### Jornada do jogador

- o jogador deve respeitar a linha da água
- o rio deve ser entendido como zona de perigo e não como área de exploração segura
- o combate deve forçar o jogador a se posicionar no centro do terreno seco, mantendo distância da margem

### Regras da boss

- a Iara não deve ser um combate de "apertar botão e bater"
- o principal modo de vencer não é dano direto contínuo
- a Iara vence quando o jogador se aproxima da água e falha na resistência
- o jogador vence quando consegue quebrar o encanto e eliminar os capangas para abrir a janela de ataque

### Progresso da luta

- ciclos iniciais: 2 capangas, feitiço mais lento
- fases intermediárias: 3 capangas, feitiço mais rápido
- fase final: feitiço impossível, afogamento fatal, intervenção da Vitória-Régia

---

## Fase final da Iara

Quando a Iara chega com pouca vida, ela tenta o feitiço definitivo.

### Como deve funcionar

- o efeito da sedução se torna impossível de resistir
- o jogador entra no transe e começa a ser puxado pela água
- a morte pelo afogamento é quase inevitável
- a âncora emocional da batalha passa a ser a ideia de "não há como sair sozinho"

### Intervenção da Vitória-Régia

No momento crítico:

- a fala misteriosa da Vitória-Régia acontece durante o escurecimento
- 1 segundo após encerrar essa fala, um soco e o hit da Iara são ouvidos no escuro
- a Vitória-Régia salva o protagonista e divide com ele uma folha no rio
- a Iara permanece caída e visível no chão durante a conversa
- a Vitória-Régia revela a aliança com a Cuca, o plano de ressuscitar o Corpo-Seco e o caminho pela floresta até a caverna
- a conclusão mantém o cenário do resgate e termina com saltos para a direita entre vitórias-régias

Esse momento deve ser narrativamente importante:

- a Iara apostou na sedução e no afogamento
- a Vitória-Régia converte o rio em esperança, cura e direção
- a vitória não é só o dano; é a intervenção de algo maior

---

## Objetivo da fase

- ensinar que o rio e a água são perigosos
- fazer o jogador respeitar a margem da água
- criar um combate com ritmo de resistência, pressão e oportunidade
- diferenciar a Iara do Boitatá: a Iara não força por dano bruto; ela seduz, arrasta e afoga

---

## Critérios de sucesso da implementação

- o jogador sente que a água é perigosa e não atravessável sem risco
- o transe é legível e muito claro visualmente
- a resistência por esquerda/direita se sente como uma reação de sobrevivência
- a queda da Iara por ter resistido ao feitiço funciona como recompensa de jogo
- os capangas quebram o ritmo da luta de forma satisfatória
- a morte por afogamento é dramática e memorável
- a intervenção da Vitória-Régia fecha o arco da Iara e abre o próximo objetivo

---

## Resumo em uma frase

A Iara é a boss da sedução e do rio: o jogador não vence batendo nela sem pensar, ele vence resistindo ao encanto, lidando com os capangas e sobrevivendo ao afogamento antes que a Vitória-Régia o salve e revele o próximo caminho.
