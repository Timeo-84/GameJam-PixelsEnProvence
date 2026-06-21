extends Node2D
# ─────────────────────────────────────────────
#  LEVEL  –  Contrôleur principal du jeu
#  Gère les 3 actes : exploration → alarme → extinction
# ─────────────────────────────────────────────

# ── Référence aux nœuds de la scène ──────────
@onready var decor_layer: Node2D   = $DecorLayer
@onready var fires_node: Node2D    = $Fires
@onready var npcs_node: Node2D     = $NPCs
@onready var trashes_node: Node2D  = $Trashes
@onready var player: Node          = $Player
@onready var fire_timer_label: Label = $HUD/FireTimerLabel
@onready var act_label: Label        = $HUD/ActLabel
@onready var sky_rect: ColorRect     = $Sky
@onready var ambient_light: DirectionalLight2D = $AmbientLight
@onready var game_timer: Timer       = $GameTimer

# ── Références dynamiques (peuplées dans _ready) ──
var mentor: Node  = null
var tourist: Node = null

# ── Assets ───────────────────────────────────
var _fire_scene:  PackedScene = preload("res://scenes/fire.tscn")
var _npc_scene:   PackedScene = preload("res://scenes/npc.tscn")
var _trash_scene: PackedScene = preload("res://scenes/trash.tscn")

# ── État interne ─────────────────────────────
var _active_fires: Array[Node] = []
var _act: int = 0

const FIRE_POSITIONS:  Array[Vector2] = [Vector2(820,380), Vector2(900,280), Vector2(740,420)]

func _ready() -> void:
	GameState.reset()
	_spawn_world()
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_set_act(0)
	_update_ambient(0.0)

# ═══════════════════════════════════════════════
#  SPAWN DU MONDE
# ═══════════════════════════════════════════════
func _spawn_world() -> void:
	_spawn_visuals()
	_spawn_walls()
	_spawn_water_source()
	_spawn_npcs()
	_spawn_trash()

func _spawn_visuals() -> void:
	# Herbe principale
	_add_rect(Vector2(0,0),   Vector2(1280,720), Color(0.28,0.48,0.18,1), -5, false)
	# Sentiers avec bordures douces
	_add_rect(Vector2(120,0), Vector2(80,720),   Color(0.75,0.65,0.48,1), -4, true)
	_add_rect(Vector2(0,300), Vector2(1280,80),  Color(0.75,0.65,0.48,1), -4, true)
	# Zone sèche (risque incendie)
	_add_rect(Vector2(600,200), Vector2(680,520), Color(0.7,0.6,0.3,0.65), -3, true)
	# Silhouette Sainte-Victoire (montagne au fond)
	_add_rect(Vector2(500,-20), Vector2(780,280), Color(0.68,0.58,0.48,1.0), -3, true)
	
	# Arbres (stylisés avec ombre portée)
	var tree_positions: Array[Vector2] = [
		Vector2(280,80), Vector2(400,60), Vector2(520,90),
		Vector2(300,450), Vector2(460,480), Vector2(700,100),
		Vector2(900,80),  Vector2(1050,120), Vector2(700,500), Vector2(1050,540)
	]
	for tp in tree_positions:
		_spawn_tree(tp)

func _add_rect(pos: Vector2, sz: Vector2, col: Color, z: int, is_decor: bool) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.z_index = z
	if is_decor:
		decor_layer.add_child(r)
	else:
		add_child(r)
		move_child(r, 0)

