extends Node

var xp=0
var coins=0
var damage_level=1
var xp_mnozstvo_level=1
var coiny_mnozstvo_level=1
var energy_level=1
var peniaze_level=5
var max_peniaze_level=1
var zivoty_level=1

var meno

# ci je potava odomknuta
var postavy = {
	"res://nesmej sa/bul/pistol(SILENT STRIKER.png":false,
	}

var save_path = "user://save.dat"


func _ready():
	load_game()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# ================= SAVE =================

func save_game():
	var data = {
		"meno": meno,
	}

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


# ================= LOAD =================

func load_game():
	if not FileAccess.file_exists(save_path):
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if data == null:
		return

	meno= data["meno"]
