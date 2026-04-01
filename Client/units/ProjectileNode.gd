extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const PROJECTILE_TEXTURES = {
	"musketier": preload("res://Card/Card_images/musketier_projectile.png"),
	"odstrelec": preload("res://Card/Card_images/musketier_projectile.png"),
	"lukostrelec": preload("res://sip.png"),
}

var target_x: float = 0.0

func setup(data: Dictionary):
	position.x = data.get("from_x", 0.0)
	position.y = 325
	target_x = position.x
	var ptype = data.get("unit_type", "musketier")
	sprite.texture = PROJECTILE_TEXTURES.get(ptype, PROJECTILE_TEXTURES["musketier"])
	sprite.scale = Vector2(0.15, 0.15)
	if data.get("to_x", 0.0) < data.get("from_x", 0.0):
		sprite.flip_h = true

func update_position(new_x: float):
	target_x = new_x

func _process(delta):
	position.x = lerp(position.x, target_x, 15.0 * delta)