func _spawn_tree(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = 0
	
	# Ombre (Ellipse noire)
	var shadow := ColorRect.new()
	shadow.size = Vector2(48, 16)
	shadow.position = Vector2(-24, 72)
	shadow.color = Color(0, 0, 0, 0.4)
	root.add_child(shadow)
	
	# Tronc
	var trunk := ColorRect.new()
	trunk.size = Vector2(16, 30)
	trunk.position = Vector2(-8, 50)
	trunk.color = Color(0.4, 0.25, 0.15, 1)
	root.add_child(trunk)
	
	# Feuillage
	var leaves := ColorRect.new()
	leaves.size = Vector2(56, 70)
	leaves.position = Vector2(-28, -20)
	leaves.color = Color(0.15, 0.4, 0.15, 1)
	root.add_child(leaves)
	
	decor_layer.add_child(root)

func _spawn_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 2
	decor_layer.add_child(walls)
	var borders: Array = [
		[Vector2(640,-15), Vector2(1400, 30)],
		[Vector2(640,735), Vector2(1400, 30)],
		[Vector2(-15,360), Vector2(30,  760)],
		[Vector2(1295,360),Vector2(30,  760)],
	]
	for b in borders:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = b[1]
		col.shape = shape
		col.position = b[0]
		walls.add_child(col)
	# Rochers
	_spawn_rock(Vector2(640,180), Vector2(80,50))
	_spawn_rock(Vector2(980,560), Vector2(60,40))

func _spawn_rock(pos: Vector2, sz: Vector2) -> void:
	var rock := StaticBody2D.new()
	rock.collision_layer = 2
	rock.position = pos
	
	var shadow := ColorRect.new()
	shadow.size = Vector2(sz.x, 10)
	shadow.position = Vector2(-sz.x/2, sz.y/2 - 5)
	shadow.color = Color(0, 0, 0, 0.4)
	rock.add_child(shadow)
	
	var vis := ColorRect.new()
	vis.size = sz
	vis.position = -sz / 2.0
	vis.color = Color(0.5, 0.45, 0.4, 1)
	rock.add_child(vis)
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = sz
	col.shape = shape
	rock.add_child(col)
	decor_layer.add_child(rock)

func _spawn_water_source() -> void:
	var ws := Area2D.new()
	ws.name = "WaterSourceDynamic"
	ws.collision_layer = 16
	ws.position = Vector2(220, 560)
	ws.add_to_group("water_source")
	var vis := ColorRect.new()
	vis.size = Vector2(60, 60)
	vis.position = Vector2(-30, -30)
	vis.color = Color(0.1, 0.5, 0.95, 0.9)
	ws.add_child(vis)
	var lbl := Label.new()
	lbl.text = "💧 Source"
	lbl.position = Vector2(-35, -52)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	ws.add_child(lbl)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 35.0
	col.shape = shape
	ws.add_child(col)
	decor_layer.add_child(ws)

func _spawn_npcs() -> void:
	# Mentor
	mentor = _npc_scene.instantiate()
	mentor.npc_name   = "Marcel – Garde Forestier"
	mentor.dialogue_key        = "mentor_intro"
	mentor.dialogue_key_repeat = "mentor_encourage"
	mentor.npc_color  = Color(0.25, 0.5, 0.15, 1)
	npcs_node.add_child(mentor)
	mentor.position = Vector2(160, 220)
	mentor.interaction_done.connect(_on_mentor_done)

	# Touriste
	tourist = _npc_scene.instantiate()
	tourist.npc_name  = "Le Touriste Négligent"
	tourist.dialogue_key        = "tourist_first"
	tourist.dialogue_key_repeat = "tourist_first"
	tourist.npc_color = Color(0.7, 0.2, 0.3, 1)
	npcs_node.add_child(tourist)
	tourist.position = Vector2(860, 200)
	tourist.interaction_done.connect(_on_tourist_done)

func _spawn_trash() -> void:
	var items: Array = [
		[Vector2(400, 230), "bottle"],
		[Vector2(600, 500), "can"],
		[Vector2(1000,450), "butt"],
	]
	for item in items:
		var t = _trash_scene.instantiate()
		t.trash_type = item[1]
		trashes_node.add_child(t)
		t.position = item[0]

# ═══════════════════════════════════════════════
#  BOUCLE PRINCIPALE
# ═══════════════════════════════════════════════
func _process(delta: float) -> void:
	if _act == 1 or _act == 2:
		GameState.time_remaining -= delta
		_update_timer_display()
		if GameState.time_remaining <= 0.0:
			_trigger_game_over()
		var urgency: float = clamp(1.0 - GameState.time_remaining / 120.0, 0.0, 1.0)
		_update_ambient(urgency)

# ═══════════════════════════════════════════════
#  ACTES
# ═══════════════════════════════════════════════
func _set_act(act: int) -> void:
	_act = act
	GameState.current_act = act
	
	# Tween pour faire "popper" le texte de l'acte
	act_label.scale = Vector2(1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(act_label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BOUNCE)
	
	match act:
		0:
			act_label.text = "Acte I – L'Appel"
			fire_timer_label.visible = false
		1:
			act_label.text = "Acte II – Le Danger"
			fire_timer_label.visible = true
		2:
			act_label.text = "Acte III – Le Climax"
		3:
			act_label.text = "Acte III – La Résolution"
			fire_timer_label.visible = false

func _update_ambient(urgency: float) -> void:
	sky_rect.color = Color(
		0.45 + urgency * 0.45,
		0.65 - urgency * 0.45,
		0.9  - urgency * 0.8,
		1.0
	)
	if ambient_light:
		ambient_light.energy = 1.0 - urgency * 0.4
		ambient_light.color = Color(1.0, 0.95 - urgency * 0.4, 0.85 - urgency * 0.5, 1.0)

func _update_timer_display() -> void:
	var secs: int = int(GameState.time_remaining)
	var mins: int = int(secs / 60.0)
	var s: int    = secs % 60
	fire_timer_label.text = "⏱ %02d:%02d" % [mins, s]
	
	# Clignotement dramatique si moins de 30 secondes
	if GameState.time_remaining < 30.0:
		var blink = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
		fire_timer_label.modulate = Color(1.0, blink, blink)
	else:
		fire_timer_label.modulate = Color.WHITE

# ═══════════════════════════════════════════════
#  ÉVÉNEMENTS NARRATIFS
# ═══════════════════════════════════════════════
func _on_mentor_done(_npc: Node) -> void:
	if not GameState.talked_to_mentor:
		GameState.talked_to_mentor = true

func _on_tourist_done(_npc: Node) -> void:
	if not GameState.talked_to_tourist:
		GameState.talked_to_tourist = true
		get_tree().create_timer(3.0).timeout.connect(_start_fire_event)

func _start_fire_event() -> void:
	if GameState.fire_started:
		return
	GameState.fire_started = true
	_set_act(1)
	GameState.time_remaining = 120.0
	DialogueManager.start_dialogue("fire_alarm", _spawn_initial_fires)

func _spawn_initial_fires() -> void:
	for pos in FIRE_POSITIONS:
		_spawn_fire(pos)
	_set_act(2)
	# Camera shake au démarrage de l'incendie !
	if player and player.has_method("add_trauma"):
		player.add_trauma(0.5)

func _spawn_fire(at_pos: Vector2) -> void:
	var fire: Node2D = _fire_scene.instantiate()
	fires_node.add_child(fire)
	fire.global_position = at_pos
	fire.fire_extinguished.connect(_on_fire_extinguished)
	fire.fire_spread.connect(_on_fire_spread)
	_active_fires.append(fire)

func _on_fire_spread(new_pos: Vector2) -> void:
	if _active_fires.size() >= 8:
		return
	_spawn_fire(new_pos)
	if player and player.has_method("add_trauma"):
		player.add_trauma(0.3)

func _on_fire_extinguished(fire: Node) -> void:
	_active_fires.erase(fire)
	if _active_fires.is_empty():
		_trigger_victory()

# ═══════════════════════════════════════════════
#  FIN DE PARTIE
# ═══════════════════════════════════════════════
func _trigger_victory() -> void:
	if _act == 3:
		return
	_set_act(3)
	GameState.game_won = true
	GameState.add_score(int(GameState.time_remaining) * 10)
	DialogueManager.start_dialogue("victory", _go_to_end_screen)

func _trigger_game_over() -> void:
	if _act == 3:
		return
	_set_act(3)
	DialogueManager.start_dialogue("game_over", _go_to_end_screen)

func _go_to_end_screen() -> void:
	get_tree().create_timer(1.5).timeout.connect(
		func(): get_tree().change_scene_to_file("res://scenes/end_screen.tscn")
	)

func _on_dialogue_started() -> void:
	pass

func _on_dialogue_finished() -> void:
	pass
