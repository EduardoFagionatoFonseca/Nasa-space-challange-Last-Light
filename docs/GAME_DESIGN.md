# Mecânicas e progressão

## Objetivo

Sobreviver a sete dias na Lua e completar três etapas de resgate. O astronauta percorre a base para alcançar cada módulo. O objetivo visível e o marcador luminoso sugerem o próximo reparo, mas o jogador pode escolher outro. Há duas ações por dia. Ações não usadas não são transferidas.

Cada reparo pede duas calibrações com Espaço no momento em que o ponteiro cruza a faixa azul. Errar não consome recursos nem ações. O botão E só funciona perto do módulo, e o dia termina no habitat. O HUD exibe apenas objetivo, indicadores vitais, progresso do resgate e o comando contextual.

## Economia

Os quatro recursos variam de 0 a 100. A base consome 10 energia, 9 oxigênio, 8 água e 7 suprimentos ao fim de cada dia. Painéis íntegros geram 14 energia (5 se danificados); na tempestade do dia 4 geram 3 (1 se danificados). A recuperação de água devolve 5 por dia, reduzida a 2 após a falha do filtro. Vazamento adiciona 6 ao consumo diário de oxigênio. Se qualquer recurso chegar a zero após o balanço, a missão termina.

| Ação | Custo | Efeito |
| --- | --- | --- |
| Reparar painéis | 3 energia, 6 suprimentos | Restaura geração e dá 20 energia imediata. |
| Produzir oxigênio | 8 energia, 4 água | Dá 23 oxigênio e sela eventual vazamento. |
| Reciclar água | 6 energia, 3 suprimentos | Dá 19 água e substitui eventual filtro defeituoso. |
| Cultivar alimentos | 7 energia, 6 água | Dá 19 suprimentos. Ciclo acelerado para o jogo. |
| Reforçar abrigo | 5 energia, 9 suprimentos | Dá 28 integridade, até 100. |
| Preparar resgate | 10 energia, 6 suprimentos | Avança uma das três etapas e restaura a antena se falhou. |

## Sete dias

1. **Primeiros procedimentos:** antena e oxigênio são os primeiros destinos sugeridos.
2. **Energia comprometida:** falha solar; reparar painéis devolve produção normal.
3. **Alerta solar:** previsão da tempestade; anomalia de rádio opcional custa 4 energia e uma ação.
4. **Tempestade solar:** geração reduzida; abrigo deve ter integridade 60 ao final. A tempestade retira 25 de integridade.
5. **Crise hídrica:** filtro falha; reciclar água restaura eficiência.
6. **Falhas múltiplas:** vazamento de oxigênio e antena desalinhada. As ações relevantes resolvem os problemas.
7. **Last Light:** últimos preparativos e resolução.

Vitória exige os quatro recursos positivos, abrigo com pelo menos 20 de integridade e resgate 3/3 ao fim do dia 7. A pontuação considera sobrevivência, recursos restantes, integridade, etapas de resgate e a pesquisa opcional. A campanha é determinística: os eventos são anunciados e não há rolagens aleatórias que prejudiquem o jogador. A rota sugerida completa os sete dias sem exigir que o jogador descubra previamente uma combinação oculta de ações.

## Escolhas de design

O custo de oportunidade está nas duas ações diárias: a mesma ação que salva um recurso adia proteção ou resgate. A interface evita parágrafos e listas de comandos durante a partida; o cenário indica o objetivo e as falhas. O modelo registra as consequências para salvamento e testes. Os valores são parâmetros de equilíbrio, não unidades físicas.
