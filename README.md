# LAST LIGHT

Jogo curto de exploração e sobrevivência lunar para Godot 4.7. Caminhe pela base, mantenha os sistemas vitais e prepare o resgate antes do fim do sétimo dia. Cada dia dura 60 segundos. Todo o texto do jogo está em português.

![Astronauta explorando a base lunar de LAST LIGHT](media/gameplay.png)

## Jogar

1. Instale o [Godot 4.7](https://godotengine.org/download/windows/) ou use a versão executável, se incluída na entrega.
2. Abra esta pasta como projeto no Godot e execute com **F5**.
3. Clique em **Iniciar missão**. Leia o objetivo geral e procure os módulos pelo marcador luminoso.
4. Use **WASD** ou as **setas** para andar. Também é possível clicar no cenário ou em um módulo para caminhar até ele.
5. Perto de um módulo, pressione **E** para iniciar o reparo. Os desafios incluem calibrar com **Espaço**, escolher uma sequência e diagnosticar uma falha. Cinco erros bloqueiam aquele reparo até o dia seguinte e gastam recursos.
6. Volte ao habitat quando o O₂ do traje baixar: **E** entra ou sai, **F** recarrega o traje usando a reserva da base. Durante o alerta solar, procure abrigo imediatamente. **Esc** pausa ou cancela um reparo.

![Calibração de um reparo na antena](media/repair.png)

![Interior do habitat e estação de recarga do traje](media/interior.png)

![Sequência de reparo dos painéis](media/sequence.png)

O jogo salva automaticamente após cada reparo e a cada mudança de dia. A opção **Continuar** retoma a campanha.

## Regras rápidas

- Energia, oxigênio da base, água e suprimentos precisam ficar acima de zero. O O₂ do traje também pode acabar durante a exploração.
- O abrigo precisa de integridade **60 ou mais** no dia 4; a tempestade pode encerrar a missão por exposição.
- Conclua as **três etapas de contato** e prepare a zona de pouso antes de terminar o dia 7.
- O marcador e a frase no canto superior esquerdo mostram o próximo reparo sugerido. Você também pode escolher outro módulo.
- Luzes vermelhas sinalizam avarias; os quatro indicadores compactos mostram os recursos vitais.
- Investigue a cratera que aparece no dia 3 para planejar uma aproximação segura da nave.

Os números são **unidades didáticas de jogo**, não medições de uma missão real. Consulte [mecânicas](docs/GAME_DESIGN.md) e [ciência](docs/SCIENCE.md).

## Estrutura

- `scripts/mission_config.gd`: custos, ganhos, textos e referências curtas.
- `scripts/mission_model.gd`: regras, eventos, turnos, vitória e derrota.
- `scripts/save_manager.gd`: save em `user://`.
- `scripts/lunar_diorama.gd`: base lunar 3D, astronauta e sinais de avaria.
- `scripts/main.gd`: caminhada, calibração, objetivos, interface e campanha.
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
