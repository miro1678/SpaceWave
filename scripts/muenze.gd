extends Node2D

# ─── Power-Up Münze ───────────────────────────────────────────────────────────
# Eine Münze kann verschiedene Power-Ups repräsentieren. Der Typ bestimmt
# Farbe der Münze und welchen Effekt das Hauptspiel beim Einsammeln auslöst.

signal eingesammelt(typ: int)

# Power-Up Typen
const TYP_TRIPLE        : int = 0   # Triple-Shot (gelb)        – original
const TYP_SCHNELLFEUER  : int = 1   # Doppelte Feuerrate (cyan)
const TYP_ZEITSTOPP     : int = 2   # 3s Bewegungsstopp (lila)
const TYP_DOPPELPUNKTE  : int = 3   # 10s doppelte Punkte (grün)
const TYP_BOMBE         : int = 4   # alle Gegner weg (orange)
const TYP_CHAOS         : int = 5   # Steuerung vertauscht (magenta)
const TYP_TODESBOMBE    : int = 6   # rot mit ☠ – sprengt alles, Game Over
const TYP_MEGA          : int = 7   # gold mit ★ – alle guten Effekte doppelt

var typ : int = TYP_TRIPLE

# Farbpalette je Typ
const FARBEN = {
	0: Color(1.00, 0.90, 0.10),  # gelb
	1: Color(0.20, 0.90, 1.00),  # cyan
	2: Color(0.75, 0.40, 1.00),  # lila
	3: Color(0.30, 1.00, 0.45),  # grün
	4: Color(1.00, 0.45, 0.15),  # orange-rot
	5: Color(1.00, 0.30, 0.80),  # magenta
	6: Color(1.00, 0.10, 0.10),  # leuchtendes rot (Todesbombe)
	7: Color(1.40, 1.10, 0.20),  # glänzend gold (Mega-Münze)
}

var geschwindigkeit : float = 70.0
var dreh_speed      : float = 2.0
var bob_timer       : float = 0.0
var puls_timer      : float = 0.0
var start_x         : float = 0.0
var abgeschossen    : bool  = false

@onready var sprite : Sprite2D = $Sprite
@onready var totenkopf : Label = $Totenkopf
@onready var stern : Label = $Stern

var pickup_sound : AudioStreamPlayer

func _ready():
	start_x = position.x
	pickup_sound = AudioStreamPlayer.new()
	pickup_sound.volume_db = 2.0
	add_child(pickup_sound)
	var sfx = load("res://assets/sounds/muenze.wav")
	if sfx: pickup_sound.stream = sfx
	_farbe_setzen()

func _farbe_setzen():
	if sprite:
		sprite.modulate = FARBEN.get(typ, FARBEN[0])
	# Marker nur bei speziellen Münzen einblenden
	if totenkopf:
		totenkopf.visible = (typ == TYP_TODESBOMBE)
	if stern:
		stern.visible = (typ == TYP_MEGA)

func _process(delta: float):
	position.y += geschwindigkeit * delta
	bob_timer  += delta
	puls_timer += delta
	position.x  = start_x + sin(bob_timer * 2.2) * 10.0

	# Todesbombe und Mega-Münze drehen sich NICHT – sonst stünde der Marker auf dem Kopf.
	# Stattdessen wackeln/glitzern sie auffällig.
	if typ == TYP_TODESBOMBE:
		rotation = sin(puls_timer * 6.0) * 0.15
	elif typ == TYP_MEGA:
		rotation = sin(puls_timer * 4.0) * 0.12
	else:
		rotation += dreh_speed * delta

	# Leichtes Pulsieren der Helligkeit, damit Power-Ups auffallen.
	# Todesbombe und Mega pulsieren stärker und auffälliger.
	if sprite:
		var basis = FARBEN.get(typ, FARBEN[0])
		var amp = 0.25
		var freq = 5.0
		if typ == TYP_TODESBOMBE:
			amp = 0.45
			freq = 8.0
		elif typ == TYP_MEGA:
			amp = 0.40
			freq = 7.0
		var f = 1.0 + sin(puls_timer * freq) * amp
		sprite.modulate = Color(basis.r * f, basis.g * f, basis.b * f, 1.0)

	if position.y > 760:
		queue_free()

func einsammeln():
	if abgeschossen: return
	abgeschossen = true
	if pickup_sound and pickup_sound.stream:
		pickup_sound.play()
	emit_signal("eingesammelt", typ)
	# Kurz warten bis Sound fertig, dann löschen
	await get_tree().create_timer(0.4).timeout
	queue_free()
