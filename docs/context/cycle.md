# Estado do Ciclo

- ciclo: Ciclo 1 — Núcleo Jogável
- objetivo: Verificar se o jogador consegue realizar a ação principal em um protótipo jogável: avançar para a direita, eliminar inimigos em sequência e derrotar a Boitata para progredir na história.
- specs-selecionadas:
  - docs/specs/C1-first-increment.md
- status: EM ANDAMENTO
- evidencias-playtest: []
- motivo-avanco: "Ainda está sendo definido o núcleo mínimo de combate e o objetivo da fase tutorial; a próxima decisão precisa fechar a regra de derrota e a passagem entre fases."
- critério-dodge-salvo:
  - O dodge combina movimento rápido em linha reta, efeito visual de smoke bomb e invulnerabilidade discreta, mantendo o estilo de rolada à Dark Souls.
  - Durante o dodge, o personagem fica invulnerável e sem hitbox de contato para não sofrer dano.
  - O dodge atravessa inimigos e projéteis, sem empurrar o personagem para longe do eixo de movimento.
  - O dodge possui cooldown para evitar uso em sequência.
  - O personagem apenas toma dano quando um inimigo realmente encosta nele, com intervalo mínimo de 0,5s entre golpes.

<!-- Atualize este arquivo conforme a sessão avança. -->

- incremento-beat-em-up: Implementado movimento em profundidade, pulo no Espa?o, c?mera lateral, encontros progressivos e vit?ria ao derrotar Boitata; valida??o automatizada e playtest manual pendente.

- tutorial-guiado: Implementadas instru??es contextuais, primeiro encontro sequencial, golpes anunciados, janelas de recupera??o e HUD de cooldowns; dura??o alvo de 3?5 minutos depende de playtest manual.
