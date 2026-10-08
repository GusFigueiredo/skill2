# Spec: Fases 3 e 4 — Rio Negro

## Incremento solicitado — 2026-10-08

- Criar duas fases ambientadas no Rio Negro usando `teste/sprites/cenario/Fases3e4/background.png` e `chao.png` fornecidos pelo usuário.
- Reutilizar movimento, pulo, ataque, rolada, pausa, HUD, derrota e transição das fases existentes.
- Fase 3: uma onda de três inimigos comuns distribuídos ao longo de uma arena de 2.300 pixels.
- Fase 4: boss fight da Iara com margem seca, água perigosa, sedução, resistência, capangas e janela de ataque; detalhada em `iara-boss-fight.md`.
- Não há buracos nestes trechos. As poças ilustradas no chão fazem parte do cenário.
- A fase 2 desbloqueia e carrega a fase 3; a fase 3 desbloqueia e carrega a fase 4. A fase 4 retorna ao mapa.
- Reiniciar após morrer carrega a própria fase. O mapa permite repetir fases já desbloqueadas; fases 5 a 7 continuam bloqueadas.
- A mensagem de fase concluída mantém a duração de 2,5 segundos solicitada anteriormente.

## Limite deste incremento

A fase 4 inicialmente usava quatro inimigos comuns. Com a spec e os novos sprites fornecidos, foi substituída pela boss fight da Iara. A Vitória Régia, o feitiço impossível, diálogos e drops ficam para uma etapa posterior por solicitação do usuário. Nesta versão, a Iara pode ser derrotada por golpes normais após os ciclos de resistência e capangas.

## Critérios de aceitação

- As duas cenas carregam os novos cenários e mantêm chão e limites de câmera alinhados à arena.
- Tutorial e Boitatá ficam inativos nas fases do rio.
- A fase 3 termina quando sua onda é derrotada. A fase 4 termina ao zerar a vida da Iara depois de abrir as brechas com resistência e derrota dos capangas.
- A sequência 2 → 3 → 4 → mapa preserva animação de vitória, saída do personagem e fades.
- A progressão é salva sequencialmente e o mapa abre a cena correspondente ao número escolhido.
- Morte e reinício nas fases 3 e 4 não carregam as fases de Ratanabá.
