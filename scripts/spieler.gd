extends Node2D
# ─── Spieler-Raumschiff ───────────────────────────────────────────────────────
signal geschossen(pos: Vector2, richtung: Vector2)
signal getroffen
const GESCHW     : float = 320.0
const SCHUSS_CD  : float = 0.18
var schuss_timer  : float = 0.0
var schuss_sound_timer : float = 0.0   # entkoppelt Sound-Trigger von Schuss-Trigger
var unverwundbar  : bool  = false
var unverw_timer  : float = 0.0
const UNVERW_DAUER: float = 2.0
# ─── Triple-Shot Boost ────────────────────────────────────────────────────────
var boost_aktiv   : bool  = false
var boost_timer   : float = 0.0
const BOOST_DAUER : float = 30.0
# ─── Mega-Boost (6 Schüsse statt 3) ───────────────────────────────────────────
var mega_aktiv : bool  = false
var mega_timer : float = 0.0
# ─── Schnellfeuer-Power-Up ────────────────────────────────────────────────────
var schnellfeuer_aktiv : bool  = false
var schnellfeuer_timer : float = 0.0
const SCHNELLFEUER_DAUER : float = 10.0
const SCHNELLFEUER_FAKTOR : float = 0.18   # Cooldown × 0.18 = ~30 Schuss/s (MG)
# ─── Chaos-Steuerung (sehr selten) ────────────────────────────────────────────
var chaos_aktiv  : bool  = false
var chaos_timer  : float = 0.0
const CHAOS_DAUER : float = 8.0

@onready var sprite_normal : Sprite2D = $SpriteNormal
@onready var sprite_boost  : Sprite2D = $SpriteBoost

# ─── Sound ────────────────────────────────────────────────────────────────────
var schuss_sound : AudioStreamPlayer
var treffer_sound: AudioStreamPlayer

func _ready():
	getroffen.connect(_bei_treffer)
	_sounds_setup()

func _sounds_setup():
	schuss_sound = AudioStreamPlayer.new()
	schuss_sound.name = "SchussSound"
	schuss_sound.volume_db = -4.0
	add_child(schuss_sound)
	var s1 = load("res://assets/sounds/spieler_schuss.wav")
	if s1: schuss_sound.stream = s1

	treffer_sound = AudioStreamPlayer.new()
	treffer_sound.name = "TrefferSound"
	treffer_sound.volume_db = 0.0
	add_child(treffer_sound)
	var s2 = load("res://assets/sounds/spieler_treffer.wav")
	if s2: treffer_sound.stream = s2

func _process(delta: float):
	_bewegung(delta)
	_schiessen(delta)
	_blink_update(delta)
	_boost_update(delta)
	_schnellfeuer_update(delta)
	_chaos_update(delta)
	_mega_update(delta)
# ─── Bewegung ─────────────────────────────────────────────────────────────────
func _bewegung(delta: float):
	var dx = 0.0
	var dy = 0.0
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A): dx -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): dx += 1
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W): dy -= 1
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S): dy += 1
	# Bei Chaos-Steuerung sind Achsen vertauscht
	if chaos_aktiv:
		dx = -dx
		dy = -dy
	var dir = Vector2(dx, dy).normalized()
	position += dir * GESCHW * delta
	position.x = clamp(position.x, 25, 455)
	position.y = clamp(position.y, 60, 700)
