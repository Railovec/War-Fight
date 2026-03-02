extends Node2D

@export var websocket_url := "ws://localhost:9080"

var socket := WebSocketPeer.new()
var last_snapshot: Dictionary = {}
var hrac: int = 1


func _ready():
	print("✅ Client ready")

	var err := socket.connect_to_url(websocket_url)
	if err != OK:
		push_error("❌ Neviem sa pripojiť na server")
		set_process(false)
	else:
		print("🔌 Pripájam sa na server...")


func _process(_delta):
	socket.poll()

	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			if socket.was_string_packet():
				_on_message(packet.get_string_from_utf8())

	elif state == WebSocketPeer.STATE_CLOSED:
		print("❌ Spojenie so serverom padlo")
		set_process(false)


func _on_message(text: String):
	var msg = JSON.parse_string(text)
	if msg == null:
		return

	if msg.has("type") and msg["type"] == "snapshot":
		update_snapshot(msg["data"])


# ======================
# UI → SERVER
# ======================

func _on_vojak_pressed():
	request_play_card("spawn_vojak")

func _on_rýchly_vojak_pressed():
	request_play_card("spawn_vojak_rychly")


func request_play_card(card_id: String):
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	var msg := {
		"type": "play_card",
		"player": hrac,
		"card": card_id
	}

	socket.send_text(JSON.stringify(msg))


# ======================
# SERVER → CLIENT
# ======================

func update_snapshot(snapshot: Dictionary):
	last_snapshot = snapshot

	if not snapshot.has("players"):
		return

	var mana = snapshot["players"][hrac]["mana"]
	$"rýchly vojak".disabled = mana < 9
	$vojak.disabled = mana < 6

	queue_redraw()


# ======================
# DRAW
# ======================

func _draw():
	if last_snapshot.is_empty():
		return

	# jednotky
	for u in last_snapshot["units"]:
		var color := Color.RED if u["owner"] == 1 else Color.BLUE
		var pos := Vector2(u["pos"], 400)
		draw_rect(Rect2(pos, Vector2(10, 10)), color)

	# bases
	for id in [1, 2]:
		var base_hp = last_snapshot["players"]["base_hp_%d" % id]
		var base_pos := Vector2(150 - 20 if id == 1 else 1002 + 20, 390)
		draw_rect(Rect2(base_pos, Vector2(20, 20)), Color.GREEN)


# ======================
# PLAYER SWITCH
# ======================

func _on_check_button_toggled(toggled_on: bool):
	hrac = 2 if toggled_on else 1
