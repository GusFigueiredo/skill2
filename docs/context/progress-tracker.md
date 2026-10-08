# Acompanhamento do Ciclo

- Ciclo ativo: Ciclo 1 — Núcleo Jogável (continua em andamento conforme `cycle.md`).
- Unidade atual solicitada: boss fight da Iara na fase 4, incluindo sedução, resistência, queda, capangas, janela de ataque e derrota normal; Vitória Régia adiada.
- Entregas: menu → prólogo cinematográfico animado → mapa; a primeira etapa inicia o protótipo existente e seis etapas futuras são exibidas bloqueadas.
- A cutscene contém cinco cenas: caminhada pelas ruínas, descoberta do artefato, travessia temporal, combate contra inimigo e prenúncio de Boitatá/Corpo Seco. Usa animações SpriteFrames já fornecidas.
- Validação automatizada: Godot 4.7.2 importou/parsing o projeto sem erros; `prologue_map_checks.gd`, `menu_checks.gd` e `startup_checks.gd` concluíram sem erros; a cena do prólogo executou por 2.100 frames em modo headless.
- Playtest visual no editor ainda pendente para avaliar ritmo, enquadramento e legibilidade.
- Estado jogável atual: fase 1 de tutorial, fase 2 da Boitatá, fase 3 do Rio Negro com inimigos comuns e fase 4 da Iara; desbloqueio persistente e escolha das quatro fases pelo mapa.
- Novas cenas: `teste/rio_negro3.tscn` e `teste/rio_negro4.tscn`. Usam `background.png` e `chao.png` de `Fases3e4`; compartilham controles, HUD, pausa, derrota e saída de fase.
- Validação do Rio Negro: `rio_negro_checks.gd`, `ratanaba_stage_checks.gd`, `campaign_checks.gd` e `stage_transition_checks.gd` passaram no Godot 4.7.2; capturas renderizadas das duas fases conferidas. Ritmo e dificuldade ainda exigem playtest manual.
- Iara: 6 de vida e 1 de dano por golpe do jogador; 8 entradas alternadas com cooldown de 0,2s quebram o transe. Surge um perseguidor lento 100px à esquerda do jogador durante o encanto, depois 2/3 capangas; todos precisam morrer para abrir 2s de vulnerabilidade. Água ativa não tira vida aos poucos: mata após 3s contínuos. Zoom padrão 1,8 e hitbox por pose, incluindo rosto e cauda. O jogador inicia em `(440, 460)`, na terra firme com a Iara visível.
- Validação da Iara: `iara_checks.gd` passou, cobrindo golpe real, ciclo, perigo da água, afogamento, pausa, conclusão e reinício. Checks de Rio Negro, Ratanabá, ataque direcional, rolada e contato também passaram; capturas dos estados conferidas.
- Revisão solicitada pelo playtest: checks atualizados confirmam cooldown em 0,49/0,5s, perseguição/dano do novo inimigo, golpes no rosto e na cauda e morte por água em 2,99/3s, inclusive durante rolada. Conferência visual confirma zoom e tamanho padrão; ataque direcional continua passando.
- Apresentação atual da Iara: idle inicial, preparação com sprites de sedução, lançamento visível antes da hipnose; ícones A/D acima da cabeça com tremor alternado e versão pressionada; zoom 2,43 no transe com retorno para 1,8. Novos efeitos de carga, projétil e aura em controlador visual próprio. `iara_checks.gd` passou e capturas renderizadas foram conferidas.
- Limitações conhecidas: Vitória Régia, feitiço impossível, ataques secundários de cabelo/espelho/knockback e drops ficam para depois. Fases 5–7 continuam bloqueadas. Ritmo e dificuldade aguardam playtest manual.
- Próxima unidade recomendada: playtestar a resistência e o alcance da brecha, depois implementar a intervenção da Vitória Régia conforme a spec.
- Unidade visual concluída: logo Pindorama do menu centralizada em um contêiner próprio e sombra traseira levemente ampliada; verificações headless do menu atualizadas.
