extends Control
# ─────────────────────────────────────────────
#  MAIN MENU
# ─────────────────────────────────────────────

@onready var title_label: Label = $Center/VBox/Title
@onready var sub_label: Label = $Center/VBox/Subtitle
@onready var play_btn: Button = $Center/VBox/PlayBtn
@onready var credits_btn: Button = $Center/VBox/CreditsBtn
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var sky: ColorRect = $Sky
@onready var mountain_rect: ColorRect = $Mountain

var _sky_tween: Tween

func _ready() -> void:
	# Autoriser le menu à tourner même en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Entrée animée
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

	play_btn.pressed.connect(_on_play_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	
	# Bloquer les clics en arrière-plan quand le panel est ouvert
	credits_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_panel.visible = false

	# Animation sky cycling (aurore provençale)
	_animate_sky()

func _animate_sky() -> void:
	if _sky_tween:
		_sky_tween.kill()
	_sky_tween = create_tween().set_loops()
	_sky_tween.tween_property(sky, "color", Color(0.95, 0.55, 0.25, 1.0), 4.0)
	_sky_tween.tween_property(sky, "color", Color(0.45, 0.65, 0.90, 1.0), 4.0)

func _on_play_pressed() -> void:
	if get_tree().paused:
		get_tree().paused = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	)

func _on_credits_pressed() -> void:
	credits_panel.visible = not credits_panel.visible
	get_tree().paused = credits_panel.visible
