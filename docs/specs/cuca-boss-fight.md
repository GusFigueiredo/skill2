# Bossfight da Cuca — laboratório da fase 6

Incremento de 2026-10-16 a partir da proposta aprovada pelo usuário. A luta ocupa o fim do terceiro trecho da fase 6 e aproveita `sprite sheet cuca.png` e `cutscene cuca.png`, preservando as imagens originais. A cutscene final do ritual será definida pelo usuário depois da mecânica.

## Entrada e arena

Após derrotar os quatro inimigos do terceiro trecho e alcançar `x=4200` em terra firme, o jogador entra no laboratório. Um checkpoint `boss` é salvo antes da apresentação. A câmera abre suavemente para mostrar a arena inteira; o protagonista caminha até `(4270,460)` enquanto a Cuca mexe a mistura. O título de entrada usa a apresentação compartilhada dos outros chefes. Os controles e o dano ficam suspensos durante os 2,1 segundos da introdução e retornam ao começar o combate.

O mapa se estende até `x=5200`. A arena vai de `x=4160` a `x=5050`, em `y=340–560`. O caldeirão fica em `(4770,405)` e a Cuca começa em `(4830,475)`. O cenário conserva a caverna sem tochas, com prateleiras de poções, bancada, livro, runas e partículas do caldeirão. A câmera do combate mostra toda a área, mantendo espaço para as ondas e esquivas.

## Combate e leitura

A Cuca tem 18 pontos de vida. O golpe normal tira 1 ponto, usando o mesmo alcance, orientação e cooldown do protagonista. Fora da canalização, ela recebe golpes normalmente. Durante a canalização, uma barreira verde indica proteção; acertá-la produz uma resposta visual e uma dica breve. A interface exibe vida, etapa da luta e uma instrução contextual por vez.

| Ação | Aviso e resposta | Consequência |
| --- | --- | --- |
| Caveira verde | A mão acumula energia, seguida do projétil com rastro. Perto do personagem, um halo dourado e o ícone K indicam a oportunidade. | Atacar na direção da caveira com K a devolve automaticamente ao caldeirão. Desviar, rolar ou saltar também evita o impacto de 2 pontos. |
| Sobrecarga do caldeirão | O projétil devolvido provoca luz, partículas, som e tremor curto. | Outros perigos são removidos; Cuca fica desequilibrada por 4,5 segundos, abrindo espaço para o combo. |
| Poça de veneno | Marcação dourada por 0,95 segundo antes de ativar. | A poça permanece 4,8 segundos; contato tira 1 ponto, com intervalo de 1,1 segundo entre acertos da poça. Pode ser evitada por movimento, salto ou esquiva. |
| Onda rasteira | O caldeirão sinaliza a expansão durante 1,15 segundo. | Uma onda verde cruza a arena. Saltar sobre ela ou rolar evita os 2 pontos de dano. |
| Estalactites | O teto racha e o local de impacto é marcado por 0,85 segundo. | Caem na posição registrada do jogador, sem persegui-lo após o aviso. Cada impacto tira 50% da vida máxima, usando a mesma mecânica da travessia. |

A reflexão responde ao evento de um ataque realmente aceito pelo jogador. K durante cooldown, controle bloqueado, esquiva ou pausa não ganha uma defesa adicional. É necessário estar na profundidade correta, dentro da janela de aproximação e atacar na direção do projétil. Um golpe devolve apenas a caveira válida mais próxima. O projétil devolvido segue automaticamente ao caldeirão e não volta a ferir o jogador.

A Cuca se reposiciona com fumaça e transição curta, sem exigir uma animação de caminhada inexistente no sheet. A preparação, o lançamento e a recuperação usam as poses fornecidas e mantêm seus pés alinhados.

## Três momentos

- **18–13 HP — O caldeirão:** caveiras, veneno isolado e ondas em sequência, permitindo aprender cada resposta.
- **12–7 HP — Magia instável:** duas poças, ataques do teto e combinações de veneno com onda, preservando rotas de fuga.
- **6–1 HP — Último encantamento:** combinações conhecidas em ordem mais intensa e duas estalactites por ataque do teto. Não acrescenta comandos novos.

As transições são sinalizadas por mudança do nome da etapa, partículas e impacto curto. A luta alterna canalização, lançamento e recuperação; não depende de eliminar capangas para liberar o dano na chefe.

## Derrota, morte e continuidade

Ao zerar a vida, a Cuca usa as três poses de queda. Todos os projéteis, poças, ondas e estalactites da luta são desativados e removidos; nenhum golpe tardio pode atingir o jogador. Depois da queda, `CucaBossFight.defeated` aciona `CucaCave._on_cuca_defeated()`, que emite `cuca_defeated`. Esse é o ponto de integração da futura cutscene do ritual.

Até o usuário fornecer o roteiro, o resultado apresenta “Cuca derrotada”, com opções de tentar novamente e voltar ao mapa. Não encena a ressurreição, não conclui a fase 6 na campanha e não libera a fase 7. O checkpoint da luta permanece salvo. A direção narrativa continua sendo: Cuca derrotada consegue concluir o ritual e o protagonista persegue o Corpo-Seco.

Morrer e voltar ao checkpoint reinicia a apresentação e a luta com vida completa para os dois, sem repetir os três grupos da caverna. Pausa congela apresentação, animações, projéteis, avisos, partículas e contadores de ataque. Reiniciar ou sair da cena limpa os perigos e os recursos da tentativa.

## Implementação e validação

- `CucaCave.gd`: entrada, checkpoint, HUD e resultado provisório.
- `CucaFrames.gd`: recortes e âncoras do corpo, ritual, caveira e caldeirão.
- `CucaBossFight.gd` e `CucaBossActor.gd`: estados, etapas, apresentação e vida.
- `CucaSpell.gd` e `CucaHazard.gd`: reflexão, poças e ondas; `CaveStalactite.gd` fornece as quedas do teto.
- `CucaLaboratory.gd`: composição da bancada, frascos, livro e runas.

`cuca_boss_checks.gd` verifica portão de entrada, checkpoint e retry, golpes reais, proteção da canalização, reflexão por K, sobrecarga, veneno, onda e salto, esquiva, estalactites, etapas, pausa e limpeza após a derrota. Os checks da caverna e da campanha verificam o acesso à luta e a progressão pendente. `cuca_boss_preview.gd` captura introdução, laboratório, escudo, lançamento, reflexão, sobrecarga, perigos e derrota em `teste/.validation/cuca-boss-previews/`. As verificações usam saves isolados.
