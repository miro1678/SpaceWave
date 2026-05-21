extends Node2D

const MUENZEN := [
	{"name": "Triple Shot",   "farbe": Color(1.00, 0.90, 0.10), "info": "3 Schuesse gleichzeitig  -  10s"},
	{"name": "Schnellfeuer",  "farbe": Color(0.20, 0.90, 1.00), "info": "Maschinengewehr-Modus  -  10s"},
	{"name": "Zeitstopp",     "farbe": Color(0.75, 0.40, 1.00), "info": "Gegner einfrieren  -  3s"},
	{"name": "Doppelpunkte",  "farbe": Color(0.30, 1.00, 0.45), "info": "Doppelte Punkte  -  10s"},
	{"name": "Bombe",         "farbe": Color(1.00, 0.45, 0.15), "info": "Alle Gegner sofort eliminieren"},
	{"name": "Chaos",         "farbe": Color(1.00, 0.30, 0.80), "info": "Steuerung vertauscht  -  5s"},
	{"name": "Todesbombe",    "farbe": Color(1.00, 0.10, 0.10), "info": "Vorsicht: sofortiges Game Over!"},
	{"name": "Mega-Boost",    "farbe": Color(1.40, 1.10, 0.20), "info": "Alle guten Effekte aktiv  -  15s"},
]

var _cl : CanvasLayer

func _ready() -> void:
	_cl = CanvasLayer.new()
	add_child(_cl)
	_hintergrund()
	_sterne()
	_titel()
	_muenzen_panel()
	_start_knopf()
	_steuerung_text()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_spiel_starten()

# ─── Hintergrund ──────────────────────────────────────────────────────────────

func _hintergrund() -> void:
	var bg := TextureRect.new()
	var tex = load("res://assets/bg/hintergrund.png")
	if tex:
		bg.texture = tex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(480, 720))
	_cl.add_child(bg)

func _sterne() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 40:
		var dot := ColorRect.new()
		var sz := rng.randf_range(1.0, 3.0)
		dot.color = Color(1, 1, 1, rng.randf_range(0.2, 0.8))
		dot.set_position(Vector2(rng.randf_range(0, 480), rng.randf_range(0, 720)))
		dot.set_size(Vector2(sz, sz))
		_cl.add_child(dot)

# ─── Titel ────────────────────────────────────────────────────────────────────

func _titel() -> void:
	# Schatten
	var schatten := Label.new()
	schatten.text = "SpaceWave"
	schatten.add_theme_font_size_override("font_size", 56)
	schatten.add_theme_color_override("font_color", Color(0.0, 0.05, 0.2, 0.7))
	schatten.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	schatten.set_position(Vector2(4, 28))
	schatten.set_size(Vector2(480, 72))
	_cl.add_child(schatten)

	# Titel
	var titel := Label.new()
	titel.text = "SpaceWave"
	titel.add_theme_font_size_override("font_size", 56)
	titel.add_theme_color_override("font_color", Color(0.35, 0.78, 1.0))
	titel.add_theme_constant_override("outline_size", 3)
	titel.add_theme_color_override("font_outline_color", Color(0.0, 0.25, 0.65))
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titel.set_position(Vector2(0, 24))
	titel.set_size(Vector2(480, 72))
	_cl.add_child(titel)

	# Untertitel
	var sub := Label.new()
	sub.text = "Space Shooter"
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.45, 0.70, 1.0, 0.85))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_position(Vector2(0, 86))
	sub.set_size(Vector2(480, 24))
	_cl.add_child(sub)

# ─── Power-Up Panel ───────────────────────────────────────────────────────────

func _muenzen_panel() -> void:
	# Hintergrund-Panel
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color       = Color(0.0, 0.04, 0.15, 0.90)
	style.border_color   = Color(0.22, 0.52, 1.0, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_position(Vector2(16, 116))
	panel.set_size(Vector2(448, 370))
	_cl.add_child(panel)

	# Panel-Kopfzeile
	var kopf := Label.new()
	kopf.text = "Power-Up Muenzen"
	kopf.add_theme_font_size_override("font_size", 15)
	kopf.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0))
	kopf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kopf.set_position(Vector2(16, 120))
	kopf.set_size(Vector2(448, 26))
	_cl.add_child(kopf)

	# Trennlinie
	var linie := ColorRect.new()
	linie.color = Color(0.22, 0.52, 1.0, 0.35)
	linie.set_position(Vector2(36, 148))
	linie.set_size(Vector2(408, 1))
	_cl.add_child(linie)

	# 2-spaltiges Raster
	for i in MUENZEN.size():
		var m      = MUENZEN[i]
		var col    := i % 2
		var row    := i / 2
		var x      := 28 + col * 226
		var y      := 156 + row * 80

		# Farbiger Punkt als Muenzen-Symbol
		var punkt := ColorRect.new()
		punkt.color = m["farbe"]
		punkt.set_position(Vector2(x, y + 8))
		punkt.set_size(Vector2(13, 13))
		_cl.add_child(punkt)

		# Muenzen-Name
		var name_lbl := Label.new()
		name_lbl.text = m["name"]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", m["farbe"])
		name_lbl.set_position(Vector2(x + 20, y))
		name_lbl.set_size(Vector2(210, 24))
		_cl.add_child(name_lbl)

		# Beschreibung
		var info_lbl := Label.new()
		info_lbl.text = m["info"]
		info_lbl.add_theme_font_size_override("font_size", 12)
		info_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
		info_lbl.set_position(Vector2(x + 20, y + 24))
		info_lbl.set_size(Vector2(210, 20))
		_cl.add_child(info_lbl)

# ─── Start-Knopf ──────────────────────────────────────────────────────────────

func _start_knopf() -> void:
	var btn := Button.new()
	btn.text = "SPIELEN"
	btn.set_position(Vector2(130, 506))
	btn.set_size(Vector2(220, 58))
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color",       Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.8, 0.96, 1.0))

	var _style := func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(2)
		s.set_corner_radius_all(12)
		return s

	btn.add_theme_stylebox_override("normal",  _style.call(Color(0.07, 0.28, 0.72), Color(0.28, 0.62, 1.0)))
	btn.add_theme_stylebox_override("hover",   _style.call(Color(0.14, 0.42, 0.92), Color(0.50, 0.80, 1.0)))
	btn.add_theme_stylebox_override("pressed", _style.call(Color(0.04, 0.16, 0.52), Color(0.20, 0.48, 0.90)))
	btn.add_theme_stylebox_override("focus",   _style.call(Color(0.07, 0.28, 0.72), Color(0.28, 0.62, 1.0)))

	btn.pressed.connect(_spiel_starten)
	_cl.add_child(btn)

# ─── Steuerung Hinweis ────────────────────────────────────────────────────────

func _steuerung_text() -> void:
	var lbl := Label.new()
	lbl.text = "Bewegen: Pfeiltasten     Schiessen: Leertaste"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.62, 0.88, 0.75))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_position(Vector2(0, 582))
	lbl.set_size(Vector2(480, 26))
	_cl.add_child(lbl)

func _spiel_starten() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
