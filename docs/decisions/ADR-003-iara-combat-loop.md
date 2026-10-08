# ADR-003: Ciclo de combate da Iara

- Data: 2026-10-08
- Status: implementado no recorte solicitado da fase 4

## Decisão

`IaraBossFight.gd` herda a infraestrutura de `Level1.gd`, mas controla a luta por uma máquina de estados independente: idle inicial, preparação, lançamento, sedução, queda, capangas, vulnerabilidade, afogamento e derrota. A conclusão automática por ondas do controlador anterior não é executada nesta fase.

`Iara.gd` reaproveita geometria de combate e animação de derrota dos inimigos, aceitando dano apenas no estado de vulnerabilidade. O jogador usa o ataque existente, com os mesmos valores da Boitatá: boss com 6 de vida e golpe do jogador com 1 de dano.

O jogador recebe um efeito temporário de sedução que reduz movimento, soma arrasto e consulta entradas alternadas com cooldown de 0,2s, bloqueando ataque, pulo e rolada. Um inimigo lento é invocado 100px à esquerda do jogador durante esse estado. O restante das fases mantém o comportamento normal. O afogamento fatal termina após três segundos; permanecer na água por três segundos causa morte direta sem uma contagem adicional ou dano gradual.

As animações usam `AtlasTexture` com regiões específicas e margens para alinhar os pés, sem alterar o sprite sheet original. Capangas são instâncias da cena reutilizável de inimigo, agora com a barra de vida exigida pelo script.

A área de dano da Iara usa os pixels visíveis do frame atual e as margens do atlas, com posição e tamanho próprios por pose. A colisão de movimento continua baseada nos pés. A câmera usa o zoom padrão 1,8 e acompanha o jogador; no transe, aproxima para 2,43 e centra o corpo do personagem, restaurando a configuração original ao terminar.

`TranceKeyPrompt.gd` cuida exclusivamente dos ícones acima da cabeça e da indicação da próxima tecla. `IaraSpellEffects.gd` desenha os efeitos por fase; nenhum deles altera as regras de combate ou aplica dano. Os sprites pressionados respondem à entrada real do teclado e ao feedback de resistência aceita.

## Limites

O feitiço impossível e a Vitória Régia foram adiados explicitamente pelo usuário. Até essa etapa, a Iara pode ser derrotada normalmente e a fase retorna ao mapa. Cabelo, espelho e onda de knockback não fazem parte deste incremento do ciclo principal.
