# ADR-002: Reutilização do combate nas fases do Rio Negro

- Data: 2026-10-08
- Status: aceito no incremento das fases 3 e 4

## Contexto

As fases de Ratanabá já compartilham controles, HUD e animação de saída. Acrescentar duas cópias completas do script e da cena faria ajustes nesses sistemas divergirem entre regiões.

## Decisão

- Extrair a configuração dos encontros de `Level1.gd` para `_setup_encounters()`.
- `RioNegro.gd` herda o comportamento existente e configura apenas inimigos, arena, câmera e ausência de buracos.
- `rio_negro3.tscn` herda `main.tscn` e substitui script e texturas; `rio_negro4.tscn` herda a cena do rio e altera índice e destino.
- O índice exportado `stage_index` identifica a conclusão da fase no save.
- `CampaignProgress.gd` concentra o caminho das quatro cenas implementadas para o mapa.
- Reinício usa `scene_file_path`, evitando escolher uma cena pela presença do tutorial.

## Consequências

O combate e as transições continuam compartilhados. A cena herdada ainda contém os nós inativos de tutorial e Boitatá, como já ocorre na fase 1; eles não participam dos encontros do rio. A fase 4 usa inimigos comuns enquanto a Iara aguarda implementação específica.
