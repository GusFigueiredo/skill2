# Spec: Primeiro Incremento Jogável (C1)

## Objetivo
Descrever o menor incremento jogável que demonstra a proposta do jogo.

## Decisões

- Nome do incremento: Protótipo de Combate Mínimo
- Escopo mínimo: Cena única com jogador controlável (movimento, pulo), ataque corpo a corpo simples, um inimigo que recebe dano, e mecânica de rolada (dash/evade) com cooldown
- Estrutura da fase tutorial: o jogador avança para a direita em uma sequência linear, elimina inimigos em onda e conclui o trecho com uma boss fight contra a Boitata.
- Justificativa: essa estrutura reproduz o ritmo de beat ’em up lateral e cria o primeiro teste de progressão, combate e leitura de padrões em um espaço de fase curto.
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

- R-004 Fase tutorial com progressão lateral e boss final (Prioridade: Alta, Status: PROPOSTO)
	- Descrição: A fase tutorial do jogo acompanha o avanço para a direita, com inimigos em sequência e encontro final contra a Boitata.
	- Origem: Decisão do aluno — a primeira fase precisa ensinar o combate e fechar com um boss tutorial para introduzir a mecânica de confronto final.
	- Critério de aceitação:
		- Dado que a fase tutorial está ativa,
		- Quando o jogador avança para a direita e elimina os inimigos em sequência,
		- Então o caminho se abre para o encontro com a Boitata.
		- Dado que a Boitata foi ativada como boss final da fase,
		- Quando o jogador derrota a criatura,
		- Então a fase termina e a história avança para o próximo mapa.

## Perguntas em aberto

- O jogador perde a fase ao zerar vida, ou a fase reinicia automaticamente ao cair em combate?


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
