extends Node
# var xp=0
var gold: int = 0
var damage_level=1
var xp_mnozstvo_level=1
var coiny_mnozstvo_level=1
var energy_level=1
var peniaze_level=5
var max_peniaze_level=1
var zivoty_level=1
var username: String = ""
var trophies: int = 0
var player_db_id: String = ""  # toto bude náš UUID
var card_levels: Dictionary = {}  
var card_counts: Dictionary = {}  # card_id -> count
var last_match_won: bool = false
var game_over_shown: bool = false
 
var click_player: AudioStreamPlayer
var click_playerdva: AudioStreamPlayer



func play_click():
	click_player.play()
	
func play_clickdva():
	click_playerdva.play()

var deck: Array = ["", "", "", "", "", ""]  # 6 slotov, prázdne = nezaplnené

# ci je postava odomknuta
var postavy = {
	"res://nesmej sa/bul/pistol(SILENT STRIKER.png": false,
	"res://Card/Card_profile_picture/musketier_profile.png": true,
	"res://Card/Card_profile_picture/jaskynny_muz_profile.png": true,
	"res://Card/Card_profile_picture/mamut_profile.png": true,
	"res://Card/Card_profile_picture/vojnovy_voz_profile.png": true,
	"res://Card/Card_profile_picture/faraon_profile.png": true,
	"res://Card/Card_profile_picture/gladiator_profile.png": true,
	"res://Card/Card_profile_picture/falkar_profile.png": true,
	"res://Card/Card_profile_picture/jaskynny_strelec_profile.png": true,
	"res://Card/Card_profile_picture/mnich_profile.png": true,
	"res://Card/Card_profile_picture/lukostrelec.png": true,
	"res://Card/Card_profile_picture/inzinier_profile.png": true,
	"res://Card/Card_profile_picture/dynamiter_profile.png": true,
	"res://Card/Card_profile_picture/lovec_profile.png": true,
	"res://Card/Card_profile_picture/vojak_ww2_profile.png": true,
	"res://Card/Card_profile_picture/bronzovy_vojak_profile.png": true,
	"res://Card/Card_profile_picture/rytier_profile.png": true,
	"res://Card/Card_profile_picture/panzer_profile.png": true,
	"res://Card/Card_profile_picture/legionar_profile.png": true,
	"res://Card/Card_profile_picture/saboter_profile.png": true,
	"res://Card/Card_profile_picture/parny_tank_profile.png": true,
	"res://Card/Card_profile_picture/odstrelec_profile.png": true,
	"res://Card/Card_profile_picture/drak_profile.png": true,
	"res://Card/Card_profile_picture/saman_profile.png": true,
	"res://Card/Card_profile_picture/balista_profile.png": true,
	"res://Card/Card_profile_picture/trebuchet_profile.png": true,
	
	
	
	
	
	
	

	
	
	
	
	
	
}
 
