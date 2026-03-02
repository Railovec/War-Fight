extends Node2D

@export var websocket_url := "ws://localhost:9080"

@onready var btn_vojak = get_node_or_null("vojak")
@onready var btn_rychly = get_node_or_null("rýchly vojak")

var socket := WebSocketPeer.new()
var last_snapshot: Dictionary = {}
var hrac: int = 1

func _ready():
	print("🚀 Štartujem klienta...")
	var err := socket.connect_to_url(websocket_url)
	if err != OK:
		print("❌ Chyba pripojenia na server")
		set_process(false)

func _process(_delta):
	socket.poll() # Dôležité: Aktualizuje stav socketu
	
	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		# KĽÚČOVÁ OPRAVA: Prečítame VŠETKY čakajúce správy v bufferi
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			if socket.was_string_packet():
				_on_message(packet.get_string_from_utf8())
	
	elif state == WebSocketPeer.STATE_CLOSED:
		print("⚠️ Spojenie so serverom sa prerušilo")
		set_process(false)

func _on_message(text: String):
	# Tu spracujeme JSON zo servera
	var data = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return

	# Reagujeme na snapshot (tu sa deje pohyb)
	if data.get("type") == "snapshot":
		var snapshot_data = data.get("data", {})
		update_snapshot(snapshot_data)

func update_snapshot(snapshot: Dictionary):
	last_snapshot = snapshot
	
	# Aktualizácia UI (mana) - podľa tvojho formátu, kde kľúče sú čísla
	var players = snapshot.get("players", {})
	
	# Skúsime nájsť dáta nášho hráča (ošetrené pre int aj string kľúče)
	var my_data = players.get(hrac, players.get(str(hrac), {}))
	
	if not my_data.is_empty():
		var mana = my_data.get("mana", 0)
		if btn_rychly: btn_rychly.disabled = (mana < 9)
		if btn_vojak: btn_vojak.disabled = (mana < 6)

	# VYNÚTIME prekreslenie (zavolá _draw)
	queue_redraw()

func _draw():
	if last_snapshot.is_empty():
		return

	# --- VYKRESLENIE JEDNOTIEK ---
	var units = last_snapshot.get("units", [])
	for u in units:
		var owner = u.get("owner", 0)
		var pos_x = u.get("pos", 0)
		
		# Farba podľa hráča
		var color = Color.RED if str(owner) == "1" else Color.BLUE
		
		# Vykreslenie (Y je nastavené na 400, pos_x berieme zo servera)
		draw_rect(Rect2(Vector2(pos_x, 400), Vector2(20, 20)), color)

	# --- VYKRESLENIE ZÁKLADNÍ ---
	var players = last_snapshot.get("players", {})
	
	# Základňa 1 (vľavo)
	if players.has("base_hp_1"):
		var hp1 = players["base_hp_1"]
		draw_rect(Rect2(Vector2(20, 380), Vector2(40, 40)), Color.GREEN if hp1 > 0 else Color.RED)
		
	# Základňa 2 (vpravo)
	if players.has("base_hp_2"):
		var hp2 = players["base_hp_2"]
		draw_rect(Rect2(Vector2(1100, 380), Vector2(40, 40)), Color.GREEN if hp2 > 0 else Color.RED)

# --- OVLÁDANIE (Tlačidlá) ---

func request_play_card(card_id: String):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var msg := {
			"type": "play_card",
			"player": hrac,
			"card": card_id
		}
		socket.send_text(JSON.stringify(msg))
		print("📤 Poslaná karta: ", card_id)

func _on_vojak_pressed():
	request_play_card("spawn_vojak")

func _on_rýchly_vojak_pressed():
	request_play_card("spawn_vojak_rychly")

func _on_check_button_toggled(toggled_on: bool):
	hrac = 2 if toggled_on else 1
	print("👤 Prepnutý na hráča: ", hrac)	
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
##STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#STARÝ KÓD (ŚURADNICE Z NEHO TREBA VYBRAŤ)
#
#
#
#
#
#
#extends Node2D
#
#@export var websocket_url := "ws://localhost:9080"
#
#var socket := WebSocketPeer.new()
#var last_snapshot: Dictionary = {}
#var hrac: int = 1
#
#
#func _ready():
	#print("✅ Client ready")
#
	#var err := socket.connect_to_url(websocket_url)
	#if err != OK:
		#push_error("❌ Neviem sa pripojiť na server")
		#set_process(false)
	#else:
		#print("🔌 Pripájam sa na server...")
#
#
#func _process(_delta):
	#socket.poll()
#
	#var state := socket.get_ready_state()
#
	#if state == WebSocketPeer.STATE_OPEN:
		#while socket.get_available_packet_count() > 0:
			#var packet := socket.get_packet()
			#if socket.was_string_packet():
				#_on_message(packet.get_string_from_utf8())
#
	#elif state == WebSocketPeer.STATE_CLOSED:
		#print("❌ Spojenie so serverom padlo")
		#set_process(false)
#
#
#func _on_message(text: String):
	#var msg := JSON.parse_string(text)
	#if msg == null:
		#return
#
	#if msg.has("type") and msg["type"] == "snapshot":
		#update_snapshot(msg["data"])
#
#
## ======================
## UI → SERVER
## ======================
#
#func _on_vojak_pressed():
	#request_play_card("spawn_vojak")
#
#func _on_rýchly_vojak_pressed():
	#request_play_card("spawn_vojak_rychly")
#
#
#func request_play_card(card_id: String):
	#if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		#return
#
	#var msg := {
		#"type": "play_card",
		#"player": hrac,
		#"card": card_id
	#}
#
	#socket.send_text(JSON.stringify(msg))
#
#
## ======================
## SERVER → CLIENT
## ======================
#
#func update_snapshot(snapshot: Dictionary):
	#last_snapshot = snapshot
#
	#if not snapshot.has("players"):
		#return
#
	#var mana := snapshot["players"][hrac]["mana"]
	#$"rýchly vojak".disabled = mana < 9
	#$vojak.disabled = mana < 6
#
	#queue_redraw()
#
#
## ======================
## DRAW
## ======================
#
#func _draw():
	#if last_snapshot.is_empty():
		#return
#
	## jednotky
	#for u in last_snapshot["units"]:
		#var color := Color.RED if u["owner"] == 1 else Color.BLUE
		#var pos := Vector2(u["pos"], 400)
		#draw_rect(Rect2(pos, Vector2(10, 10)), color)
#
	## bases
	#for id in [1, 2]:
		#var base_hp := last_snapshot["players"]["base_hp_%d" % id]
		#var base_pos := Vector2(150 - 20 if id == 1 else 1002 + 20, 390)
		#draw_rect(Rect2(base_pos, Vector2(20, 20)), Color.GREEN)
#
#
## ======================
## PLAYER SWITCH
## ======================
#
#func _on_check_button_toggled(toggled_on: bool):
	#hrac = 2 if toggled_on else 1
