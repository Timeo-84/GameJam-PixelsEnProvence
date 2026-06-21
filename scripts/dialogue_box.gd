extends Control
# ─────────────────────────────────────────────
#  DIALOGUE BOX  –  UI affichant les lignes de dialogue
# ─────────────────────────────────────────────

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/Margin/VBox/TextLabel
@onready var continue_label: Label = $Panel/Margin/VBox/ContinueLabel
@onready var portrait_rect: ColorRect = $Panel/Portrait
@onready var portrait_emoji: Label = $Panel/PortraitEmoji

var PORTRAIT_COLORS: Dictionary = {
	"mentor":  Color(0.3, 0.5, 0.2),
	"tourist": Color(0.7, 0.2, 0.3),
	"hero":    Color(0.2, 0.4, 0.8),
	"alert":   Color(0.8, 0.1, 0.1),
}
var PORTRAIT_EMOJIS: Dictionary = {
	"mentor":  "👨‍🌾",
	"tourist": "🕶️",
	"hero":    "🦸",
	"alert":   "🚨",
}

var _full_text: String = ""
var _typing_done: bool = false
var _char_index: int = 0
var _typing_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.line_displayed.connect(_on_line_displayed)

func _input(event: InputEvent) -> void:
	# Ne pas capturer l'input si le dialogue est déjà terminé (même si la boîte est encore visible)
	if not visible or not DialogueManager.is_active:
		return
	# Avancer avec ENTREE ou E (pas ESPACE pour éviter le conflit avec extinguish)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if not _typing_done:
			_skip_typing()
		else:
			DialogueManager.next_line()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not _typing_active:
		return
	# Fait défiler le texte caractère par caractère via _process (sans tween ni lambda)
	_char_index += int(delta * 40.0)  # ~40 caractères/seconde
	if _char_index >= _full_text.length():
		_char_index = _full_text.length()
		_typing_active = false
		_typing_done = true
		continue_label.visible = true
	text_label.text = _full_text.substr(0, _char_index)

func _skip_typing() -> void:
	_typing_active = false
	_char_index = _full_text.length()
	text_label.text = _full_text
	_typing_done = true
	continue_label.visible = true

func _on_dialogue_started() -> void:
	visible = true
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)

func _on_dialogue_finished() -> void:
	_typing_active = false
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

func _on_line_displayed(text: String, speaker: String, portrait: String) -> void:
	speaker_label.text = speaker
	_full_text = text
	_char_index = 0
	_typing_done = false
	_typing_active = true
	continue_label.visible = false
	text_label.text = ""

	# Portrait
	var pcol: Color = PORTRAIT_COLORS.get(portrait, Color.GRAY)
	portrait_rect.color = pcol
	var pemoji: String = PORTRAIT_EMOJIS.get(portrait, "❓")
	portrait_emoji.text = pemoji

	# Couleur du speaker
	match portrait:
		"mentor":  speaker_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.4))
		"tourist": speaker_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		"hero":    speaker_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		"alert":   speaker_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		_:         speaker_label.add_theme_color_override("font_color", Color.WHITE)