var card_image_to_id = {
	"res://Card/Card_profile_picture/musketier_profile.png": "spawn_musketier",
	"res://Card/Card_profile_picture/jaskynny_muz_profile.png": "spawn_jaskynny_muz",
	"res://Card/Card_profile_picture/mamut_profile.png": "spawn_mamut",
	"res://Card/Card_profile_picture/vojnovy_voz_profile.png": "spawn_vojnovy_voz",
	"res://Card/Card_profile_picture/faraon_profile.png": "spawn_faraon",
	"res://Card/Card_profile_picture/gladiator_profile.png": "spawn_gladiator",
	"res://Card/Card_profile_picture/falkar_profile.png": "spawn_faklar",
	"res://Card/Card_profile_picture/jaskynny_strelec_profile.png": "spawn_jaskynny_strelec",
	"res://Card/Card_profile_picture/mnich_profile.png": "spawn_mnich",
	"res://Card/Card_profile_picture/lukostrelec.png": "spawn_lukostrelec",
	"res://Card/Card_profile_picture/inzinier_profile.png": "spawn_inzinier",
	"res://Card/Card_profile_picture/dynamiter_profile.png": "spawn_dynamiter",
	"res://Card/Card_profile_picture/lovec_profile.png": "spawn_lovec",
	"res://Card/Card_profile_picture/vojak_ww2_profile.png": "spawn_vojak_ww2",
	"res://Card/Card_profile_picture/bronzovy_vojak_profile.png": "spawn_bronzovy_vojak",
	"res://Card/Card_profile_picture/rytier_profile.png": "spawn_rytier",
	"res://Card/Card_profile_picture/panzer_profile.png": "spawn_panzer",
	"res://Card/Card_profile_picture/legionar_profile.png": "spawn_legionar",
	"res://Card/Card_profile_picture/saboter_profile.png": "spawn_saboter",
	"res://Card/Card_profile_picture/parny_tank_profile.png": "spawn_parny_tank",
	"res://Card/Card_profile_picture/odstrelec_profile.png": "spawn_odstrelec",
	"res://Card/Card_profile_picture/drak_profile.png": "spawn_drak",
	"res://Card/Card_profile_picture/saman_profile.png": "spawn_saman",
	"res://Card/Card_profile_picture/trebuchet_profile.png": "spawn_trebuchet",
	"res://Card/Card_profile_picture/balista_profile.png": "spawn_balistar",
	
	
	
	
	
	
	
	
	}
	

var save_path = "user://save.dat"
 
var card_costs = {
	"spawn_jaskynny_muz": 3, "spawn_lovec": 4, "spawn_saman": 6, "spawn_mamut": 8, "spawn_faklar": 7, "spawn_jaskynny_strekec": 4, 
	"spawn_bronzovy_vojak": 4, "spawn_vojnovy_voz": 7, "spawn_lukostrelec": 5, "spawn_faraon": 9,
	"spawn_legionar": 5, "spawn_balistar": 8, "spawn_gladiator": 6, "spawn_saboter": 7,
	"spawn_rytier": 6, "spawn_trebuchet": 9, "spawn_mnich": 5, "spawn_drak": 10,
	"spawn_musketier": 5, "spawn_parny_tank": 10, "spawn_inzinier": 7, "spawn_dynamiter": 6,
	"spawn_vojak_ww2": 4, "spawn_panzer": 10, "spawn_odstrelec": 7,
}


func _ready():
	# Ak je spustený ako druhá testovacia inštancia
	if "--second" in OS.get_cmdline_args():
		save_path = "user://save2.dat"
	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://hudba/freesound-community-button-press-85188_5Av4hk9z.mp3")  # tvoja cesta
	add_child(click_player)
	click_playerdva = AudioStreamPlayer.new()
	click_playerdva.stream = preload("res://hudba/levelup.mp3")  # tvoja cesta
	add_child(click_playerdva)
	
	load_game()
	
	if player_db_id == "":
		player_db_id = _generate_uuid()
		save_game()
 
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
 
# ================= SAVE =================
func save_game():
	var data = {
		"meno": username,
		"uuid": player_db_id,
		"trophies": trophies,
		"gold": gold,
		"deck": deck,
		"card_levels": card_levels,
		"card_counts": card_counts,
	}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
 
# ================= LOAD =================
func load_game():
	if not FileAccess.file_exists(save_path):
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return
	username = str(data.get("meno", ""))
	player_db_id = str(data.get("uuid", ""))
	trophies = int(data.get("trophies", 0))
	gold = data.get("gold", 0)
	deck = data.get("deck", ["", "", "", "", "", ""])
	card_levels = data.get("card_levels", {})
	card_counts = data.get("card_counts", {})
 
# ================= UUID GENERÁTOR =================
func _generate_uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var b := []
	for i in 16:
		b.append(rng.randi() % 256)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % b
	
	
# ================= inventar ===============
var owned_cards: Array = ["spawn_jaskynny_muz", "spawn_musketier"]  # default odomknuté

func owns_card(card_id: String) -> bool:
	return owned_cards.has(card_id)	
