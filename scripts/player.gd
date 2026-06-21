extends CharacterBody2D
# ─────────────────────────────────────────────
#  PLAYER  –  Machine à états & Game Feel
# ─────────────────────────────────────────────

enum State { IDLE, MOVE, DIALOGUE, SPRAY }

const ACCEL := 1800.0
const FRICTION := 1400.0
const MAX_SPEED := 240.0
const SPRAY_RANGE := 120.0
const WATER_COST := 15.0

var current_state: State = State.IDLE
var _cooldown_timer: float = 0.0

@onready var sprite: ColorRect = $Sprite
@onready var walk_trail: GPUParticles2D = $WalkTrail
@onready var water_particles: GPUParticles2D = $WaterParticles
@onready var camera: Camera2D = $Camera2D
@onready var interact_area: Area2D = $InteractArea

var _shake_trauma: float = 0.0

signal water_recharged()

func _ready() -> void:
	add_to_group("player")
	GameState.water_changed.connect(_on_water_changed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_update_sprite_color()

# ═══════════════════════════════════════════════
#  PROCESS PHYSIQUE & CAMERA SHAKE
# ═══════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	_process_camera_shake(delta)

	match current_state:
		State.DIALOGUE:
			_apply_friction(delta)
			_squash_stretch(delta)
			move_and_slide()
		State.SPRAY:
			_apply_friction(delta)
			move_and_slide()
		_:
			_handle_movement(delta)

func _handle_movement(delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()

	if dir != Vector2.ZERO:
		current_state = State.MOVE
		velocity = velocity.move_toward(dir * MAX_SPEED, ACCEL * delta)
		walk_trail.emitting = true
		# Orientation visuelle
		if dir.x > 0:
			sprite.scale.x = 1.0
			water_particles.process_material.direction = Vector3(1, 0, 0)
			water_particles.position.x = 15
		elif dir.x < 0:
			sprite.scale.x = -1.0
			water_particles.process_material.direction = Vector3(-1, 0, 0)
			water_particles.position.x = -15
	else:
		current_state = State.IDLE
		walk_trail.emitting = false
		_apply_friction(delta)
	
	_squash_stretch(delta)
	move_and_slide()

func _apply_friction(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func _squash_stretch(delta: float) -> void:
	# Déformation selon la vitesse
	var spd_ratio: float = velocity.length() / MAX_SPEED
	var target_y: float = 1.0 - (spd_ratio * 0.15)
	var target_x: float = signf(sprite.scale.x) * (1.0 + (spd_ratio * 0.15))
	
	# Transition douce
	sprite.scale.y = lerpf(sprite.scale.y, target_y, 15.0 * delta)
	sprite.scale.x = lerpf(sprite.scale.x, target_x, 15.0 * delta)

# ═══════════════════════════════════════════════
#  CAMERA SHAKE
# ═══════════════════════════════════════════════
func add_trauma(amount: float) -> void:
	_shake_trauma = clampf(_shake_trauma + amount, 0.0, 1.0)

func _process_camera_shake(delta: float) -> void:
	if _shake_trauma > 0.0:
		_shake_trauma = maxf(_shake_trauma - delta * 0.8, 0.0)
		var amt: float = _shake_trauma * _shake_trauma
		camera.offset.x = (randf() * 2.0 - 1.0) * 12.0 * amt
		camera.offset.y = (randf() * 2.0 - 1.0) * 12.0 * amt
	else:
		camera.offset = Vector2.ZERO

# ═══════════════════════════════════════════════
#  INPUTS ET ACTIONS
# ═══════════════════════════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.DIALOGUE or _cooldown_timer > 0.0:
		return

	if event.is_action_pressed("extinguish"):
		_try_spray()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("interact"):
		_handle_interact()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("pick_trash"):
		_handle_trash()
		get_viewport().set_input_as_handled()

func _try_spray() -> void:
	if current_state == State.SPRAY or GameState.water_level < WATER_COST:
		return
	if GameState.use_water(WATER_COST):
		current_state = State.SPRAY
		water_particles.restart()
		get_tree().create_timer(0.4).timeout.connect(func(): if current_state == State.SPRAY: current_state = State.IDLE)
		
		var push_dir = Vector2.RIGHT if sprite.scale.x > 0 else Vector2.LEFT
		for fire_node in get_tree().get_nodes_in_group("fire"):
			if fire_node is Node2D:
				var dist: float = global_position.distance_to((fire_node as Node2D).global_position)
				if dist <= SPRAY_RANGE:
					# Le feu doit être dans la direction où on regarde (approximativement)
					var to_fire = (fire_node.global_position - global_position).normalized()
					if to_fire.dot(push_dir) > 0.0:
						fire_node.extinguish(35.0)
						add_trauma(0.1)

func _handle_interact() -> void:
	# 1. Chercher la source d'eau (Ça, ça marche déjà grâce aux Areas)
	for area in interact_area.get_overlapping_areas():
		if area.is_in_group("water_source"):
			GameState.add_water(GameState.WATER_MAX)
			DialogueManager.start_dialogue("water_source")
			water_recharged.emit()
			return
			
	# 2. Chercher le PNJ par DISTANCE (Infaillible, ignore les collisions)
	var closest_npc: Node = null
	var min_dist: float = 120.0 # Le joueur peut parler à un PNJ à 120 pixels à la ronde
	
	# On récupère tous les PNJ du jeu
	for npc in get_tree().get_nodes_in_group("npc"):
		# On calcule la distance exacte entre le joueur et le PNJ
		var d = global_position.distance_to(npc.global_position)
		if d < min_dist:
			min_dist = d
			closest_npc = npc
			
	# Si on a trouvé un PNJ assez proche, on lui parle
	if closest_npc != null and closest_npc.has_method("interact"):
		closest_npc.interact()

func _handle_trash() -> void:
	var closest_trash: Node = null
	var min_dist: float = INF
	for area in interact_area.get_overlapping_areas():
		if area.is_in_group("trash"):
			var d = global_position.distance_squared_to(area.global_position)
			if d < min_dist:
				min_dist = d
				closest_trash = area
				
	if closest_trash != null and closest_trash.has_method("collect"):
		closest_trash.collect()

# ═══════════════════════════════════════════════
#  GÉRER LES ÉTATS DU DIALOGUE DE FAÇON ÉTANCHE
# ═══════════════════════════════════════════════
func _on_dialogue_started() -> void:
	current_state = State.DIALOGUE

func _on_dialogue_finished() -> void:
	_cooldown_timer = 0.2  # Protection d'écho de touche E
	current_state = State.IDLE

# ═══════════════════════════════════════════════
#  ZONES – détection des PNJ, déchets, eau
# ═══════════════════════════════════════════════
func _on_interact_area_body_entered(_body: Node) -> void: pass
func _on_interact_area_body_exited(_body: Node) -> void: pass
func _on_interact_area_area_entered(_area: Node) -> void: pass
func _on_interact_area_area_exited(_area: Node) -> void: pass

func _on_water_changed(_amount: float) -> void:
	_update_sprite_color()

func _update_sprite_color() -> void:
	var ratio: float = GameState.water_level / GameState.WATER_MAX
	sprite.color = Color(0.2 + (1.0 - ratio) * 0.6, 0.4 * ratio, 0.9 * ratio, 1.0)
