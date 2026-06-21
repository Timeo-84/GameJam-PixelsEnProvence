extends Node

# ─────────────────────────────────────────────
#  GAME STATE  –  Autoload singleton
# ─────────────────────────────────────────────

signal score_changed(new_score: int)
signal water_changed(amount: float)
signal trash_collected(count: int)

# Acte actuel : 0 = menu, 1 = prologue/forêt, 2 = climax, 3 = fin
var current_act: int = 0

# Ressources du joueur
var water_level: float = 100.0       # %
const WATER_MAX: float = 100.0

# Score / progression
var score: int = 0
var trash_count: int = 0
var fires_extinguished: int = 0

# Flags de scénario
var talked_to_mentor: bool = false
var talked_to_tourist: bool = false
var fire_started: bool = false
var game_won: bool = false

# Temps restant (Acte 2/3)
var time_remaining: float = 120.0
var timer_active: bool = false

func reset() -> void:
	current_act = 0
	water_level = WATER_MAX
	score = 0
	trash_count = 0
	fires_extinguished = 0
	talked_to_mentor = false
	talked_to_tourist = false
	fire_started = false
	game_won = false
	time_remaining = 120.0
	timer_active = false

func add_water(amount: float) -> void:
	water_level = clamp(water_level + amount, 0.0, WATER_MAX)
	water_changed.emit(water_level)

func use_water(amount: float) -> bool:
	if water_level <= 0:
		return false
	water_level = clamp(water_level - amount, 0.0, WATER_MAX)
	water_changed.emit(water_level)
	return true

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func collect_trash() -> void:
	trash_count += 1
	score += 50
	trash_collected.emit(trash_count)
	score_changed.emit(score)

func extinguish_fire() -> void:
	fires_extinguished += 1
	score += 200
	score_changed.emit(score)
