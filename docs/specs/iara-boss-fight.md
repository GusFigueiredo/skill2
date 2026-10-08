# Boss Fight: Iara

## Recorte implementado — 2026-10-08

Por solicitação do usuário, este incremento implementa primeiro o combate e a derrota normal da Iara. O feitiço final impossível e o resgate pela Vitória Régia ficam para depois; não impedem o último golpe nesta versão.

- Vida: 6 pontos, igual à Boitatá da fase 2. Cada golpe normal do jogador continua causando 1 de dano, sem multiplicador de burst.
- Arena: margem seca à esquerda e rio à direita, conforme o novo `chao boss fight Iara.png`. Esta composição resolve a divergência entre esquerda/direita citada abaixo usando o asset fornecido.
- A batalha começa com Iara em idle por 1,25s. Depois ela prepara a sedução com os sprites próprios desse ataque: 2,5s de preparação, ou 2s com metade da vida ou menos. As partículas surgem depois do início da pose. O lançamento tem 0,55s de trajeto visível antes de aplicar hipnose.
- Câmera: zoom padrão de 1,8 fora do transe; durante a hipnose, aproxima suavemente para 2,43 e centra o personagem. Quebrar o encanto, morrer ou terminar a luta restaura o enquadramento normal.
- Posição inicial do jogador: `(440, 460)`, na terra firme, 180px antes da linha de água e com a Iara visível no enquadramento inicial.
- Transe: arrasto crescente, movimento reduzido a 20%, bloqueio de ataque, pulo e rolada, escurecimento e filtro de áudio. O jogador tem 7 segundos para quebrá-lo.
- Resistência: 8 entradas alternadas A/D ou esquerda/direita, com cooldown compartilhado de 0,2 segundo entre ações aceitas. Segurar uma direção não acumula; parar por mais de 1,25 segundo reduz o progresso. O HUD indica quando a próxima ação está pronta.
- No transe, os sprites pixelados de A/D aparecem acima da cabeça, acompanhando a posição do personagem e o zoom. Só a próxima tecla indicada treme. Pressionar A ou D exibe a versão pressionada fornecida na imagem; uma ação aceita muda a indicação para a outra tecla. Ao terminar o efeito, os ícones desaparecem.
- Efeitos do feitiço: partículas, arcos de energia e selo no chão durante a preparação; projétil com rastro e coração no lançamento; espiral, aura, pequenos corações e círculo nos pés durante a hipnose. A Iara usa os sprites de sedução também na aplicação do feitiço.
- Ao entrar em transe surge um inimigo 100 pixels à esquerda do jogador, na mesma altura, com velocidade de 30 pixels por segundo, que segue e causa dano por contato. Se sobreviver ao encanto, continua junto dos capangas e também precisa ser derrotado para abrir a brecha.
- Encanto quebrado: queda de 0,75 segundo e aproximação da Iara à margem, seguida do surgimento animado de 2 capangas; com metade da vida ou menos, 3.
- Iara só recebe dano depois que todos os capangas morrem. A janela dura exatamente 2 segundos; depois, o canto recomeça.
- A água não causa dano gradual. Durante canto/transe, permanecer nela por 3 segundos contínuos causa morte direta com a animação normal e tela de derrota, sem uma segunda contagem. Voltar à margem zera a exposição. Durante queda, capangas e brecha, o encanto se interrompe e a água se acalma.
- Falhar no transe inicia uma contagem fatal de 3 segundos; ao final, o jogador morre. O zoom do transe retorna ao padrão ao começar o afogamento.
- A área de dano da Iara acompanha os limites visíveis de cada frame, incluindo rosto e cauda na pose caída; a colisão dos pés permanece separada. A proteção fora da janela continua ativa.
- Zerar a vida da Iara executa sua animação de derrota, salva a fase 4 e retorna ao mapa pela transição existente. Reiniciar recarrega a luta inteira.
- Os ataques adicionais de cabelo, onda com knockback e espelho/ilusão permanecem para outro incremento. O foco atual é canto, sedução, capangas e vulnerabilidade.

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

- a Vitória-Régia aparece no rio
- ela quebra o encanto da Iara
- a Iara cai ou é derrubada
- o jogador recebe um item, amuleto ou pista
- a Vitória-Régia revela o próximo destino: onde encontrar Cuca

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
