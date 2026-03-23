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
 
# ci je postava odomknuta
var postavy = {
	"res://nesmej sa/bul/pistol(SILENT STRIKER.png": false,
}
 
var save_path = "user://save.dat"
 
func _ready():
	# Ak je spustený ako druhá testovacia inštancia
	if "--second" in OS.get_cmdline_args():
		save_path = "user://save2.dat"
	
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
