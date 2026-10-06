Sprites integrados e tamanhos atualizados: protagonista/inimigos aumentados em 25% (escala 0.75), Boitatá em 50% (escala 1.2). Pés alinhados ao chão. Poses extraídas da imagem original, sem fundo; original preservado.

Animações em sprites/characters/{player,enemy,boitata}.tres, PNGs individuais nas pastas correspondentes. scripts/CharacterVisual.gd seleciona as animações pelo estado do ator. build_character_sprites.gd permite regenerar os recortes.

Validação concluída: visual_checks.gd, contact_checks.gd, boitata_checks.gd e menu_checks.gd passaram. Os testes de esquiva e duração de ataque foram atualizados para o comportamento atual. Godot headless emite aviso do certificado do sistema e avisos de objetos ao sair, sem falhas funcionais nesses testes.

A remoção de fundo é automática por cores dos painéis; pode remover alguns pixels escuros de detalhes da arte. Há sprites/characters/preview.png para conferir a aparência sobre fundo contrastante. Ajustes finos de contorno, se desejados, podem ser feitos nos PNGs individuais.
