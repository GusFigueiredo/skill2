# ADR-001: Prólogo e mapa de fases em cenas separadas

- Status: Aceito
- Contexto: o menu iniciava diretamente a cena de combate, enquanto a campanha planejada possui sete fases e uma introdução narrativa.
- Decisão: adicionar cenas independentes para o prólogo e o mapa; usar `SceneTransition` para carregar o prólogo e a fase; exibir sete marcos, habilitando apenas Ratanabá. O prólogo é uma sequência de cinco beats ilustrados com SpriteFrames reutilizados e formas/cenários compostos na cena; os beats avançam automaticamente e aceitam avanço manual.
- Consequências: a navegação fica desacoplada do combate e pode crescer por etapas. A cutscene funciona sem arte externa, mas ainda não tem arte própria para o historiador, Cuca ou Corpo Seco. O mapa ainda não salva progresso; seis etapas continuam bloqueadas e a cena da fase 1 ainda inclui a Boitatá.
- Alternativa descartada: adicionar cutscene e seleção diretamente à cena de combate, o que misturaria apresentação, navegação e gameplay.
