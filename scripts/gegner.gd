extends Node2D

# ─── Gegner-Raumschiff ────────────────────────────────────────────────────────

signal abgeschossen
signal schiesst(pos: Vector2)

var typ             : int   = 1
var punkte_wert     : int   = 10
var treff_radius    : float = 28.0
var farbe           : Color = Color(1, 0.3, 0.3)
var geschwindigkeit : Vector2 = Vector2(0, 80)
var leben           : int   = 1

var schuss_timer : float = 0.0
var schuss_pause : float = 3.0

# Texturen je Typ
const TEXTUR_PFADE = {
	1: "res://assets/enemies/enemy1.png",
	2: "res://assets/enemies/enemy2.png",
	3: "res://assets/enemies/enemy3.png",
}

@onready var sprite : Sprite2D = $Sprite

func _ready():
	_typ_setup()
	schuss_timer = randf_range(1.0, schuss_pause)

func _typ_setup():
	match typ:
		1:
			farbe        = Color(1.0, 0.25, 0.25)
			leben        = 1
			treff_radius = 26.0
			schuss_pause = 3.5
		2:
			farbe        = Color(0.3, 0.5, 1.0)
			leben        = 2
			treff_radius = 26.0
			schuss_pause = 2.2
		3:
			farbe        = Color(0.3, 1.0, 0.4)
			leben        = 6
			treff_radius = 34.0
			schuss_pause = 1.4

	var tex = load(TEXTUR_PFADE.get(typ, TEXTUR_PFADE[1]))
	sprite.texture = tex
	# Boss etwas größer
	sprite.scale = Vector2(0.9, 0.9) if typ == 3 else Vector2(0.7, 0.7)
	# Gegner schauen nach unten → um 180° drehen
	sprite.rotation_degrees = 180

func _process(delta: float):
	position += geschwindigkeit * delta

	# Typ 2 wackelt
	if typ == 2:
		position.x += sin(Time.get_ticks_msec() * 0.004 + position.y * 0.05) * 1.2

	schuss_timer -= delta
	if schuss_timer <= 0:
		schuss_timer = schuss_pause * randf_range(0.7, 1.3)
		emit_signal("schiesst", position + Vector2(0, treff_radius))

func schaden_nehmen(menge: int):
	leben -= menge
	if leben <= 0:
		emit_signal("abgeschossen")
		queue_free()
	else:
		# Kurzes weißes Aufblitzen
		modulate = Color(2, 2, 2)
		var tw = create_tween()
		tw.tween_property(self, "modulate", Color(1, 1, 1), 0.12)
