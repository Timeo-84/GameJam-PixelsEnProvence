extends CanvasLayer
# ─────────────────────────────────────────────
#  HUD  –  Heads-Up Display
# ─────────────────────────────────────────────

@onready var water_bar: ProgressBar = $MarginContainer/Panel/MarginContainer/VBox/WaterRow/WaterBar
@onready var score_label: Label = $MarginContainer/Panel/MarginContainer/VBox/ScoreLabel
@onready var trash_label: Label = $MarginContainer/Panel/MarginContainer/VBox/TrashLabel

func _ready() -> void:
	# S'assurer que le HUD continue de tourner pendant la pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	GameState.water_changed.connect(_on_water_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.trash_collected.connect(_on_trash_collected)
	
	# Pause du jeu pendant les dialogues
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	
	_refresh()

func _refresh() -> void:
	water_bar.value = GameState.water_level
	score_label.text = "Score : %d" % GameState.score
	trash_label.text = "🗑 Déchets : %d" % GameState.trash_count

func _on_dialogue_started() -> void:
	get_tree().paused = true

func _on_dialogue_finished() -> void:
	get_tree().paused = false

func _on_water_changed(amount: float) -> void:
	var tween := create_tween()
	# Animation plus élastique (bounce)
	tween.tween_property(water_bar, "value", amount, 0.4).set_trans(Tween.TRANS_SPRING)
	
	# Transition fluide de la couleur
	var target_color: Color
	if amount < 25.0:
		target_color = Color(1.0, 0.2, 0.2)
	elif amount < 50.0:
		target_color = Color(1.0, 0.7, 0.2)
	else:
		target_color = Color(0.2, 0.8, 1.0)
		
	var ctween := create_tween()
	ctween.tween_property(water_bar, "modulate", target_color, 0.3)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score : %d" % new_score
	var tween := create_tween()
	score_label.pivot_offset = score_label.size / 2.0
	tween.tween_property(score_label, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(score_label, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(score_label, "modulate", Color(1, 0.85, 0.4), 0.2)

func _on_trash_collected(count: int) -> void:
	trash_label.text = "🗑 Déchets : %d" % count
	var tween := create_tween()
	trash_label.pivot_offset = trash_label.size / 2.0
	tween.tween_property(trash_label, "rotation", 0.1, 0.1)
	tween.tween_property(trash_label, "rotation", -0.1, 0.1)
	tween.tween_property(trash_label, "rotation", 0.0, 0.1)
