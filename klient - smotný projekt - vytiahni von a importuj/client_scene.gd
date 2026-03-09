extends Node2D

@export var websocket_url := "ws://localhost:9080"

@onready var btn_vojak = get_node_or_null("vojak")
@onready var btn_rychly = get_node_or_null("rýchly vojak")

var socket := WebSocketPeer.new()
var last_snapshot: Dictionary = {}
var hrac: int = 1

func _ready():
	var heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 0.5 # Každú pol sekundu pošle "ping"
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(func():
		if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			socket.send_text(JSON.stringify({"type": "ping"}))
	)
	add_child(heartbeat_timer)
	socket.set_no_delay(true)
	print("🚀 Štartujem klienta...")
	var err := socket.connect_to_url(websocket_url)
	if err != OK:
		print("❌ Chyba pripojenia na server")
		set_process(false)
		
	var refresh_timer = Timer.new()
	refresh_timer.wait_time = 0.1
	refresh_timer.autostart = true
	refresh_timer.timeout.connect(func(): queue_redraw())
	add_child(refresh_timer)
	socket.inbound_buffer_size = 65536 * 2
	socket.outbound_buffer_size = 65536

func _process(_delta):
	socket.poll()
	# DOPLNENÝ RIADOK: Force-flush alebo overenie stavu
	if socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING or socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		# Tento príkaz prinúti engine skontrolovať buffer
		var _unused = socket.get_available_packet_count()

	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		var has_new_data = false
		
		# Spracujeme VŠETKY čakajúce správy v tomto snímku
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			if socket.was_string_packet():
				_on_message(packet.get_string_from_utf8())
				has_new_data = true
		
		# Ak prišli akékoľvek nové dáta, okamžite prekreslíme obrazovku
		if has_new_data:
			queue_redraw()
	
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("⚠️ Spojenie prerušené. Kód: %d, Dôvod: %s" % [code, reason])
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
		# if btn_rychly: btn_rychly.disabled = (mana < 9)
		# if btn_vojak: btn_vojak.disabled = (mana < 6)
		
		
	print("Nové dáta prijaté! Počet jednotiek: ", snapshot.get("units", []).size())
	last_snapshot = snapshot
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
		var color = Color.BLUE if int(owner) == 1 else Color.RED
		
		# Vykreslenie (Y je nastavené na 400, pos_x berieme zo servera)
		draw_rect(Rect2(Vector2(pos_x, 400), Vector2(20, 20)), color)

	# --- VYKRESLENIE ZÁKLADNÍ ---
	var players = last_snapshot.get("players", {})
	
	# Základňa 1 (vľavo)
	if players.has("base_hp_1"):
		var hp1 = players["base_hp_1"]
		draw_rect(Rect2(Vector2(150-40, 380), Vector2(40, 40)), Color.GREEN if hp1 > 0 else Color.RED) #150 pride zo servera a -40 je veľkostť campu
		
	# Základňa 2 (vpravo)
	if players.has("base_hp_2"):
		var hp2 = players["base_hp_2"]
		draw_rect(Rect2(Vector2(1002+20, 380), Vector2(40, 40)), Color.GREEN if hp2 > 0 else Color.RED) #1002 pride zo servera a +20 je veľkostť campu -> tak to centruje nwm prečo...

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
