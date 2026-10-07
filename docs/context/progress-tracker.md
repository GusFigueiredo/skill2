# Acompanhamento do Ciclo

- Ciclo ativo: Ciclo 1 — Núcleo Jogável (continua em andamento conforme `cycle.md`).
- Unidade aprovada nesta sessão: prólogo de Ratanabá e mapa de sete fases, como incremento de fluxo de campanha.
- Entregas: menu → prólogo cinematográfico animado → mapa; a primeira etapa inicia o protótipo existente e seis etapas futuras são exibidas bloqueadas.
- A cutscene contém cinco cenas: caminhada pelas ruínas, descoberta do artefato, travessia temporal, combate contra inimigo e prenúncio de Boitatá/Corpo Seco. Usa animações SpriteFrames já fornecidas.
- Validação automatizada: Godot 4.7.2 importou/parsing o projeto sem erros; `prologue_map_checks.gd`, `menu_checks.gd` e `startup_checks.gd` concluíram sem erros; a cena do prólogo executou por 2.100 frames em modo headless.
- Playtest visual no editor ainda pendente para avaliar ritmo, enquadramento e legibilidade.
- Limitações conhecidas: o protótipo ligado à fase 1 ainda contém a luta contra a Boitatá; nenhum desbloqueio persistente, drop ou fase posterior foi implementado.
- Próxima unidade recomendada: separar o tutorial de Ratanabá da fase 2 da Boitatá antes de implementar a progressão por drops.
- Unidade visual concluída: logo Pindorama do menu centralizada em um contêiner próprio e sombra traseira levemente ampliada; verificações headless do menu atualizadas.
