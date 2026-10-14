class_name MissionConfig
extends RefCounted

const MAX_RESOURCE := 100
const START := {"energy": 70, "oxygen": 66, "water": 64, "supplies": 75}
const ACTIONS := {
	"solar": {"title": "Reparar painéis", "cost": {"energy": 3, "supplies": 6}, "gain": {"energy": 20}, "site": "solar", "tip": "Restaura a geração e recupera energia da bateria."},
	"oxygen": {"title": "Produzir oxigênio", "cost": {"energy": 8, "water": 4}, "gain": {"oxygen": 23}, "site": "oxygen", "tip": "Eletrólise usa eletricidade para separar água em oxigênio e hidrogênio."},
	"water": {"title": "Reciclar água", "cost": {"energy": 6, "supplies": 3}, "gain": {"water": 19}, "site": "water", "tip": "Recupera água usada pela tripulação e troca filtros se necessário."},
	"food": {"title": "Cultivar alimentos", "cost": {"energy": 7, "water": 6}, "gain": {"supplies": 19}, "site": "greenhouse", "tip": "Produção acelerada é uma simplificação didática."},
	"shelter": {"title": "Reforçar abrigo", "cost": {"energy": 5, "supplies": 9}, "gain": {}, "site": "shelter", "tip": "Aumenta a proteção antes da tempestade solar."},
	"rescue": {"title": "Preparar resgate", "cost": {"energy": 10, "supplies": 6}, "gain": {}, "site": "antenna", "tip": "Complete três etapas: sinal, rota e baliza de pouso."}
}
const ACTION_ORDER := ["solar", "oxygen", "water", "food", "shelter", "rescue"]
const DAY_TITLES := [
	"", "Primeiros procedimentos", "Energia comprometida", "Alerta solar",
	"Tempestade solar", "Crise hídrica", "Preparação final", "Last Light"
]
const DAY_BRIEFS := [
	"",
	"A Terra está em silêncio. O resgate chega em sete dias. Escolha até duas ações e mantenha os sistemas vitais.",
	"Micrometeoritos danificaram os painéis solares. A geração de energia caiu até o reparo.",
	"Um aumento de partículas solares foi previsto para amanhã. O abrigo precisa de integridade 60 ou mais.",
	"A tempestade chegou. O abrigo será testado quando o dia terminar; a geração solar está reduzida.",
	"O filtro de recuperação de água perdeu eficiência. Reciclar água também troca o filtro.",
	"Um vazamento de oxigênio e uma falha na antena exigem resposta. Produzir oxigênio sela o vazamento; preparar resgate restaura a antena.",
	"A nave de resgate está próxima. Termine as três etapas e preserve os sistemas vitais até o fim do dia."
]
const SCIENCE := {
	"solar": "A energia solar é uma opção para a superfície lunar, mas painéis e armazenamento precisam resistir à poeira e aos ciclos de iluminação. Fonte: NASA Lunar Surface Technology.",
	"oxygen": "O sistema ECLSS da NASA produz oxigênio por eletrólise da água. Nosso custo por ação é uma unidade didática, não um dado operacional.",
	"water": "A NASA recupera água de condensado e outros fluxos, filtra, oxida e testa sua qualidade. A taxa usada no jogo é simplificada.",
	"greenhouse": "Plantas precisam de água, luz, ar e ambiente controlado. O ciclo de colheita do jogo é acelerado para caber em sete turnos.",
	"shelter": "A Lua não oferece a mesma proteção atmosférica da Terra. Eventos solares tornam a blindagem e o abrigo críticos.",
	"antenna": "Sinalização, navegação e uma área de pouso segura são necessidades de uma operação de resgate. As três etapas são um modelo de jogo.",
	"habitat": "Sistemas de suporte à vida precisam manter ar respirável, água e condições seguras para a tripulação."
}

