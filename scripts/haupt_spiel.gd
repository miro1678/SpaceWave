extends Node2D

const SPIELER_SZENE     = preload("res://scenes/spieler.tscn")
const GEGNER_SZENE      = preload("res://scenes/gegner.tscn")
const GESCHOSS_SZENE    = preload("res://scenes/geschoss.tscn")
const EXPLOSION_SZENE   = preload("res://scenes/explosion.tscn")
const MUENZE_SZENE      = preload("res://scenes/muenze.tscn")

# ─── Power-Up Typen (synchron mit muenze.gd) ──────────────────────────────────
const PU_TRIPLE        : int = 0
const PU_SCHNELLFEUER  : int = 1
const PU_ZEITSTOPP     : int = 2
const PU_DOPPELPUNKTE  : int = 3
const PU_BOMBE         : int = 4
const PU_CHAOS         : int = 5
const PU_TODESBOMBE    : int = 6   # rote Münze mit ☠ – sprengt alles, Game Over
const PU_MEGA          : int = 7   # goldene Münze mit ★ – 6 Schüsse + alle guten Effekte 15 s

var punkte        : int  = 0
var leben         : int  = 3
var welle         : int  = 1
var spiel_laeuft  : bool = false

var gegner_pro_welle   : int   = 6
var spawn_pause        : float = 1.8
var spawn_timer        : float = 0.0
var gegner_gespawnt    : int   = 0
var gegner_geschw_base : float = 80.0
var welle_laeuft_aus   : bool  = false

var muenzen_timer : float = 40.0
const MUENZEN_PAUSE : float = 40.0

# ─── Power-Up Zustände ────────────────────────────────────────────────────────
var zeitstopp_aktiv  : bool  = false
var zeitstopp_timer  : float = 0.0
const ZEITSTOPP_DAUER : float = 3.0

var doppelpunkte_aktiv : bool  = false
var doppelpunkte_timer : float = 0.0
const DOPPELPUNKTE_DAUER : float = 10.0

@onready var spieler_layer  = $SpielerLayer
@onready var gegner_layer   = $GegnerLayer
@onready var geschoss_layer = $GeschossLayer
@onready var effekt_layer   = $EffektLayer

@onready var punkte_label    = $UI/PunkteLabel
@onready var leben_label     = $UI/LebenLabel
@onready var welle_label     = $UI/WelleLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var punkte_end      = $UI/GameOverPanel/PunkteEndLabel
@onready var neu_start_btn   = $UI/GameOverPanel/NeuStartBtn
@onready var titel_label     = $UI/GameOverPanel/TitelLabel

var spieler       : Node2D = null
var muenzen_layer : Node2D = null
var boost_label        : Label  = null   # Triple-Shot
var schnellfeuer_label : Label  = null
var zeitstopp_label    : Label  = null
var doppel_label       : Label  = null
var chaos_label        : Label  = null
var mega_label         : Label  = null
var musik_player  : AudioStreamPlayer
var game_over_sound : AudioStreamPlayer

func _ready():
	neu_start_btn.pressed.connect(_neu_starten)

	muenzen_layer = Node2D.new()
	muenzen_layer.name = "MuenzenLayer"
	add_child(muenzen_layer)

	_status_labels_erzeugen()
	_sounds_setup()
	_starten()

func _status_labels_erzeugen():
	var ui = $UI
	# Helper: Label gestapelt unter der Punkte-Zeile
	boost_label        = _label_neu(ui, "BoostLabel",        Color(1.00, 0.90, 0.10),  44)
	schnellfeuer_label = _label_neu(ui, "SchnellfeuerLabel", Color(0.20, 0.90, 1.00),  70)
	zeitstopp_label    = _label_neu(ui, "ZeitstoppLabel",    Color(0.80, 0.50, 1.00),  96)
	doppel_label       = _label_neu(ui, "DoppelLabel",       Color(0.30, 1.00, 0.45), 122)
	chaos_label        = _label_neu(ui, "ChaosLabel",        Color(1.00, 0.30, 0.80), 148)
	mega_label         = _label_neu(ui, "MegaLabel",         Color(1.40, 1.10, 0.20), 174)

