# Relatório de testes — 14/10/2026

Ambiente local: Godot 4.7 estável, Windows, renderizador GL Compatibility, 1280 × 720. Os testes foram executados com o editor original da mesma versão.

## Verificações concluídas

- `model_test.gd`: estado inicial, custo de ações, eventos dos sete dias, reparos, caminho completo de vitória, salvamento e derrota na tempestade.
- `balance_test.gd`: vitória com e sem investigação científica (pontuações 125 e 114), falha por resgate incompleto, falha de abrigo e falha por oxigênio zerado.
- `ui_test.gd`: iniciar missão, selecionar a antena pelo cenário 3D, executar a ação contextual, avançar pelos sete dias, salvar e restaurar a vitória.
- `assets_test.gd`: os sete modelos Kenney importam como meshes válidos e têm dimensões não nulas.
- Captura visual local da cena principal em 1280 × 720: módulos, barras, botões, iluminação e textos aparecem no quadro.
- Pacote PCK exportado pelo Godot 4.7 e iniciado com o executável Godot 4.7 para Windows. O processo encerrou normalmente tanto em modo gráfico quanto em modo sem janela.
- O [workflow 38605260089](https://github.com/EduardoFagionatoFonseca/Nasa-space-challange-Last-Light/actions/runs/38605260089) concluiu com sucesso na versão mais recente: importação, quatro scripts de teste, exportação Windows e Web e envio de ambos os artefatos.

## Limitações verificadas

- O computador tem templates de exportação 4.6.1, incompatíveis com pacotes 4.7. Uma tentativa de usar o executável de template antigo falhou com `Pack version unsupported: 4`; ele foi substituído pela versão 4.7 na cópia local. O diretório `build/windows/` contém um pacote portátil funcional composto pelo executável do editor Godot 4.7 e `LAST_LIGHT.pck`, maior que uma exportação normal.
- A build Web foi gerada pelo GitHub com templates 4.7, mas ainda não foi aberta no navegador neste ambiente.

## Próxima validação humana

Jogar uma partida completa em um PC diferente, conferir legibilidade na resolução alvo e abrir a build Web em navegador compatível depois da exportação. A automação verifica o fluxo programático; não mede diversão nem acessibilidade.
