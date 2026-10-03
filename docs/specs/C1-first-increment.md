# Spec: Primeiro Incremento Jogável (C1)

## Objetivo
Descrever o menor incremento jogável que demonstra a proposta do jogo.

## Decisões

- Nome do incremento: Protótipo de Combate Mínimo
- Escopo mínimo: Cena única com jogador controlável (movimento, pulo), ataque corpo a corpo simples, um inimigo que recebe dano, e mecânica de rolada (dash/evade) com cooldown
- Estrutura do primeiro trecho: o jogador aprende os controles e o combate avançando pela cidade perdida de Ratanaba. Na campanha planejada, a Boitatá é enfrentada na fase 2, como boss tutorial; essa luta não faz parte da fase 1.
- Justificativa: o incremento testa o ritmo de beat ’em up lateral, progressão, combate e leitura de padrões sem exigir a implementação da campanha completa.
- Papel do jogador: Jogador controla um homem cujo objetivo é derrotar criaturas folclóricas (confirmado)
- Tom do jogo: Sério

## Requisitos

<!-- Requisitos serão adicionados aqui seguindo o formato em references/formato-requisitos.md -->

- R-001 Movimento e Pulo (Prioridade: Alta, Status: PRONTO)
	- Descrição: O jogador pode mover-se lateralmente e pular.
	- Critério de aceitação (Dado/Quando/Então):
		- Dado que o protótipo está rodando,
		- Quando o jogador pressiona `A` ou `D`,
		- Então o personagem se move horizontalmente com velocidade inicial configurada.
		- Dado que o jogador está no chão,
		- Quando o jogador pressiona `Espa?o`,
		- Então o personagem executa um pulo observável.

- R-002 Ataque básico (Prioridade: Alta, Status: PRONTO)
	- Descrição: O jogador pode atacar e infligir dano a um inimigo próximo.
	- Critério de aceitação:
		- Dado que um inimigo está dentro do alcance de ataque,
		- Quando o jogador pressiona `K`,
		- Então o inimigo recebe `1` de dano e perde vida; se a vida do inimigo chegar a 0, ele é removido da cena.

- R-003 Rolada / Dodge (Prioridade: Alta, Status: PRONTO)
	- Descrição: O jogador executa uma rolada curta que o desloca rapidamente e concede invulnerabilidade temporária.
	- Parâmetros implementados: duração = 0.25s, distância ≈150px, invulnerabilidade = 0.25s, cooldown = 0.8s.
	- Critério de aceitação:
		- Dado que a rolada não está em cooldown,
		- Quando o jogador pressiona `Shift (esquerdo)`,
		- Então o jogador realiza uma rolada curta (dash) e fica imune a danos durante a duração, e não pode rolard novamente até o cooldown terminar.


- R-004 Fase tutorial com progressão lateral (Prioridade: Alta, Status: PROPOSTO)
	- Descrição: A primeira fase acompanha o avanço pela cidade perdida de Ratanaba e ensina os controles e mecânicas básicas por meio de encontros com inimigos.
	- Origem: Decisão do aluno — a primeira fase ensina o combate; a boss fight tutorial contra a Boitatá acontece na segunda fase.
	- Critério de aceitação:
		- Dado que a fase tutorial está ativa,
		- Quando o jogador avança e supera os encontros de tutorial,
		- Então o caminho se abre e a fase termina sem a boss fight da Boitatá.

## Perguntas em aberto

- O jogador perde a fase ao zerar vida, ou a fase reinicia automaticamente ao cair em combate?

## Direção da campanha

A estrutura planejada para o jogo completo é de pelo menos 7 fases em 4 mapas/regiões: Floresta da Ratanaba (tutorial na cidade perdida; depois a floresta e a boss fight tutorial da Boitatá), Rio Negro (onda de inimigos; depois a boss fight da Iara com intervenção da Vitória Régia), Caverna da Cuca (onda de inimigos com transição para o laboratório; depois a boss fight da Cuca e interrupção do ritual do Corpo Seco) e Floresta Amazônica (onda de inimigos e confronto final contra o Corpo Seco). O detalhamento está em `docs/context/game-overview.md`.

O protótipo descrito nos registros abaixo já reuniu encontros e Boitatá em um único trecho jogável para testar o núcleo de combate. Isso documenta o estado do protótipo, não altera a divisão planejada da campanha em fases 1 e 2.


## Incremento beat ?em up ? 2026-10-02

