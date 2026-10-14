# Checkpoints por trecho

## Incremento solicitado — 2026-10-13

- Todas as quatro fases implementadas salvam automaticamente um checkpoint na entrada.
- Fase 1: checkpoint adicional ao começar a lição de combate, depois de atravessar o buraco. Retomar repete a entrada do inimigo e a lição de ataque/esquiva, sem repetir as lições de movimentação.
- Fase 2: checkpoint ao entrar na segunda onda e outro após aterrissar além do último buraco, antes da apresentação da Boitatá.
- Fase 3: checkpoint na entrada do trecho do Rio Negro.
- Fase 4: checkpoint inicial na primeira onda, outro na segunda onda depois do único buraco e outro na margem seca, antes da cutscene da Iara. Retomar a bossfight não repete as cinco criaturas do caminho.
- A tela de morte oferece “Voltar ao checkpoint”. O personagem volta com vida completa; os inimigos do trecho atual e a bossfight reiniciam. Ondas anteriores concluídas não reaparecem ao retomar os trechos internos das fases 2 e 4.
- O checkpoint mais recente persiste em `user://campaign_progress.cfg`, junto dos desbloqueios, e serve ao retorno após a morte. A opção “Continuar do checkpoint” foi removida do menu por solicitação; “Jogar” segue para o prólogo e o mapa de fases.
- Escolher uma fase pelo mapa inicia uma nova tentativa dessa fase e salva seu checkpoint inicial. Concluir a fase limpa o checkpoint daquela tentativa; a fase seguinte salva um novo ponto ao carregar.
- O aviso “Checkpoint salvo” ou “Checkpoint retomado” aparece brevemente no HUD.

Implementação: `CampaignProgress.gd`, `SceneTransition.gd`, `Level1.gd`, `TutorialBalloon.gd`, `GameMenu.gd` e `DeathPresentation.gd`.

Validação: `teste/checkpoint_checks.gd` cobre retorno após morte em cada trecho, tutorial restaurado, ondas anteriores removidas, vida completa, reinício da Iara, desbloqueios preservados e seleção de fase pelo mapa. A opção `--verify-persistence` verifica que o checkpoint sobrevive em um novo processo, que o menu não oferece retomada e que “Jogar” mantém o caminho pelo prólogo e mapa, usando o mesmo APPDATA isolado.
