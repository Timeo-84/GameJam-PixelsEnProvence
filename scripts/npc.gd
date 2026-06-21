extends StaticBody2D
# ─────────────────────────────────────────────
#  NPC  –  Personnage non-joueur interactif
# ─────────────────────────────────────────────

@export var npc_name: String = "NPC"
@export var dialogue_key: String = ""
@export var dialogue_key_repeat: String = ""
@export var npc_color: Color = Color(0.5, 0.5, 0.5)

var _has_interacted: bool = false
var _time: float = 0.0

signal interaction_done(npc: Node)

func _ready() -> void:
	add_to_group("npc")
	# Applique la couleur au nœud Sprite s'il existe
	var sp: Node = get_node_or_null("Sprite")
	if sp and sp is ColorRect:
		(sp as ColorRect).color = npc_color
	# Label de nom
	var lbl: Node = get_node_or_null("Label")
	if lbl and lbl is Label:
		(lbl as Label).text = npc_name
	# Exclamation visible par défaut
	var ex: Node = get_node_or_null("Exclamation")
	if ex:
		ex.visible = true
	# Hint caché par défaut
	var hl: Node = get_node_or_null("HintLabel")
	if hl:
		hl.visible = false

func _process(delta: float) -> void:
	var ex: Node = get_node_or_null("Exclamation")
	if ex and ex.visible:
		_time += delta * 4.0
		ex.position.y = -60.0 + sin(_time) * 5.0

func interact() -> void:
	var key: String = dialogue_key
	if _has_interacted and dialogue_key_repeat != "":
		key = dialogue_key_repeat
	if key == "":
		return
	_has_interacted = true
	# Cache l'exclamation après première interaction
	var ex: Node = get_node_or_null("Exclamation")
	if ex:
		ex.visible = false
	DialogueManager.start_dialogue(key, _on_dialogue_done)

func _on_dialogue_done() -> void:
	interaction_done.emit(self)

func _on_detect_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var hl: Node = get_node_or_null("HintLabel")
		if hl:
			hl.visible = true

func _on_detect_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var hl: Node = get_node_or_null("HintLabel")
		if hl:
			hl.visible = false