# ─── Schießen ─────────────────────────────────────────────────────────────────
func _schiessen(delta: float):
	schuss_timer -= delta
	schuss_sound_timer -= delta
	if schuss_timer > 0: return
	# Mit Schnellfeuer-Power-Up: Leertaste gedrückt halten = Dauerfeuer.
	# Ohne Power-Up: Einzelschuss pro Tastendruck (wie bisher).
	var feuer = (Input.is_action_pressed("ui_accept")
		if schnellfeuer_aktiv
		else Input.is_action_just_pressed("ui_accept"))
	if feuer:
		var cd = SCHUSS_CD * (SCHNELLFEUER_FAKTOR if schnellfeuer_aktiv else 1.0)
		schuss_timer = cd
		# Sound: bei MG nicht jedes mal neu antriggern (sonst hackt es), sondern
		# nur alle ~0.07 s einen neuen Sound-Anschlag → klingt wie Rattern.
		if schuss_sound and schuss_sound.stream and schuss_sound_timer <= 0:
			schuss_sound.play()
			schuss_sound_timer = 0.07 if schnellfeuer_aktiv else 0.0
		var basis = position + Vector2(0, -30)
		if mega_aktiv:
			# 6-Schuss-Fächer: zentral, plus 5 zunehmend gekippte Bahnen
			emit_signal("geschossen", basis,                  Vector2(0, -1))
			emit_signal("geschossen", basis + Vector2(-6, 2),  Vector2(-0.22, -0.98).normalized())
			emit_signal("geschossen", basis + Vector2( 6, 2),  Vector2( 0.22, -0.98).normalized())
			emit_signal("geschossen", basis + Vector2(-12, 4), Vector2(-0.50, -0.87).normalized())
			emit_signal("geschossen", basis + Vector2( 12, 4), Vector2( 0.50, -0.87).normalized())
			emit_signal("geschossen", basis + Vector2(  0, -4), Vector2(0, -1))   # 6. Schuss: zweiter zentral
		elif boost_aktiv:
			emit_signal("geschossen", basis,                Vector2(0, -1))
			emit_signal("geschossen", basis + Vector2(-8, 0), Vector2(-0.42, -0.91).normalized())
			emit_signal("geschossen", basis + Vector2( 8, 0), Vector2( 0.42, -0.91).normalized())
		else:
			emit_signal("geschossen", basis, Vector2(0, -1))
# ─── Treffer / Blinken ────────────────────────────────────────────────────────
func _bei_treffer():
	if unverwundbar: return
	unverwundbar = true
	unverw_timer = UNVERW_DAUER
	if treffer_sound and treffer_sound.stream:
		treffer_sound.play()
func _blink_update(delta: float):
	if not unverwundbar: return
	unverw_timer -= delta
	modulate.a = 0.2 if fmod(unverw_timer * 7, 2) < 1 else 1.0
	if unverw_timer <= 0:
		unverwundbar = false
		modulate.a = 1.0
# ─── Boost (Triple-Shot) ──────────────────────────────────────────────────────
func _boost_update(delta: float):
	if not boost_aktiv: return
	boost_timer -= delta
	if boost_timer <= 0:
		boost_aktiv = false
		sprite_normal.visible = true
		sprite_boost.visible  = false
func boost_aktivieren(dauer: float = BOOST_DAUER):
	boost_aktiv  = true
	boost_timer  = dauer
	sprite_normal.visible = false
	sprite_boost.visible  = true
func boost_verbleibend() -> float:
	return boost_timer if boost_aktiv else 0.0
# ─── Schnellfeuer ─────────────────────────────────────────────────────────────
func _schnellfeuer_update(delta: float):
	if not schnellfeuer_aktiv: return
	schnellfeuer_timer -= delta
	if schnellfeuer_timer <= 0:
		schnellfeuer_aktiv = false
func schnellfeuer_aktivieren(dauer: float = SCHNELLFEUER_DAUER):
	schnellfeuer_aktiv = true
	schnellfeuer_timer = dauer
func schnellfeuer_verbleibend() -> float:
	return schnellfeuer_timer if schnellfeuer_aktiv else 0.0
# ─── Chaos-Steuerung ──────────────────────────────────────────────────────────
func _chaos_update(delta: float):
	if not chaos_aktiv: return
	chaos_timer -= delta
	if chaos_timer <= 0:
		chaos_aktiv = false
func chaos_aktivieren():
	chaos_aktiv = true
	chaos_timer = CHAOS_DAUER
func chaos_verbleibend() -> float:
	return chaos_timer if chaos_aktiv else 0.0
# ─── Mega (6 Schüsse) ─────────────────────────────────────────────────────────
func _mega_update(delta: float):
	if not mega_aktiv: return
	mega_timer -= delta
	if mega_timer <= 0:
		mega_aktiv = false
func mega_aktivieren(dauer: float = 15.0):
	mega_aktiv = true
	mega_timer = dauer
func mega_verbleibend() -> float:
	return mega_timer if mega_aktiv else 0.0
