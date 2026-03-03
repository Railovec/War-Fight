extends Node

const PORT := 9080

var tcp_server := TCPServer.new()
var peers: Dictionary = {}
var next_peer_id := 1

@onready var battle := $BattleManager


func _ready():
	var err := tcp_server.listen(PORT)
	if err != OK:
		push_error("❌ Server sa nepodarilo spustiť")
		set_process(false)
	else:
		print("✅ SERVER BEŽÍ NA PORTE", PORT)
	
	# Pridaj toto do _ready() v serverovom scripte
	var broadcast_timer := Timer.new()
	broadcast_timer.wait_time = 0.2 # Rovnaký čas ako TICK_RATE
	broadcast_timer.autostart = true
	broadcast_timer.timeout.connect(broadcast_snapshot)
	add_child(broadcast_timer)


func _process(_delta):
	# nové pripojenia
	while tcp_server.is_connection_available():
		var ws := WebSocketPeer.new()
		ws.accept_stream(tcp_server.take_connection())

		var peer_id := next_peer_id
		next_peer_id += 1

		peers[peer_id] = ws
		print("🟢 Client pripojený:", peer_id)

		send_snapshot(peer_id)

	# spracovanie klientov
	for peer_id in peers.keys():
		var peer: WebSocketPeer = peers[peer_id]
		peer.poll()

		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var packet := peer.get_packet()
				if peer.was_string_packet():
					_handle_packet(peer_id, packet.get_string_from_utf8())

		elif peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			print("🔴 Client odpojený:", peer_id)
			peers.erase(peer_id)


func _handle_packet(peer_id: int, text: String):
	var msg = JSON.parse_string(text)
	if msg == null:
		return

	if msg.get("type") == "play_card":
		battle.client_play_card(msg["player"], msg["card"])
		broadcast_snapshot()


func send_snapshot(peer_id: int):
	if not peers.has(peer_id):
		return

	var data := {
		"type": "snapshot",
		"data": battle.get_game_snapshot()
	}

	peers[peer_id].send_text(JSON.stringify(data))


func broadcast_snapshot():
	for id in peers.keys():
		send_snapshot(id)
