extends Node2D

# ─── Explosion via AnimatedSprite2D ──────────────────────────────────────────
# typ: "spieler" = große 22-Frame Explosion (explosion-1-e)
#      "gegner"  = mittlere 12-Frame Explosion (explosion-1-d)

var farbe : Color = Color(1, 0.5, 0)
var typ   : String = "gegner"

@onready var anim_sprite : AnimatedSprite2D = $AnimSprite

func _ready():
	var frames = SpriteFrames.new()
	frames.add_animation("explode")
	frames.set_animation_loop("explode", false)

	if typ == "spieler":
		# explosion-1-e: 22 Frames, große Explosion
		frames.set_animation_speed("explode", 20.0)
		anim_sprite.scale = Vector2(2.2, 2.2)
		for i in range(1, 23):
			var tex = load("res://assets/explosions/spieler/explosion-e%d.png" % i)
			if tex: frames.add_frame("explode", tex)
		# Zweite versetzt für mehr Wumms
		var e2 = anim_sprite.duplicate()
		e2.scale    = Vector2(1.5, 1.5)
		e2.modulate = Color(1.0, 0.7, 0.1)
		e2.position = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		add_child(e2)
		e2.sprite_frames = frames
		e2.play("explode")
	else:
		# explosion-1-d: 12 Frames, Gegner-Explosion
		frames.set_animation_speed("explode", 16.0)
		anim_sprite.scale = Vector2(1.2, 1.2)
		for i in range(1, 13):
			var tex = load("res://assets/explosions/gegner/explosion-d%d.png" % i)
			if tex: frames.add_frame("explode", tex)

	anim_sprite.modulate      = farbe
	anim_sprite.sprite_frames = frames
	anim_sprite.play("explode")
	anim_sprite.animation_finished.connect(queue_free)
