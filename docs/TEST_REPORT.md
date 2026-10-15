# Relatório de testes — 15/10/2026

Ambiente local: Godot 4.7 estável, Windows, renderizador GL Compatibility, capturas em 1280 × 720.

## Verificações concluídas

- `model_test.gd`: relógio e consumo contínuo, oxigênio do traje, recarga com reserva da base, inspeção da cratera, preparação do pouso, cinco erros de reparo, salvamento e vitória ou derrota.
- `balance_test.gd`: campanha guiada dos sete dias e consequências de recursos e requisitos de resgate.
- `ui_test.gd`: entrada no habitat, perigos de oxigênio e radiação, diferentes reparos e campanha até a vitória.
- `assets_test.gd`: sete modelos Kenney carregam como meshes válidos.
- Capturas visuais: exterior, interior, cratera, tempestade e sequência de reparo. O interior foi ajustado após uma captura que mostrou luz excessiva.

Os quatro testes passaram localmente em 15/10/2026. A automação verifica regras e fluxos; a sensação de movimento, a dificuldade e a legibilidade em outros monitores ainda exigem partidas humanas.

## Exportação

O [workflow de builds](https://github.com/EduardoFagionatoFonseca/Nasa-space-challange-Last-Light/actions/workflows/build.yml) executa os mesmos testes e publica pacotes Windows e Web. A execução desta revisão deve ser consultada na página do workflow depois que o GitHub terminar a construção.
