extends Node2D

# ─── Geschoss ─────────────────────────────────────────────────────────────────

var geschwindigkeit  : Vector2 = Vector2(0, -550)
var spieler_geschoss : bool    = true
var schaden          : int     = 1

@onready var sprite : Sprite2D = $Sprite

func _ready():
	if spieler_geschoss:
		sprite.texture = load("res://assets/lasers/laser_spieler.png")
		sprite.scale   = Vector2(1.2, 1.2)
	else:
		sprite.texture = load("res://assets/lasers/laser_gegner.png")
		sprite.scale   = Vector2(1.0, 1.0)
		sprite.rotation_degrees = 180   # Gegner-Laser zeigt nach unten

	# Sprite zur Flugrichtung ausrichten
	sprite.rotation = geschwindigkeit.angle() + PI / 2.0

func _process(delta: float):
	position += geschwindigkeit * delta
	if position.y < -30 or position.y > 750 or position.x < -30 or position.x > 510:
		queue_free()