func _label_neu(parent: Node, name: String, farbe: Color, oben: int) -> Label:
	var l = Label.new()
	l.name = name
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", farbe)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.offset_left   = 100
	l.offset_top    = oben
	l.offset_right  = 380
	l.offset_bottom = oben + 26
	l.visible = false
	parent.add_child(l)
	return l

func _sounds_setup():
	# Hintergrundmusik
	musik_player = AudioStreamPlayer.new()
	musik_player.name = "MusikPlayer"
	musik_player.volume_db = -14.0
	add_child(musik_player)
	var musik = load("res://assets/sounds/hintergrund_musik.wav")
	if musik:
		musik.loop_mode  = AudioStreamWAV.LOOP_FORWARD
		musik.loop_begin = 0
		musik.loop_end   = musik.data.size() / 2
		musik_player.stream = musik
		musik_player.play()

	# Game Over Sound
	game_over_sound = AudioStreamPlayer.new()
	game_over_sound.name = "GameOverSound"
	game_over_sound.volume_db = 2.0
	add_child(game_over_sound)
	var go_sfx = load("res://assets/sounds/game_over.wav")
	if go_sfx: game_over_sound.stream = go_sfx

func _starten():
	punkte = 0
	leben  = 3
	welle  = 1
	spiel_laeuft = true
	muenzen_timer = 12.0
	zeitstopp_aktiv = false
	zeitstopp_timer = 0.0
	doppelpunkte_aktiv = false
	doppelpunkte_timer = 0.0
	game_over_panel.visible = false
	if boost_label:        boost_label.visible        = false
	if schnellfeuer_label: schnellfeuer_label.visible = false
	if zeitstopp_label:    zeitstopp_label.visible    = false
	if doppel_label:       doppel_label.visible       = false
	if chaos_label:        chaos_label.visible        = false
	if mega_label:         mega_label.visible         = false
	# Musik wieder starten falls sie gestoppt wurde
	if musik_player and not musik_player.playing:
		musik_player.play()
	_ui_update()
	_spieler_spawnen()
	_welle_starten()

func _neu_starten():
	for k in spieler_layer.get_children():  k.queue_free()
	for k in gegner_layer.get_children():   k.queue_free()
	for k in geschoss_layer.get_children(): k.queue_free()
	for k in effekt_layer.get_children():   k.queue_free()
	for k in muenzen_layer.get_children():  k.queue_free()
	_starten()

func _spieler_spawnen():
	if spieler and is_instance_valid(spieler):
		spieler.queue_free()
	spieler = SPIELER_SZENE.instantiate()
	spieler.position = Vector2(240, 640)
	spieler.geschossen.connect(_spieler_schuss)
	spieler.getroffen.connect(_spieler_trifft)
	spieler_layer.add_child(spieler)

func _spieler_schuss(pos: Vector2, richtung: Vector2):
	if not spiel_laeuft: return
	var g = GESCHOSS_SZENE.instantiate()
	g.position = pos
	g.spieler_geschoss = true
	g.geschwindigkeit  = richtung * 550
	geschoss_layer.add_child(g)

func _spieler_trifft():
	if not spiel_laeuft: return
	leben -= 1
	_ui_update()
	# Große Spieler-Explosion (22-Frame Typ)
	_explosion_bei(spieler.position, Color(1.0, 0.35, 0.0), "spieler")
	for i in range(3):
		var offset = Vector2(randf_range(-45, 45), randf_range(-45, 45))
		_explosion_bei(spieler.position + offset, Color(1.0, 0.7, 0.1), "gegner")
	if leben <= 0:
		_game_over()
	else:
		await get_tree().create_timer(0.8).timeout
		if spiel_laeuft:
			_spieler_spawnen()

func _welle_starten():
	welle_laeuft_aus = false
	gegner_gespawnt  = 0
	gegner_pro_welle = 5 + welle * 2
	spawn_pause      = max(0.4, 1.8 - welle * 0.12)
	spawn_timer      = 0.5
	welle_label.text = "Welle %d" % welle

