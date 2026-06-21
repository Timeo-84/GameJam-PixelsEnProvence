extends Node2D
# ─────────────────────────────────────────────
#  FIRE NODE  –  Spreads over time, can be extinguished
# ─────────────────────────────────────────────

signal fire_extinguished(fire: Node)
signal fire_spread(new_pos: Vector2)

const SPREAD_INTERVAL := 8.0
const MAX_INTENSITY := 100.0

var intensity: float = 20.0
var spread_timer: float = 0.0
var _alive: bool = true
var _extinguish_tween: Tween

@onready var fire_particles: GPUParticles2D = $FireParticles
@onready var smoke_particles: GPUParticles2D = $SmokeParticles
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	add_to_group("fire")
	_update_visuals()

func _process(delta: float) -> void:
	if not _alive:
		return
		
	# Ne s'étend et ne grandit que s'il n'est pas en train d'être éteint
	if not _extinguish_tween or not _extinguish_tween.is_running():
		intensity = minf(intensity + delta * 4.0, MAX_INTENSITY)
		spread_timer += delta
		if spread_timer >= SPREAD_INTERVAL:
			spread_timer = 0.0
			_try_spread()
			
	_update_visuals()

func _update_visuals() -> void:
	var ratio: float = intensity / MAX_INTENSITY
	
	# Paramètres particules (feu)
	fire_particles.amount = maxi(10, int(ratio * 60))
	fire_particles.process_material.scale_min = 6.0 + ratio * 8.0
	fire_particles.process_material.scale_max = 10.0 + ratio * 14.0
	fire_particles.process_material.emission_box_extents = Vector3(8.0 + ratio * 15.0, 2.0, 1.0)
	
	# Paramètres fumée
	smoke_particles.amount = maxi(5, int(ratio * 30))
	smoke_particles.process_material.emission_box_extents = Vector3(10.0 + ratio * 15.0, 2.0, 1.0)
	
	if light:
		light.energy = 0.6 + ratio * 1.5
		# Oscillation de la lumière
		light.texture_scale = 1.5 + ratio * 2.0 + (sin(Time.get_ticks_msec() * 0.005) * 0.2)
		
	# Clamper la croissance du scale à une valeur stricte pour ne pas exploser la collision
	var visual_scale = clampf(0.8 + ratio * 1.5, 0.5, 2.5)
	scale = Vector2(visual_scale, visual_scale)

func _try_spread() -> void:
	if intensity < 50.0:
		return
	var offsets: Array[Vector2] = [Vector2(80, 0), Vector2(-80, 0), Vector2(0, 80), Vector2(0, -80)]
	var chosen: Vector2 = offsets[randi() % offsets.size()]
	fire_spread.emit(global_position + chosen)

func extinguish(amount: float) -> void:
	if not _alive:
		return
		
	var target_intensity = maxf(intensity - amount, 0.0)
	
	if _extinguish_tween:
		_extinguish_tween.kill()
		
	_extinguish_tween = create_tween()
	# Réduit fluidement les PV (intensité)
	_extinguish_tween.tween_property(self, "intensity", target_intensity, 0.2)
	
	if target_intensity <= 0.0:
		_extinguish_tween.tween_callback(_die)

func _die() -> void:
	_alive = false
	GameState.extinguish_fire()
	fire_extinguished.emit(self)
	
	# Désactiver la collision pour éviter les erreurs ou interactions futures
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	
	# Animation d'extinction (coupure du feu, reste un peu de fumée)
	fire_particles.emitting = false
	var tween := create_tween()
	if light:
		tween.tween_property(light, "energy", 0.0, 0.4)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.4)
	tween.parallel().tween_property(smoke_particles, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)
