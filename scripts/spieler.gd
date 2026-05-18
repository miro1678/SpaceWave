extends Node2D
# ─── Spieler-Raumschiff ───────────────────────────────────────────────────────
signal geschossen(pos: Vector2, richtung: Vector2)
signal getroffen
const GESCHW     : float = 320.0
const SCHUSS_CD  : float = 0.18
var schuss_timer  : float = 0.0
var unverwundbar  : bool  = false
var unverw_timer  : float = 0.0
const UNVERW_DAUER: float = 2.0
# ─── Triple-Shot Boost ────────────────────────────────────────────────────────
var boost_aktiv   : bool  = false
var boost_timer   : float = 0.0
const BOOST_DAUER : float = 30.0
@onready var sprite_normal : Sprite2D = $SpriteNormal
@onready var sprite_boost  : Sprite2D = $SpriteBoost
func _ready():
	getroffen.connect(_bei_treffer)
func _process(delta: float):
	_bewegung(delta)
	_schiessen(delta)
	_blink_update(delta)
	_boost_update(delta)
# ─── Bewegung ─────────────────────────────────────────────────────────────────
func _bewegung(delta: float):
	var dx = 0.0
	var dy = 0.0
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A): dx -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): dx += 1
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W): dy -= 1
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S): dy += 1
	var dir = Vector2(dx, dy).normalized()
	position += dir * GESCHW * delta
	position.x = clamp(position.x, 25, 455)
	position.y = clamp(position.y, 60, 700)
# ─── Schießen ─────────────────────────────────────────────────────────────────
func _schiessen(delta: float):
	schuss_timer -= delta
	if schuss_timer > 0: return
	if Input.is_action_just_pressed("ui_accept"):
		schuss_timer = SCHUSS_CD
		var basis = position + Vector2(0, -30)
		if boost_aktiv:
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
func _blink_update(delta: float):
	if not unverwundbar: return
	unverw_timer -= delta
	modulate.a = 0.2 if fmod(unverw_timer * 7, 2) < 1 else 1.0
	if unverw_timer <= 0:
		unverwundbar = false
		modulate.a = 1.0
# ─── Boost ────────────────────────────────────────────────────────────────────
func _boost_update(delta: float):
	if not boost_aktiv: return
	boost_timer -= delta
	if boost_timer <= 0:
		boost_aktiv = false
		sprite_normal.visible = true
		sprite_boost.visible  = false
func boost_aktivieren():
	boost_aktiv  = true
	boost_timer  = BOOST_DAUER
	sprite_normal.visible = false
	sprite_boost.visible  = true
func boost_verbleibend() -> float:
	return boost_timer if boost_aktiv else 0.0
