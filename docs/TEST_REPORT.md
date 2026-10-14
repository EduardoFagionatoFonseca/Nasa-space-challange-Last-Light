# Relatório de testes — 14/10/2026

Ambiente local: Godot 4.7 estável, Windows, renderizador GL Compatibility, 1280 × 720. Os testes foram executados com o editor original da mesma versão.

## Verificações concluídas

- `model_test.gd`: estado inicial, custo de ações, eventos dos sete dias, reparos, caminho completo de vitória, salvamento e derrota na tempestade.
- `balance_test.gd`: vitória com e sem investigação científica (pontuações 125 e 114), falha por resgate incompleto, falha de abrigo e falha por oxigênio zerado.
- `ui_test.gd`: iniciar missão, avançar pelos sete dias via interface do jogo, salvar e restaurar a vitória.
- `assets_test.gd`: os sete modelos Kenney importam como meshes válidos e têm dimensões não nulas.
- Captura visual local da cena principal em 1280 × 720: módulos, barras, botões, iluminação e textos aparecem no quadro.
- Pacote PCK exportado pelo Godot 4.7 e iniciado com o executável Godot 4.7 para Windows. O processo encerrou normalmente tanto em modo gráfico quanto em modo sem janela.

## Limitações verificadas

- O computador tem templates de exportação 4.6.1, incompatíveis com pacotes 4.7. Uma tentativa de usar o executável de template antigo falhou com `Pack version unsupported: 4`; ele foi substituído pela versão 4.7 na cópia local. O diretório `build/windows/` contém um pacote portátil funcional composto pelo executável do editor Godot 4.7 e `LAST_LIGHT.pck`, maior que uma exportação normal.
- A build HTML5 ainda precisa dos templates de exportação 4.7. O workflow do GitHub baixa os templates correspondentes e tenta gerar Windows e Web; seu resultado precisa ser conferido na aba Actions. Nenhuma build web foi declarada testada localmente.
- O teste de interface em modo sem janela termina com aviso de objetos remanescentes do próprio processo de teste, depois de reportar sucesso. Não houve erro de script ou falha de jogo nos cenários verificados.

## Próxima validação humana

Jogar uma partida completa em um PC diferente, conferir legibilidade na resolução alvo e abrir a build Web em navegador compatível depois da exportação. A automação verifica o fluxo programático; não mede diversão nem acessibilidade.