func _process(delta: float):
	if not spiel_laeuft: return
	_gegner_spawnen_tick(delta)
	_muenzen_tick(delta)
	_zeitstopp_tick(delta)
	_doppelpunkte_tick(delta)
	_kollisionen_prüfen()
	_gegner_auserhalb_entfernen()
	_status_ui_update()

func _muenzen_tick(delta: float):
	muenzen_timer -= delta
	if muenzen_timer <= 0:
		muenzen_timer = MUENZEN_PAUSE * randf_range(0.8, 1.2)
		_muenze_spawnen()

func _muenze_spawnen():
	var m = MUENZE_SZENE.instantiate()
	m.position = Vector2(randf_range(30, 450), -30)
	m.typ = _zufaelliger_powerup_typ()
	m.eingesammelt.connect(_powerup_einsammeln)
	muenzen_layer.add_child(m)

func _zufaelliger_powerup_typ() -> int:
	# Gewichtete Auswahl. Todesbombe ist die gefährlichste Münze.
	# Mega-Münze ist extrem selten und super stark.
	# Chaos und Bombe sind ebenfalls selten. Triple bleibt das Brot-und-Butter-Power-Up.
	var r = randf()
	if r < 0.01: return PU_MEGA          # 1 %  – Jackpot
	if r < 0.13: return PU_TODESBOMBE    # 12 % – Game Over Falle
	if r < 0.18: return PU_CHAOS         # 5 %
	if r < 0.28: return PU_BOMBE         # 10 %
	if r < 0.43: return PU_DOPPELPUNKTE  # 15 %
	if r < 0.58: return PU_ZEITSTOPP     # 15 %
	if r < 0.78: return PU_SCHNELLFEUER  # 20 %
	return PU_TRIPLE                     # 22 %

# ─── Power-Up Einsammeln ──────────────────────────────────────────────────────
func _powerup_einsammeln(typ: int):
	match typ:
		PU_TRIPLE:        _aktiviere_triple()
		PU_SCHNELLFEUER:  _aktiviere_schnellfeuer()
		PU_ZEITSTOPP:     _aktiviere_zeitstopp()
		PU_DOPPELPUNKTE:  _aktiviere_doppelpunkte()
		PU_BOMBE:         _aktiviere_bombe()
		PU_CHAOS:         _aktiviere_chaos()
		PU_TODESBOMBE:    _aktiviere_todesbombe()
		PU_MEGA:          _aktiviere_mega()
		_:                _aktiviere_triple()

func _aktiviere_triple():
	if spieler and is_instance_valid(spieler):
		spieler.boost_aktivieren()
		_explosion_bei(spieler.position, Color(1.0, 0.9, 0.1), "gegner")

func _aktiviere_schnellfeuer():
	if spieler and is_instance_valid(spieler):
		spieler.schnellfeuer_aktivieren()
		_explosion_bei(spieler.position, Color(0.2, 0.9, 1.0), "gegner")

func _aktiviere_zeitstopp():
	zeitstopp_aktiv = true
	zeitstopp_timer = ZEITSTOPP_DAUER
	# Alle Gegner und Gegner-Geschosse einfrieren
	for gn in gegner_layer.get_children():
		if is_instance_valid(gn) and gn.has_method("einfrieren_setzen"):
			gn.einfrieren_setzen(true)
	for gs in geschoss_layer.get_children():
		if is_instance_valid(gs) and gs.has_method("einfrieren_setzen"):
			gs.einfrieren_setzen(true)
	if spieler and is_instance_valid(spieler):
		_explosion_bei(spieler.position, Color(0.75, 0.4, 1.0), "gegner")

func _aktiviere_doppelpunkte():
	doppelpunkte_aktiv = true
	doppelpunkte_timer = DOPPELPUNKTE_DAUER
	if spieler and is_instance_valid(spieler):
		_explosion_bei(spieler.position, Color(0.3, 1.0, 0.45), "gegner")

