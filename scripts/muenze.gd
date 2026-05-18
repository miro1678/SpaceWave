extends Node2D

# ─── Power-Up Münze ───────────────────────────────────────────────────────────

signal eingesammelt

var geschwindigkeit : float = 70.0
var dreh_speed      : float = 2.0
var bob_timer       : float = 0.0
var start_x         : float = 0.0
var abgeschossen    : bool  = false

func _ready():
	start_x = position.x

func _process(delta: float):
	position.y += geschwindigkeit * delta
	bob_timer  += delta
	position.x  = start_x + sin(bob_timer * 2.2) * 10.0
	rotation   += dreh_speed * delta
	if position.y > 760:
		queue_free()

func einsammeln():
	if abgeschossen: return
	abgeschossen = true
	emit_signal("eingesammelt")
	queue_free()
