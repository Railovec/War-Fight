extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func setup(data: Dictionary):
	position.x = data.get("from_x", 0.0)
	position.y = 325

	var tex = load("res://Card/Card_images/musketier_projectile.png")
	sprite.texture = tex
	sprite.scale = Vector2(0.15, 0.15)

	# Flip ak ide doľava
	if data.get("to_x", 0.0) < data.get("from_x", 0.0):
		sprite.flip_h = true

func update_position(new_x: float):
	position.x = new_x
