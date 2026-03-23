extends CanvasLayer

@onready var wheel = $Wheel
@onready var arrow = $Arrow
@onready var result_label = $ResultLabel
@onready var background = $Background

# 8 sektorov kolesa — musí sedieť s obrázkom (v smere hodinových ručičiek)
const REWARDS = [
	{"type": "card", "value": "karta", "label": "Nová karta!"},
	{"type": "rare_card", "value": "vzacna_karta", "label": "Vzácna karta!"},
	{"type": "gold", "value": 500, "label": "500 Goldov!"},
	{"type": "card", "value": "karta", "label": "Nová karta!"},
	{"type": "mega_spin", "value": 0, "label": "MEGA SPIN!"},
	{"type": "trophies", "value": 10, "label": "+10 Trofejí!"},
	{"type": "gold", "value": 100, "label": "100 Goldov!"},
	{"type": "duplicate", "value": "duplikat", "label": "Duplikát karty!"},
]


const SECTOR_ANGLE = 360.0 / 8.0  # 45 stupňov na sektor

var is_spinning := false
var current_rotation := 0.0
var target_rotation := 0.0
var spin_speed := 0.0
var spin_deceleration := 0.0
var final_reward_index := 0

signal reward_selected(reward)

func _ready():
	visible = false
	result_label.visible = false
	result_label.add_theme_font_size_override("font_size", 28)

func show_wheel():
	visible = true
	result_label.visible = false
	result_label.text = ""

func spin():
	if is_spinning:
		return

	is_spinning = true
	result_label.visible = false

	# Vyber náhodnú odmenu
	final_reward_index = randi() % 8

	# Vypočítaj cieľový uhol
	# Šípka je hore (270 stupňov) — sektor 0 začína hore
	var target_sector_angle = (final_reward_index * SECTOR_ANGLE) + (SECTOR_ANGLE / 2.0)
	var extra_rotations = 360.0 * (5 + randi() % 5)
	target_rotation = current_rotation + extra_rotations + (360.0 - fmod(current_rotation, 360.0)) + (360.0 - target_sector_angle)

	spin_speed = 1800.0  # stupňov za sekundu
	spin_deceleration = 120.0


func _process(delta):
	if not is_spinning:
		return

	spin_speed = max(0.0, spin_speed - spin_deceleration * delta)
	current_rotation += spin_speed * delta
	wheel.rotation_degrees = current_rotation

	if spin_speed <= 0.0:
		is_spinning = false
		_on_spin_finished()


func _on_spin_finished():
	var reward = REWARDS[final_reward_index]
	result_label.text = reward["label"]
	result_label.visible = true
	print("🎰 Odmena: ", reward["label"])
	
	# Aplikuj odmenu
	await _apply_reward(reward)
	
	emit_signal("reward_selected", reward)
	await get_tree().create_timer(3.0).timeout
	visible = false


func _apply_reward(reward: Dictionary) -> void:
	var uuid := Global.player_db_id
	
	match reward["type"]:
		"gold":
			await Supabase.add_gold(uuid, int(reward["value"]))
			print("💰 Pridaných ", reward["value"], " gold")
		
		"trophies":
			Global.trophies += int(reward["value"])
			Global.save_game()
			var body := JSON.stringify({"trophies": Global.trophies})
			await Supabase._request(
				"/rest/v1/players?id=eq." + uuid,
				HTTPClient.METHOD_PATCH, body
			)
			print("🏆 Pridaných ", reward["value"], " trofejí")
		
		"card", "rare_card":
			# Náhodná karta z dostupných
			var available_cards := ["spawn_jaskynny_muz", "spawn_lovec", "spawn_saman", "spawn_mamut"]
			var random_card = available_cards[randi() % available_cards.size()]
			await Supabase.add_card(uuid, random_card)
			result_label.text = "Karta: " + random_card + "!"
		
		"duplicate":
			var available_cards := ["spawn_jaskynny_muz", "spawn_lovec", "spawn_saman", "spawn_mamut"]
			var random_card = available_cards[randi() % available_cards.size()]
			await Supabase.add_card(uuid, random_card)
			result_label.text = "Duplikát: " + random_card + "!"
		
		"gem":
			await Supabase.add_gold(uuid, 50)
			print("💎 Drahokam = 50 gold")
		
		"mega_spin":
			print("⭐ MEGA SPIN!")
			await get_tree().create_timer(1.0).timeout
			spin()
