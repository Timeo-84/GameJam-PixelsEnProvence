extends Control
# ─────────────────────────────────────────────
#  END SCREEN  –  Victoire ou Game Over
# ─────────────────────────────────────────────

@onready var title_label: Label = $Center/VBox/Title
@onready var message_label: Label = $Center/VBox/Message
@onready var score_label: Label = $Center/VBox/ScoreLabel
@onready var trash_label: Label = $Center/VBox/TrashLabel
@onready var fire_label: Label = $Center/VBox/FireLabel
@onready var retry_btn: Button = $Center/VBox/RetryBtn
@onready var menu_btn: Button = $Center/VBox/MenuBtn
@onready var bg: ColorRect = $Background
@onready var stars: GPUParticles2D = $Stars

func _ready() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

	if GameState.game_won:
		_show_victory()
	else:
		_show_game_over()

func _show_victory() -> void:
	title_label.text = "🏆 La Sainte-Victoire est sauvée !"
	title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	message_label.text = "Grâce à toi, la forêt de Provence et ses espèces\nprotégées peuvent vivre un jour de plus.\n\nTu es un véritable Gardien de la Nature !"
	bg.color = Color(0.1, 0.2, 0.1, 1.0)
	stars.emitting = true
	_fill_stats()

func _show_game_over() -> void:
	title_label.text = "💔 L'incendie a ravagé la forêt..."
	title_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	message_label.text = "Des hectares de pins centenaires sont partis en fumée.\nCes forêts mettront 100 ans à repousser.\n\nRecommence et protège la Provence !"
	bg.color = Color(0.2, 0.08, 0.05, 1.0)
	stars.emitting = false
	_fill_stats()

func _fill_stats() -> void:
	score_label.text = "Score final : %d pts" % GameState.score
	trash_label.text = "Déchets ramassés : %d 🗑" % GameState.trash_count
	fire_label.text = "Foyers éteints : %d 🔥" % GameState.fires_extinguished

func _on_retry() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_menu() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
