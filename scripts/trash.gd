extends Area2D
# ─────────────────────────────────────────────
#  TRASH COLLECTIBLE
# ─────────────────────────────────────────────

@export var trash_type: String = "bottle"
@export var points: int = 50

signal collected(trash: Node)

var _colors: Dictionary = {
	"bottle": Color(0.3, 0.8, 0.3, 0.9),
	"can":    Color(0.7, 0.7, 0.1, 0.9),
	"butt":   Color(0.8, 0.3, 0.1, 0.9),
}
var _emojis: Dictionary = {
	"bottle": "🍾",
	"can":    "🥤",
	"butt":   "🚬",
}

var _time: float = 0.0
@onready var _sprite: Node = null

func _ready() -> void:
	add_to_group("trash")
	_sprite = get_node_or_null("Sprite")
	if _sprite and _sprite is ColorRect:
		(_sprite as ColorRect).color = _colors.get(trash_type, Color.GRAY)
	var ico: Node = get_node_or_null("Icon")
	if ico and ico is Label:
		(ico as Label).text = _emojis.get(trash_type, "?")
	var hint: Node = get_node_or_null("Hint")
	if hint:
		hint.visible = false

func _process(delta: float) -> void:
	_time += delta * 3.0
	if _sprite:
		_sprite.position.y = -15.0 + sin(_time) * 4.0

func _on_body_entered(_body: Node) -> void:
	var hint: Node = get_node_or_null("Hint")
	if hint:
		hint.visible = true

func _on_body_exited(_body: Node) -> void:
	var hint: Node = get_node_or_null("Hint")
	if hint:
		hint.visible = false

func collect() -> void:
	GameState.collect_trash()
	collected.emit(self)
	# Animation de collecte
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
