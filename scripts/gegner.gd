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

# Eingefroren-Status (Zeitstopp-Power-Up)
var eingefroren : bool = false

# Texturen je Typ
const TEXTUR_PFADE = {
	1: "res://assets/enemies/enemy1.png",
	2: "res://assets/enemies/enemy2.png",
	3: "res://assets/enemies/enemy3.png",
}

@onready var sprite : Sprite2D = $Sprite

# ─── Sound ────────────────────────────────────────────────────────────────────
var schuss_sound : AudioStreamPlayer
var treffer_sound: AudioStreamPlayer

func _ready():
	_typ_setup()
	schuss_timer = randf_range(1.0, schuss_pause)
	_sounds_setup()

func _sounds_setup():
	schuss_sound = AudioStreamPlayer.new()
	schuss_sound.name = "GegnerSchussSound"
	schuss_sound.volume_db = -8.0
	add_child(schuss_sound)
	var s1 = load("res://assets/sounds/gegner_schuss.wav")
	if s1: schuss_sound.stream = s1

	treffer_sound = AudioStreamPlayer.new()
	treffer_sound.name = "GegnerTrefferSound"
	treffer_sound.volume_db = -2.0
	add_child(treffer_sound)
	var s2 = load("res://assets/sounds/gegner_treffer.wav")
	if s2: treffer_sound.stream = s2

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
	# Bei Zeitstopp: weder bewegen noch schießen
	if eingefroren:
		return

	position += geschwindigkeit * delta

	# Typ 2 wackelt
	if typ == 2:
		position.x += sin(Time.get_ticks_msec() * 0.004 + position.y * 0.05) * 1.2

	schuss_timer -= delta
	if schuss_timer <= 0:
		schuss_timer = schuss_pause * randf_range(0.7, 1.3)
		if schuss_sound and schuss_sound.stream:
			schuss_sound.play()
		emit_signal("schiesst", position + Vector2(0, treff_radius))

func einfrieren_setzen(an: bool):
	eingefroren = an
	if an:
		# Leichter bläulich-violetter Tint signalisiert "eingefroren"
		modulate = Color(0.55, 0.65, 1.4)
	else:
		modulate = Color(1, 1, 1)

func schaden_nehmen(menge: int):
	leben -= menge
	if treffer_sound and treffer_sound.stream:
		treffer_sound.play()
	if leben <= 0:
		emit_signal("abgeschossen")
		queue_free()
	else:
		# Kurzes weißes Aufblitzen (auch im Eingefroren-Zustand erlaubt)
		modulate = Color(2, 2, 2)
		var ziel = Color(0.55, 0.65, 1.4) if eingefroren else Color(1, 1, 1)
		var tw = create_tween()
		tw.tween_property(self, "modulate", ziel, 0.12)
