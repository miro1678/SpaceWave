extends Node2D

# ─── Explosion via AnimatedSprite2D ──────────────────────────────────────────

var farbe : Color = Color(1, 0.5, 0)   # Wird für Modulate genutzt

@onready var anim_sprite : AnimatedSprite2D = $AnimSprite

func _ready():
	# SpriteFrames dynamisch aufbauen
	var frames = SpriteFrames.new()
	frames.add_animation("explode")
	frames.set_animation_speed("explode", 18.0)
	frames.set_animation_loop("explode", false)

	for i in range(10):
		var tex = load("res://assets/effects/fire%02d.png" % i)
		frames.add_frame("explode", tex)

	anim_sprite.sprite_frames = frames
	anim_sprite.modulate      = farbe
	anim_sprite.play("explode")
	anim_sprite.animation_finished.connect(queue_free)