- Inspira??o adicional confirmada: TMNT cl?ssicos e TMNT: Shredder?s Revenge.
- WASD ou setas movem o jogador pelos dois eixos da rua; movimento diagonal ? normalizado.
- Espa?o mant?m o pulo como deslocamento visual em altura, separado da posi??o dos p?s na arena.
- Colis?es e ordena??o visual usam a posi??o dos p?s; ataques exigem proximidade na mesma faixa de profundidade.
- K ataca com alcance ampliado e cooldown de 1s. Contato persistente causa dano a cada 0,7s.
- Shift inicia rolada de 120px em 0,22s na dire??o do movimento, ou para o lado encarado se parado; cooldown de 0,8s. Atravessa inimigos e bloqueia dano apenas durante a rolada.
- Rua de 3800px, c?mera de acompanhamento, dois grupos de dois inimigos e Boitata como chefe final. Derrotar cada grupo libera avan?o para o pr?ximo encontro.
- Inimigos futuros ficam invis?veis e sem colis?o/dano at? a ativa??o de seu encontro.
- Derrota mostra rein?cio da fase; derrotar o chefe mostra vit?ria e permite reiniciar. Este incremento encerra a fase; o pr?ximo mapa permanece para um ciclo posterior.

## Travessia de buracos ? 2026-10-02

- A rua foi alongada para 3800px, afastando os encontros e abrindo espa?o para travessia.
- Dois buracos de 100px e 110px cruzam a profundidade inteira da rua, entre os encontros. Bordas amarelas e o aviso ?ESPA?O PARA PULAR? sinalizam o perigo.
- Andar ou rolar sobre um buraco causa morte imediata (vida zerada e tela de derrota), com anima??o curta de queda e sem retorno autom?tico ao ch?o. A invulnerabilidade da rolada e o cooldown de dano n?o impedem a morte ambiental.
- Pular com Espa?o e avan?ar atravessa os buracos sem dano; aterrissar dentro do buraco tamb?m provoca queda.
- Qualquer queda mostra a tela de derrota e permite reiniciar a fase pelo bot?o.

## Tutorial guiado e ataques anunciados ? 2026-10-02

- Sequ?ncia: movimenta??o, ataque contra um inimigo, segundo inimigo para praticar rolada, primeiro buraco, encontro de dois inimigos em profundidade, segundo buraco e Boitat?.
- Instru??es contextuais acompanham o encontro; vencer o primeiro inimigo ativa o segundo. Caminho aberto aparece no objetivo at? o pr?ximo encontro.
- Inimigos comuns anunciam um golpe com faixa amarela fixa na dire??o escolhida por 0,65s; Boitat? anuncia por 0,9s e tem alcance maior (140px contra 90px). O jogador pode sair da faixa ou rolar.
- Ap?s golpear, inimigos ficam parados em recupera??o por 0,4s; Boitat? por 0,55s. Dano por contato de 0,7s continua ativo, respeitando a invulnerabilidade e o intervalo de dano do jogador.
- HUD mostra vida, etapa/objetivo, disponibilidade de ataque e rolada, instru??o contextual e barra de vida do chefe.
- Tempo de experi?ncia alvo: 3 a 5 minutos, a confirmar com playtest; ainda n?o medido.

## Ajustes da Boitatá — 2026-10-02

- A Boitatá permanece no trecho de chão em que surge, com margem de 20px da borda dos buracos. Perseguição e dash não atravessam o último buraco; dash bloqueado entra em recuperação.
- Ataques normais (mordida, cauda e empurrão): 3 de dano, cooldown de 1,3s após o golpe.
- Dash especial: 5 de dano. O rastro de fogo mantém 1 de dano.
- Com o jogador a mais de 200px, lança uma bola de fogo direcionada à posição dele a cada 2s enquanto em perseguição. Cada bola causa 2 de dano e respeita a invulnerabilidade da rolada.
- Verificação headless em `teste/boitata_checks.gd`: passou, incluindo limite do buraco, danos, cooldown de projéteis e imunidade da rolada.

## Menu básico e pausa — 2026-10-02

- O projeto inicia em `teste/menu.tscn`, com título provisório “LENDAS DO BRASIL” e botões Jogar, Controles e Sair.
- O título pode ser alterado em `title_text` ou substituído por uma textura em `title_image` no script `GameMenu.gd`.
- Esc pausa e continua a partida. A pausa congela movimento, combate e projéteis e oferece Continuar, Controles, Voltar ao menu e Sair.
- Voltar ao menu libera a pausa; Jogar começa uma nova partida. Esc não abre a pausa durante derrota ou vitória.
- Playtest relatado pelo usuário: outras pessoas jogaram e gostaram das mecânicas; duração e observações específicas ainda não foram registradas.
- Testes headless do menu: início, controles, pausa/retomada, congelamento do combate e retorno para nova partida passaram.
