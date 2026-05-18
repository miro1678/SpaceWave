extends Node2D

const SPIELER_SZENE     = preload("res://scenes/spieler.tscn")
const GEGNER_SZENE      = preload("res://scenes/gegner.tscn")
const GESCHOSS_SZENE    = preload("res://scenes/geschoss.tscn")
const EXPLOSION_SZENE   = preload("res://scenes/explosion.tscn")
const MUENZE_SZENE      = preload("res://scenes/muenze.tscn")

var punkte        : int  = 0
var leben         : int  = 3
var welle         : int  = 1
var spiel_laeuft  : bool = false

# Wellen-Spawn-Parameter
var gegner_pro_welle   : int   = 6
var spawn_pause        : float = 1.8
var spawn_timer        : float = 0.0
var gegner_gespawnt    : int   = 0
var gegner_geschw_base : float = 80.0
var welle_laeuft_aus   : bool  = false

var muenzen_timer      : float = 40.0
const MUENZEN_PAUSE    : float = 40.0

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

var spieler      : Node2D = null
var muenzen_layer: Node2D = null
var boost_label  : Label  = null

func _ready():
	neu_start_btn.pressed.connect(_neu_starten)

	muenzen_layer = Node2D.new()
	muenzen_layer.name = "MuenzenLayer"
	add_child(muenzen_layer)

	var ui = $UI
	boost_label = Label.new()
	boost_label.name = "BoostLabel"
	boost_label.add_theme_font_size_override("font_size", 20)
	boost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_label.offset_left   = 100
	boost_label.offset_top    = 44
	boost_label.offset_right  = 380
	boost_label.offset_bottom = 70
	boost_label.visible = false
	ui.add_child(boost_label)

	_starten()

func _starten():
	punkte = 0
	leben  = 3
	welle  = 1
	spiel_laeuft = true
	muenzen_timer = 12.0
	game_over_panel.visible = false
	if boost_label: boost_label.visible = false
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
	_explosion_bei(spieler.position, Color(1.0, 0.071, 0.0, 1.0))
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
	_kollisionen_prüfen()
	_gegner_auserhalb_entfernen()
	_boost_ui_update()

func _muenzen_tick(delta: float):
	muenzen_timer -= delta
	if muenzen_timer <= 0:
		muenzen_timer = MUENZEN_PAUSE * randf_range(0.8, 1.2)
		_muenze_spawnen()

func _muenze_spawnen():
	var m = MUENZE_SZENE.instantiate()
	m.position = Vector2(randf_range(30, 450), -30)
	m.eingesammelt.connect(_boost_aktivieren)
	muenzen_layer.add_child(m)

func _boost_aktivieren():
	if spieler and is_instance_valid(spieler):
		spieler.boost_aktivieren()
		_explosion_bei(spieler.position, Color(1.0, 0.9, 0.1))

func _boost_ui_update():
	if not boost_label: return
	if spieler and is_instance_valid(spieler) and spieler.boost_aktiv:
		var t = spieler.boost_verbleibend()
		boost_label.text    = "⚡ TRIPLE SHOT  %.0fs ⚡" % t
		boost_label.visible = true
	else:
		boost_label.visible = false

func _gegner_spawnen_tick(delta: float):
	if gegner_gespawnt >= gegner_pro_welle: return
	spawn_timer -= delta
	if spawn_timer > 0: return
	spawn_timer = spawn_pause
	_gegner_spawnen()
	gegner_gespawnt += 1

func _gegner_spawnen():
	var g = GEGNER_SZENE.instantiate()
	var typ = _zufaelliger_typ()
	g.typ = typ
	g.position = Vector2(randf_range(40, 440), -40)
	g.geschwindigkeit = _typ_geschw(typ)
	g.punkte_wert     = _typ_punkte(typ)
	g.abgeschossen.connect(_bei_abschuss.bind(g))
	g.schiesst.connect(_gegner_schuss)
	gegner_layer.add_child(g)

func _zufaelliger_typ() -> int:
	var w = welle
	if w >= 5 and randf() < 0.15: return 3   # Boss
	if w >= 3 and randf() < 0.25: return 2   # Schnell
	return 1                                   # Standard

func _typ_geschw(typ: int) -> Vector2:
	match typ:
		1: return Vector2(randf_range(-30, 30), gegner_geschw_base + welle * 8)
		2: return Vector2(randf_range(-60, 60), gegner_geschw_base + welle * 14)
		3: return Vector2(0, 55 + welle * 4)
	return Vector2(0, 80)

func _typ_punkte(typ: int) -> int:
	match typ:
		1: return 10
		2: return 25
		3: return 80
	return 10

func _gegner_schuss(pos: Vector2):
	if not spiel_laeuft: return
	var g = GESCHOSS_SZENE.instantiate()
	g.position = pos
	g.spieler_geschoss = false
	g.geschwindigkeit  = Vector2(0, 300)
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
					_explosion_bei(gn.position, gn.farbe)
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
				_explosion_bei(gn.position, gn.farbe)
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
	punkte += gn.punkte_wert
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
	punkte_end.text = "Punkte: %d" % punkte
	game_over_panel.visible = true

func _ui_update():
	punkte_label.text = "Punkte: %d" % punkte
	leben_label.text  = "❤".repeat(leben)
	welle_label.text  = "Welle %d" % welle

func _explosion_bei(pos: Vector2, farbe: Color):
	var e = EXPLOSION_SZENE.instantiate()
	e.position = pos
	e.farbe = farbe
	effekt_layer.add_child(e)