func _aktiviere_bombe():
	# Alle Gegner auf dem Screen vernichten – Punkte zählen mit
	var faktor = 2 if doppelpunkte_aktiv else 1
	for gn in gegner_layer.get_children():
		if is_instance_valid(gn):
			_explosion_bei(gn.position, gn.farbe, "gegner")
			punkte += gn.punkte_wert * faktor
			gn.queue_free()
	# Gegner-Geschosse zusätzlich entfernen, damit der Screen wirklich "leer" ist
	for gs in geschoss_layer.get_children():
		if is_instance_valid(gs) and not gs.spieler_geschoss:
			gs.queue_free()
	# Kleiner Bildschirm-Flash über mehrere Explosionen
	for i in range(6):
		var p = Vector2(randf_range(40, 440), randf_range(80, 600))
		_explosion_bei(p, Color(1.0, 0.55, 0.15), "gegner")
	_ui_update()

func _aktiviere_chaos():
	if spieler and is_instance_valid(spieler):
		spieler.chaos_aktivieren()
		_explosion_bei(spieler.position, Color(1.0, 0.3, 0.8), "gegner")

func _aktiviere_todesbombe():
	# Die rote Trap-Münze: sprengt den gesamten Bildschirm, kostet alle Leben.
	# Alles auf dem Spielfeld geht hoch – Gegner, Gegner-Geschosse, Spieler.
	# Keine Punkte! Reine Strafe.

	# Spieler-Geschosse auch wegputzen, damit der ganze Screen "kracht"
	for gs in geschoss_layer.get_children():
		if is_instance_valid(gs):
			gs.queue_free()

	# Alle Gegner explodieren lassen (ohne Punkte zu vergeben)
	for gn in gegner_layer.get_children():
		if is_instance_valid(gn):
			_explosion_bei(gn.position, Color(1.0, 0.2, 0.1), "gegner")
			gn.queue_free()

	# Bildschirmfüllendes Explosionsfeuerwerk in rot/orange
	var anzahl = 28
	for i in range(anzahl):
		var p = Vector2(randf_range(20, 460), randf_range(20, 720))
		var farbe = Color(1.0, randf_range(0.1, 0.4), randf_range(0.05, 0.2))
		var typ_str = "spieler" if i % 4 == 0 else "gegner"
		_explosion_bei(p, farbe, typ_str)

	# Spieler-Schiff zerstören + alle Leben auf einmal abziehen
	if spieler and is_instance_valid(spieler):
		_explosion_bei(spieler.position, Color(1.0, 0.1, 0.0), "spieler")
		for i in range(5):
			var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			_explosion_bei(spieler.position + offset, Color(1.0, 0.3, 0.0), "spieler")

	leben = 0
	_ui_update()
	# Kurze Verzögerung, damit die Explosionsanimation noch sichtbar ist,
	# bevor das Game-Over-Panel hochfährt.
	await get_tree().create_timer(0.6).timeout
	if spieler and is_instance_valid(spieler):
		spieler.queue_free()
	_game_over()

func _aktiviere_mega():
	# Mega-Münze: alle guten Effekte für 15 s + 6-Schuss-Modus.
	# Zeitstopp ist absichtlich NICHT dabei.
	const MEGA_DAUER : float = 15.0
	if spieler and is_instance_valid(spieler):
		spieler.boost_aktivieren(MEGA_DAUER)        # Triple-Sprite + Boost-State
		spieler.schnellfeuer_aktivieren(MEGA_DAUER) # Maschinengewehr-Feuerrate
		spieler.mega_aktivieren(MEGA_DAUER)         # 6 Schüsse statt 3
		# Doppelpunkte für 15 s
		doppelpunkte_aktiv = true
		doppelpunkte_timer = MEGA_DAUER
		# Goldener Effekt-Burst am Spieler
		for i in range(8):
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			_explosion_bei(spieler.position + offset, Color(1.4, 1.1, 0.2), "gegner")

# ─── Zeitstopp Ablauf ─────────────────────────────────────────────────────────
func _zeitstopp_tick(delta: float):
	if not zeitstopp_aktiv: return
	zeitstopp_timer -= delta
	if zeitstopp_timer <= 0:
		zeitstopp_aktiv = false
		# Wieder auftauen
		for gn in gegner_layer.get_children():
			if is_instance_valid(gn) and gn.has_method("einfrieren_setzen"):
				gn.einfrieren_setzen(false)
		for gs in geschoss_layer.get_children():
			if is_instance_valid(gs) and gs.has_method("einfrieren_setzen"):
				gs.einfrieren_setzen(false)

