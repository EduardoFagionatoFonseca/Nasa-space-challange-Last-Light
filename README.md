# LAST LIGHT

Jogo curto de estratégia e sobrevivência lunar para Godot 4.7. Mantenha uma pequena base ativa por sete dias e prepare três etapas de resgate. Uma partida leva aproximadamente 10 a 15 minutos. Todo o texto do jogo está em português.

## Jogar

1. Instale o [Godot 4.7](https://godotengine.org/download/windows/) ou use a versão executável, se incluída na entrega.
2. Abra esta pasta como projeto no Godot e execute com **F5**.
3. Clique em **Iniciar missão**. Escolha até duas ações por dia, examine o estado da base e encerre o dia quando estiver pronto.
4. Clique nos módulos do cenário para ler sua função e, quando houver uma ação associada, executá-la. **Esc** abre a pausa.

O jogo salva automaticamente após cada ação e a cada mudança de dia. A opção **Continuar** retoma a campanha. **Reiniciar** substitui o save atual.

## Regras rápidas

- Energia, oxigênio, água e suprimentos precisam ficar acima de zero.
- O abrigo precisa de integridade **60 ou mais** ao terminar o dia 4.
- Conclua as **três etapas do resgate** antes de terminar o dia 7.
- As ações mostram custos, resultados e dicas ao passar o cursor. A previsão avisa os principais eventos futuros.
- A anomalia do dia 3 é uma investigação científica opcional que aumenta a pontuação.

Os números são **unidades didáticas de jogo**, não medições de uma missão real. Consulte [mecânicas](docs/GAME_DESIGN.md) e [ciência](docs/SCIENCE.md).

## Estrutura

- `scripts/mission_config.gd`: custos, ganhos, textos e referências curtas.
- `scripts/mission_model.gd`: regras, eventos, turnos, vitória e derrota.
- `scripts/save_manager.gd`: save em `user://`.
- `scripts/lunar_diorama.gd`: base lunar 3D, animações e seleção.
- `scripts/main.gd`: menus, HUD e ligação entre interface e campanha.
- `scripts/soundscape.gd`: trilha e efeitos sonoros gerados por código.
- `assets/kenney_space_kit/`: modelos 3D CC0 com licença incluída.
- `tests/`: verificações automatizadas.

## Testes

Com `godot` no PATH, a partir desta pasta:

```text
godot --headless --path . --script res://tests/model_test.gd
godot --headless --path . --script res://tests/ui_test.gd
godot --headless --path . --script res://tests/assets_test.gd
godot --headless --path . --script res://tests/balance_test.gd
```

Veja os resultados executados em [TEST_REPORT.md](docs/TEST_REPORT.md).

## Exportação

Abra o projeto no Godot 4.7. Em **Projeto > Exportar**, instale os templates **da mesma versão** do editor. Exporte os presets **Windows Desktop** e **Web** para `build/`. O renderizador é **GL Compatibility**, adequado ao caminho WebGL do Godot 4. O jogo não requer servidor ou API; a build web pode precisar de um servidor HTTP local para ser aberta no navegador, conforme as regras do navegador.

O [workflow de builds no GitHub](https://github.com/EduardoFagionatoFonseca/Nasa-space-challange-Last-Light/actions/workflows/build.yml) executa os testes e publica os pacotes Windows e Web como artefatos. Abra uma execução concluída para baixá-los. Os artefatos expiram conforme a política do GitHub; o projeto e os presets permanecem no repositório para nova exportação.

## Créditos

Conceito, código, interface, terreno 3D e áudio procedural foram criados para LAST LIGHT. Modelos selecionados do [Kenney Space Kit](https://kenney.nl/assets/space-kit), licença **CC0**: veja [License.txt](assets/kenney_space_kit/License.txt) e [ASSETS.md](docs/ASSETS.md). Motor: Godot 4.7. Fontes científicas públicas da NASA constam em [SCIENCE.md](docs/SCIENCE.md). Este jogo é um projeto independente e não é afiliado nem endossado pela NASA.
