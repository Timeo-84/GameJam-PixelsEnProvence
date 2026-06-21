extends Node

# ─────────────────────────────────────────────
#  DIALOGUE MANAGER  –  Autoload singleton
# ─────────────────────────────────────────────

signal dialogue_started()
signal dialogue_finished()
signal line_displayed(text: String, speaker: String, portrait: String)

var is_active: bool = false
var _lines: Array = []
var _index: int = 0
var _callback: Callable

# Base de données des dialogues du jeu
const DIALOGUES: Dictionary = {
	"mentor_intro": [
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Ah, te voilà enfin ! Je t'attendais, jeune homme. Je suis Marcel, garde forestier depuis 30 ans ici à la Sainte-Victoire."},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Aujourd'hui le risque incendie est EXTRÊME. Indice 5 sur 5. La végétation n'a pas eu de pluie depuis 6 semaines."},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Prends cette gourde. Elle te permettra d'éteindre de petits départs de feu. Chaque goutte compte !"},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Et ramasse les déchets dangereux que tu trouveras : bouteilles en verre, canettes... Tout peut déclencher un incendie par temps de canicule."},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Utilise [E] pour interagir, [ESPACE] pour asperger d'eau, [F] pour ramasser les déchets. Bonne chance, Gardien !"},
	],
	"mentor_encourage": [
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Du courage ! La forêt a besoin de toi. Continue de ramasser les déchets et garde ta gourde pour les urgences."},
	],
	"tourist_first": [
		{"speaker": "Touriste Négligent", "portrait": "tourist",
		 "text": "Hé, c'est une belle montagne ici ! Je prends quelques photos... *jette son sandwich par terre*"},
		{"speaker": "Héros", "portrait": "hero",
		 "text": "Excusez-moi, vous venez de jeter votre emballage ! C'est une réserve naturelle ici !"},
		{"speaker": "Touriste Négligent", "portrait": "tourist",
		 "text": "Oh, c'est rien... Il y a sûrement des gens payés pour nettoyer, non ? *allume une cigarette*"},
		{"speaker": "Héros", "portrait": "hero",
		 "text": "Éteignez ça immédiatement ! Le risque d'incendie est au maximum aujourd'hui ! C'est dangereux !"},
		{"speaker": "Touriste Négligent", "portrait": "tourist",
		 "text": "Pff, vous exagérez... *jette le mégot à moitié éteint dans les broussailles* Bonne journée !"},
	],
	"fire_alarm": [
		{"speaker": "Système d'alerte", "portrait": "alert",
		 "text": "⚠️ ALERTE INCENDIE ! Un départ de feu a été détecté sur le sentier nord-est !"},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "C'est le mégot de ce touriste ! Vite, utilise ta gourde pour éteindre les flammes avant qu'elles se propagent !"},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Tu as 2 minutes avant que le feu devienne incontrôlable. Cours aux sources pour recharger ta gourde !"},
	],
	"victory": [
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Incroyable ! Tu as réussi à éteindre tous les foyers ! La Sainte-Victoire est sauvée !"},
		{"speaker": "Touriste Négligent", "portrait": "tourist",
		 "text": "Je... je suis vraiment désolé. Je ne réalisais pas le danger que je représentais. Je n'aurais jamais dû..."},
		{"speaker": "Héros", "portrait": "hero",
		 "text": "C'est pour ça qu'on sensibilise. La nature n'a pas de voix. C'est à nous de la protéger."},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Grâce à toi, la forêt de pins centenaires et les espèces protégées qui y vivent sont sauvées. Tu es un vrai Gardien !"},
	],
	"game_over": [
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Le feu... il s'est trop propagé. Des hectares de forêt sont perdus. Des espèces protégées, des décennies de croissance..."},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Ne te décourage pas. L'incendie de la Sainte-Victoire de 1989 a détruit 9000 hectares. Ces forêts mettent 100 ans à repousser."},
		{"speaker": "Garde Forestier Marcel", "portrait": "mentor",
		 "text": "Recommence et protège ces merveilles de Provence. La nature compte sur toi."},
	],
	"water_source": [
		{"speaker": "Indication", "portrait": "alert",
		 "text": "💧 Source naturelle ! Tu remplis ta gourde. Eau rechargée à 100% !"},
	],
}

func start_dialogue(key: String, callback: Callable = Callable()) -> void:
	if not DIALOGUES.has(key):
		push_warning("Dialogue key not found: " + key)
		return
	is_active = true
	_lines = DIALOGUES[key]
	_index = 0
	_callback = callback
	dialogue_started.emit()
	_show_current()

func next_line() -> void:
	if not is_active:
		return
	_index += 1
	if _index >= _lines.size():
		_end_dialogue()
	else:
		_show_current()

func _show_current() -> void:
	var d: Dictionary = _lines[_index]
	line_displayed.emit(d.get("text", ""), d.get("speaker", ""), d.get("portrait", ""))

func _end_dialogue() -> void:
	is_active = false
	_lines = []
	_index = 0
	dialogue_finished.emit()
	if _callback.is_valid():
		_callback.call()
