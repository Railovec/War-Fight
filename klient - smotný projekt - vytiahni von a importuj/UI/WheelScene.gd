extends CanvasLayer

@onready var wheel = $Zasranekoleso3
@onready var arrow = $Arrow
@onready var result_label = $ResultLabel
@onready var background = $Background

const REWARDS = [
	{"type": "duplicate", "value": "duplikat", "label": "Duplikát karty!"},
	{"type": "trophies", "value": 10, "label": "+10 Trofejí!"},
	{"type": "gold", "value": 500, "label": "500 Goldov!"},
	{"type": "card", "value": "karta", "label": "Nová karta!"},
	{"type": "gold", "value": 100, "label": "100 Goldov!"},
	{"type": "mega_spin", "value": 0, "label": "MEGA SPIN!"},
	
	
	{"type": "rare_card", "value": "vzacna_karta", "label": "Vzácna karta!"},
	
	{"type": "card", "value": "karta", "label": "Nová karta!"},
	
	
	

]



const SECTOR_ANGLE = 360.0 / 8.0
const WHEEL_OFFSET = 0.0  # uprav ak sektor 0 nesedí s obrázkom

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
	$AudioStreamPlayer2D.play()

	is_spinning = true
	result_label.visible = false

	final_reward_index = randi() % 8

	var sector_center = final_reward_index * SECTOR_ANGLE + SECTOR_ANGLE / 2.0 + WHEEL_OFFSET
	var extra_rotations = 360.0 * (5 + randi() % 5)
	var current_mod = fmod(current_rotation, 360.0)
	var delta_to_target = fmod(sector_center - current_mod + 360.0, 360.0)

	target_rotation = current_rotation + extra_rotations + delta_to_target
	spin_speed = 1800.0
	spin_deceleration = 120.0



func _process(delta):
	if not is_spinning:
		$AudioStreamPlayer2D.stop()
		return
	spin_speed = max(0.0, spin_speed - spin_deceleration * delta)

	var next_rotation = current_rotation + spin_speed * delta
	if next_rotation >= target_rotation:
		current_rotation = target_rotation
		wheel.rotation_degrees = current_rotation
		is_spinning = false
		_on_spin_finished()
		return

	current_rotation = next_rotation
	wheel.rotation_degrees = current_rotation


func _on_spin_finished():
	var reward = REWARDS[final_reward_index]
	result_label.text = reward["label"]
	result_label.visible = true
	print("🎰 Odmena: ", reward["label"])

	if reward["type"] == "mega_spin":
		result_label.text = "MEGA SPIN! Točíš znova 2x!"
		await get_tree().create_timer(1.5).timeout
		is_spinning = false
		spin()
		await get_tree().create_timer(8.0).timeout
		is_spinning = false
		spin()
		return

	await _apply_reward(reward)
	emit_signal("reward_selected", reward)
	await get_tree().create_timer(3.0).timeout
	visible = false


func _get_cards_for_current_arena() -> Array:
	var trophies = Global.trophies
	if trophies >= 2000:
		return ["spawn_vojak_ww2", "spawn_panzer", "spawn_odstrelec"]
	elif trophies >= 1500:
		return ["spawn_musketier", "spawn_parny_tank", "spawn_inzinier", "spawn_dynamiter"]
	elif trophies >= 1000:
		return ["spawn_rytier", "spawn_trebuchet", "spawn_mnich", "spawn_drak"]
	elif trophies >= 600:
		return ["spawn_legionar", "spawn_balistar", "spawn_gladiator", "spawn_saboter"]
	elif trophies >= 300:
		return ["spawn_bronzovy_vojak", "spawn_vojnovy_voz", "spawn_lukostrelec", "spawn_faraon"]
	else:
		return ["spawn_jaskynny_muz", "spawn_lovec", "spawn_saman", "spawn_mamut"]

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
			var available_cards = _get_cards_for_current_arena()
			var random_card = available_cards[randi() % available_cards.size()]
			await Supabase.add_card(uuid, random_card)
			result_label.text = "Karta: " + random_card.replace("spawn_", "").capitalize() + "!"
		"duplicate":
			var available_cards = _get_cards_for_current_arena()
			var random_card = available_cards[randi() % available_cards.size()]
			await Supabase.add_card(uuid, random_card)
			result_label.text = "Duplikát: " + random_card.replace("spawn_", "").capitalize() + "!"
		"gem":
			await Supabase.add_gold(uuid, 50)
			print("💎 Drahokam = 50 gold")
		"mega_spin":
			pass
