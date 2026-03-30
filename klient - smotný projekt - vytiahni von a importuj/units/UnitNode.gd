extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $ProgressBar

var owner_id: int = 1
var current_hp: int = 100
var max_hp: int = 100
var unit_type: String = "jaskynny_muz"

# Konfigurácia každej jednotky
const UNIT_CONFIG = {
	"jaskynny_muz": {
		"walk": {"file": "res://Card/Card_images/jaskynny_muz_walk.png", "frames": 5, "cols": 5, "rows": 1, "fps": 8},
		"attack": {"file": "res://Card/Card_images/jaskynny_muz_hit.png", "frames": 6, "cols": 3, "rows": 2, "fps": 10},
	},
	"musketier": {
		"walk": {"file": "res://Card/Card_images/musketier_idle.png", "frames": 5, "cols": 5, "rows": 1, "fps": 6},
		"attack": {"file": "res://Card/Card_images/musketier_attack.png", "frames": 6, "cols": 3, "rows": 2, "fps": 10},
	},
	"mamut": {
		"walk": {"file": "res://Card/Card_images/mamut_walk.png", "frames": 5, "cols": 5, "rows": 1, "fps": 6},
		"attack": {"file": "res://Card/Card_images/mamut_hit.png", "frames": 6, "cols": 3, "rows": 2, "fps": 8},
		"death": {"file": "res://Card/Card_images/mamut_death.png", "frames": 2, "cols": 2, "rows": 1, "fps": 6},
	},
	"vojnovy_voz": {
		"walk": {"file": "res://Card/Card_images/vojnovy_voz_walk.png", "frames": 5, "cols": 5, "rows": 1, "fps": 8},
		"attack": {"file": "res://Card/Card_images/vojnovy_voz_hit.png", "frames": 6, "cols": 3, "rows": 2, "fps": 10},
	},
	"faraon": {
		"walk": {"file": "res://Card/Card_images/faraon_walk.png", "frames": 5, "cols": 5, "rows": 1, "fps": 8},
		"attack": {"file": "res://Card/Card_images/faraon_hit.png", "frames": 6, "cols": 3, "rows": 2, "fps": 10},
		
	
	},
}

func setup(type: String):
	unit_type = type
	_setup_animations()
	_setup_hp_bar()
	sprite.play("walk")
	sprite.animation_finished.connect(_on_animation_finished)

func _setup_animations():
	var frames = SpriteFrames.new()
	var config = UNIT_CONFIG.get(unit_type, UNIT_CONFIG["jaskynny_muz"])

	for anim_name in config.keys():
		var anim = config[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, anim["fps"])
		frames.set_animation_loop(anim_name, anim_name == "walk")

		# Skontroluj či sú framy samostatné súbory alebo jeden sheet
		if anim.get("separate_files", false):
			for i in anim["frames"]:
				var path = anim["file_pattern"] % i
				var tex = load(path)
				frames.add_frame(anim_name, tex)
		else:
			var tex = load(anim["file"])
			var img_size = tex.get_size()
			var fw = img_size.x / anim["cols"]
			var fh = img_size.y / anim["rows"]
			for row in range(anim["rows"]):
				for col in range(anim["cols"]):
					var atlas = AtlasTexture.new()
					atlas.atlas = tex
					atlas.region = Rect2(col * fw, row * fh, fw, fh)
					frames.add_frame(anim_name, atlas)

	sprite.sprite_frames = frames
	sprite.scale = Vector2(0.5, 0.5)

func _setup_hp_bar():
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.position = Vector2(-25, -110) 
	hp_bar.size = Vector2(50, 4)
	hp_bar.show_percentage = false

	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = 3
	style_bg.corner_radius_top_right = 3
	style_bg.corner_radius_bottom_left = 3
	style_bg.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("background", style_bg)

	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.2, 0.85, 0.2)
	style_fill.corner_radius_top_left = 3
	style_fill.corner_radius_top_right = 3
	style_fill.corner_radius_bottom_left = 3
	style_fill.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("fill", style_fill)

func update_from_snapshot(unit_data: Dictionary):
	current_hp = unit_data.get("hp", 100)
	max_hp = unit_data.get("max_hp", 100)
	owner_id = unit_data.get("owner", 1)
	var new_x: float = unit_data.get("pos", 0.0)

	if owner_id == 1:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

	# Offset aby jednotky nestáli na rovnakom mieste
	if owner_id == 1:
		position.x = new_x - 30
	else:
		position.x = new_x + 30
	position.y = 325
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	_update_hp_bar_color()

	var just_fired: bool = unit_data.get("just_fired", false)
	if just_fired and sprite.animation != "attack":
		sprite.play("attack")
	elif not just_fired and sprite.animation == "walk":
		sprite.play("walk")

func play_death():
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	queue_free()

func _on_animation_finished():
	if sprite.animation == "attack":
		sprite.play("walk")

func _update_hp_bar_color():
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	var style_fill = StyleBoxFlat.new()
	if pct > 0.6:
		style_fill.bg_color = Color(0.2, 0.85, 0.2)
	elif pct > 0.3:
		style_fill.bg_color = Color(0.95, 0.75, 0.1)
	else:
		style_fill.bg_color = Color(0.9, 0.15, 0.15)
	style_fill.corner_radius_top_left = 3
	style_fill.corner_radius_top_right = 3
	style_fill.corner_radius_bottom_left = 3
	style_fill.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("fill", style_fill)