func _doppelpunkte_tick(delta: float):
	if not doppelpunkte_aktiv: return
	doppelpunkte_timer -= delta
	if doppelpunkte_timer <= 0:
		doppelpunkte_aktiv = false

# ─── Status-Anzeige ───────────────────────────────────────────────────────────
func _status_ui_update():
	# Triple-Shot
	if boost_label:
		if spieler and is_instance_valid(spieler) and spieler.boost_aktiv:
			boost_label.text    = "⚡ TRIPLE SHOT  %.0fs ⚡" % spieler.boost_verbleibend()
			boost_label.visible = true
		else:
			boost_label.visible = false
	# Schnellfeuer
	if schnellfeuer_label:
		if spieler and is_instance_valid(spieler) and spieler.schnellfeuer_aktiv:
			schnellfeuer_label.text    = "🔫 MASCHINENGEWEHR  %.0fs" % spieler.schnellfeuer_verbleibend()
			schnellfeuer_label.visible = true
		else:
			schnellfeuer_label.visible = false
	# Zeitstopp
	if zeitstopp_label:
		if zeitstopp_aktiv:
			zeitstopp_label.text    = "❄ ZEITSTOPP  %.1fs" % zeitstopp_timer
			zeitstopp_label.visible = true
		else:
			zeitstopp_label.visible = false
	# Doppel-Punkte
	if doppel_label:
		if doppelpunkte_aktiv:
			doppel_label.text    = "✦ x2 PUNKTE  %.0fs" % doppelpunkte_timer
			doppel_label.visible = true
		else:
			doppel_label.visible = false
	# Chaos
	if chaos_label:
		if spieler and is_instance_valid(spieler) and spieler.chaos_aktiv:
			chaos_label.text    = "↺ STEUERUNG VERTAUSCHT  %.0fs" % spieler.chaos_verbleibend()
			chaos_label.visible = true
		else:
			chaos_label.visible = false
	# Mega
	if mega_label:
		if spieler and is_instance_valid(spieler) and spieler.mega_aktiv:
			mega_label.text    = "★ MEGA-BOOST  %.0fs ★" % spieler.mega_verbleibend()
			mega_label.visible = true
		else:
			mega_label.visible = false

func _gegner_spawnen_tick(delta: float):
	if gegner_gespawnt >= gegner_pro_welle: return
	spawn_timer -= delta
	if spawn_timer > 0: return
	spawn_timer = spawn_pause
	_gegner_spawnen()
	gegner_gespawnt += 1

func _gegner_spawnen():
	var g = GEGNER_SZENE.instantiate()
	var t = _zufaelliger_typ()
	g.typ = t
	g.position = Vector2(randf_range(40, 440), -40)
	g.geschwindigkeit = _typ_geschw(t)
	g.punkte_wert     = _typ_punkte(t)
	g.abgeschossen.connect(_bei_abschuss.bind(g))
	g.schiesst.connect(_gegner_schuss)
	gegner_layer.add_child(g)
	# Frisch gespawnter Gegner während Zeitstopp ebenfalls einfrieren
	if zeitstopp_aktiv and g.has_method("einfrieren_setzen"):
		g.einfrieren_setzen(true)

func _zufaelliger_typ() -> int:
	if welle >= 5 and randf() < 0.15: return 3
	if welle >= 3 and randf() < 0.25: return 2
	return 1

func _typ_geschw(t: int) -> Vector2:
	match t:
		1: return Vector2(randf_range(-30, 30), gegner_geschw_base + welle * 8)
		2: return Vector2(randf_range(-60, 60), gegner_geschw_base + welle * 14)
		3: return Vector2(0, 55 + welle * 4)
	return Vector2(0, 80)

func _typ_punkte(t: int) -> int:
	match t:
		1: return 10
		2: return 25
		3: return 80
	return 10

func _gegner_schuss(pos: Vector2):
	if not spiel_laeuft: return
	# Während Zeitstopp dürfen Gegner gar nicht erst feuern. Sicherheitsnetz.
	if zeitstopp_aktiv: return
	var g = GESCHOSS_SZENE.instantiate()
	g.position = pos
	g.spieler_geschoss = false
	g.geschwindigkeit  = Vector2(0, 480)
	geschoss_layer.add_child(g)

func _kollisionen_prüfen():
	var geschosse = geschoss_layer.get_children()
	var gegner    = gegner_layer.get_children()
	var muenzen   = muenzen_layer.get_children()

	for gs in geschosse:
		if not is_instance_valid(gs): continue
		if gs.spieler_geschoss:
			for mn in muenzen:
				if not is_instance_valid(mn): continue
				if gs.position.distance_to(mn.position) < 16:
					gs.queue_free()
					mn.einsammeln()
					break
			if not is_instance_valid(gs): continue
			for gn in gegner:
				if not is_instance_valid(gn): continue
				if gs.position.distance_to(gn.position) < gn.treff_radius:
					_explosion_bei(gn.position, gn.farbe, "gegner")
					gn.schaden_nehmen(gs.schaden)
					gs.queue_free()
					break
		else:
			if spieler and is_instance_valid(spieler) and not spieler.unverwundbar:
				if gs.position.distance_to(spieler.position) < 22:
					gs.queue_free()
					spieler.getroffen.emit()

	if spieler and is_instance_valid(spieler) and not spieler.unverwundbar:
		for gn in gegner:
			if not is_instance_valid(gn): continue
			if gn.position.distance_to(spieler.position) < gn.treff_radius + 18:
				_explosion_bei(gn.position, gn.farbe, "gegner")
				gn.queue_free()
				spieler.getroffen.emit()
				break

func _gegner_auserhalb_entfernen():
	for gn in gegner_layer.get_children():
		if gn.position.y > 760:
			gn.queue_free()
	if gegner_gespawnt >= gegner_pro_welle and gegner_layer.get_child_count() == 0 and not welle_laeuft_aus:
		_welle_beendet()

func _bei_abschuss(gn: Node2D):
	var faktor = 2 if doppelpunkte_aktiv else 1
	punkte += gn.punkte_wert * faktor
	_ui_update()

func _welle_beendet():
	welle_laeuft_aus = true
	welle += 1
	await get_tree().create_timer(1.5).timeout
	if spiel_laeuft:
		_welle_starten()

func _game_over():
	spiel_laeuft = false
	if spieler and is_instance_valid(spieler):
		spieler.queue_free()
	# Musik leiser machen
	if musik_player:
		var tw_musik = create_tween()
		tw_musik.tween_property(musik_player, "volume_db", -40.0, 1.0)
	# Game Over Sound abspielen
	if game_over_sound and game_over_sound.stream:
		game_over_sound.play()
	punkte_end.text = "Punkte: %d" % punkte

	# ── GAME OVER Einblend-Animation ─────────────────────────────────────────
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	titel_label.scale    = Vector2(0.2, 0.2)
	titel_label.modulate = Color(1, 0.1, 0.1, 0)

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(game_over_panel, "modulate:a", 1.0, 0.6)
	tw.tween_property(titel_label, "scale",    Vector2(1.0, 1.0),        0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(titel_label, "modulate", Color(1, 0.2, 0.2, 1),    0.5)

	await get_tree().create_timer(0.8).timeout
	var pulse = create_tween().set_loops()
	pulse.tween_property(titel_label, "modulate", Color(1, 0.6, 0.1, 1), 0.5)
	pulse.tween_property(titel_label, "modulate", Color(1, 0.1, 0.1, 1), 0.5)

func _ui_update():
	punkte_label.text = "Punkte: %d" % punkte
	leben_label.text  = "❤".repeat(leben)
	welle_label.text  = "Welle %d" % welle

func _explosion_bei(pos: Vector2, farbe: Color, typ: String = "gegner"):
	var e = EXPLOSION_SZENE.instantiate()
	e.position = pos
	e.farbe    = farbe
	e.typ      = typ
	effekt_layer.add_child(e)
