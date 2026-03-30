extends Node2D

@export var websocket_url := "ws://localhost:9080"

@onready var btn_vojak = get_node_or_null("vojak")
@onready var btn_rychly = get_node_or_null("rýchly vojak")

@onready var wheel_scene = $CanvasLayer

var socket := WebSocketPeer.new()
var last_snapshot: Dictionary = {}
var hrac: int = 1
var game_started := false
var opponent_name: String = ""
var opponent_trophies: int = 0
var supabase_updating := false
var match_requested := false
var player_label: Label
var opponent_label: Label
var unit_count_label: Label

var projectile_nodes: Dictionary = {}
var projectile_scene = preload("res://units/ProjectileNode.tscn")

# Sleduje živé unit nody: spawn_id -> Node2D
var unit_nodes: Dictionary = {}

# Preload unit scény
var unit_scene = preload("res://units/UnitNode.tscn")

func _ready():
	_build_deck_buttons()
	var heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 0.5
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(func():
		if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
			socket.send_text(JSON.stringify({"type": "ping"}))
	)
	add_child(heartbeat_timer)

	socket.set_no_delay(true)
	print("🚀 Štartujem klienta...")
	var err := socket.connect_to_url(websocket_url, TLSOptions.client_unsafe())
	if err != OK:
		print("❌ Chyba pripojenia")
		set_process(false)

	socket.inbound_buffer_size = 65536 * 2
	socket.outbound_buffer_size = 65536
	_create_player_labels()
	_create_mana_bar()


func _process(_delta):
	socket.poll()

	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not match_requested:
			match_requested = true
			client_ready()

		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			if socket.was_string_packet():
				_on_message(packet.get_string_from_utf8())

	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("⚠️ Spojenie prerušené. Kód: %d, Dôvod: %s" % [code, reason])
		if not supabase_updating:
			set_process(false)


func _on_message(text: String):
	var data = JSON.parse_string(text)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return

	var type = data.get("type", "")

	if type == "player_id":
		hrac = int(data.get("id", 1))
		opponent_name = data.get("opponent", "Súper")
		opponent_trophies = int(data.get("opponent_trophies", 0))
		var received_deck: Array = data.get("deck", [])
		if received_deck.size() > 0:
			Global.deck = received_deck
		
		if hrac == 1:
		# Hráč 1 má základňu vľavo
			player_label.position = Vector2(10, 10)
			opponent_label.position = Vector2(1050, 10)
		else:
		# Hráč 2 má základňu vpravo
			player_label.position = Vector2(1050, 10)
			opponent_label.position = Vector2(10, 10)
		player_label.text = "👤 " + Global.username
		opponent_label.text = "💀 " + opponent_name
		print("🎮 Som hráč: ", hrac, " | Súper: ", opponent_name, "| Deck: ", Global.deck)
		_build_deck_buttons()

	elif type == "waiting":
		print("⏳ Čakám na súpera...")

	elif type == "game_start":
		print("🚀 Hra začala!")
		game_started = true

	elif type == "snapshot":
		var snapshot_data = data.get("data", {})
		update_snapshot(snapshot_data)

	elif type == "game_over":
		var won: bool = data.get("won", false)
		Global.last_match_won = won
		Global.game_over_shown = true  # ← vždy true
		await Supabase.update_after_match(Global.player_db_id, won)
		get_tree().change_scene_to_file("res://menu/startovascena.tscn")
		set_process(false)


func update_snapshot(snapshot: Dictionary):
	last_snapshot = snapshot
	var units_data: Array = snapshot.get("units", [])
	#print("📦 Snapshot — počet jednotiek: ", units_data.size())
	for u in units_data:
		print("  unit: ", u)
	var alive_ids := {}

	for u in units_data:
		var id: int = u.get("id", 0)
		alive_ids[id] = true

		if not unit_nodes.has(id):
			_spawn_unit_node(id, u)
		else:
			unit_nodes[id].update_from_snapshot(u)

	# Zmaž nody jednotiek ktoré už nie sú v snapshote
	for id in unit_nodes.keys():
		if not alive_ids.has(id):
			_remove_unit_node(id)
	
	# Projektily
	var projectiles_data: Array = snapshot.get("projectiles", [])
	var alive_proj_ids := {}

	for p in projectiles_data:
		#print("🎯 Projektil data: ", p)
		var pid: int = int(p.get("id", 0))
		#print("PID: ", pid, " má node: ", projectile_nodes.has(pid), " keys: ", projectile_nodes.keys())
		alive_proj_ids[pid] = true
		if not projectile_nodes.has(pid):
			print("🚀 Spawnujem projektil ID: ", pid, " pos: ", p.get("pos", 0.0))
			var node = projectile_scene.instantiate()
			add_child(node)
			projectile_nodes[pid] = node
			node.setup(p)
		else:
			projectile_nodes[pid].update_position(p.get("pos", 0.0))

	for pid in projectile_nodes.keys():
		if not alive_proj_ids.has(pid):
			projectile_nodes[pid].queue_free()
			projectile_nodes.erase(pid)
	# print("🎯 Projektily v snapshote: ", projectiles_data.size())
	queue_redraw()
	var players_data = snapshot.get("players", {})
	var my_mana = players_data.get(str(hrac), {}).get("mana", 0)
	_update_mana_crystals(my_mana)
	var my_cooldowns = snapshot.get("card_cooldowns", {}).get(str(hrac), {})
	_update_card_cooldowns(my_cooldowns)
	
	var my_units = snapshot.get("units", []).filter(func(u): return int(u.get("owner", 0)) == hrac)
	var count = my_units.size()
	if unit_count_label:
		unit_count_label.text = "⚔️ %d/25" % count
		if count >= 20:
			unit_count_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # červená
		elif count >= 15:
			unit_count_label.add_theme_color_override("font_color", Color(1, 0.8, 0.0))  # žltá
		else:
			unit_count_label.add_theme_color_override("font_color", Color(1, 1, 1))  # biela

func _spawn_unit_node(id: int, unit_data: Dictionary):
	var node = unit_scene.instantiate()
	node.position = Vector2(unit_data.get("pos", 0.0), 400)
	add_child(node)
	unit_nodes[id] = node
	var utype = unit_data.get("unit_type", "jaskynny_muz")
	node.setup(utype)
	node.update_from_snapshot(unit_data)


func _remove_unit_node(id: int):
	if unit_nodes.has(id):
		var node = unit_nodes[id]
		unit_nodes.erase(id)
		node.play_death()


# _draw() len pre základne
func _draw():
	if last_snapshot.is_empty():
		return

	var players = last_snapshot.get("players", {})

	if players.has("base_hp_1"):
		var hp1 = players["base_hp_1"]
		draw_rect(Rect2(Vector2(150-40, 360), Vector2(40, 40)), Color.GREEN if hp1 > 0 else Color.RED)
		draw_string(ThemeDB.fallback_font, Vector2(110, 355), "HP: %d" % hp1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	if players.has("base_hp_2"):
		var hp2 = players["base_hp_2"]
		draw_rect(Rect2(Vector2(1002+20, 360), Vector2(40, 40)), Color.GREEN if hp2 > 0 else Color.RED)
		draw_string(ThemeDB.fallback_font, Vector2(1022, 355), "HP: %d" % hp2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


# --- OVLÁDANIE ---

func request_play_card(card_id: String):
	if not game_started:
		return
	if not Global.deck.has(card_id):
		print("❌ Karta nie je v decku: ", card_id)
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify({"type": "play_card", "card": card_id}))
		print("📤 Poslaná karta: ", card_id)


func client_ready():
	socket.send_text(JSON.stringify({
		"type": "find_match",
		"username": Global.username,
		"trophies": Global.trophies,
		"deck": Global.deck,
		"card_levels": Global.card_levels,
	}))
	print("📤 Hľadám súpera... Trofeje: ", Global.trophies, "Deck: ", Global.deck)

func _build_deck_buttons():
	var container = $DeckButtons
	container.add_theme_constant_override("separation", 10)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	for child in container.get_children():
		child.queue_free()
	
	for i in range(Global.deck.size()):
		var card_id = Global.deck[i]
		if card_id == "":
			continue
		
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(150, 150)
		wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wrapper.set_meta("card_id", card_id)
		
		# Obrázok
		var img_path = _get_card_image(card_id)
		if img_path != "":
			var tex = load(img_path)
			if tex:
				var tr = TextureRect.new()
				tr.texture = tex
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				wrapper.add_child(tr)
		
		# Cena — horný ľavý roh
		var cost = Global.card_costs.get(card_id, 0)
		var cost_label = Label.new()
		cost_label.text = str(cost)
		cost_label.position = Vector2(4, 4)
		cost_label.z_index = 1
		cost_label.add_theme_font_size_override("font_size", 13)
		cost_label.add_theme_color_override("font_color", Color(1, 1, 1))
		var cost_bg = StyleBoxFlat.new()
		cost_bg.bg_color = Color(0.1, 0.3, 0.9, 0.95)
		cost_bg.set_corner_radius_all(6)
		cost_bg.content_margin_left = 5
		cost_bg.content_margin_right = 5
		cost_bg.content_margin_top = 2
		cost_bg.content_margin_bottom = 2
		cost_label.add_theme_stylebox_override("normal", cost_bg)
		wrapper.add_child(cost_label)
		
		# Klik
		wrapper.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				request_play_card(card_id)
		)
		container.add_child(wrapper)

func _get_card_image(card_id: String) -> String:
	for img_path in Global.card_image_to_id.keys():
		if Global.card_image_to_id[img_path] == card_id:
			return img_path
	return ""
	
	
func _create_player_labels():
# --- PLAYER LABEL ---
	player_label = Label.new()
	player_label.position = Vector2(10, 10)
	player_label.add_theme_font_size_override("font_size", 20)
	player_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	
	# Vytvorenie pozadia pre hráča
	var player_bg = StyleBoxFlat.new()
	player_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8) # Tmavosivé farba s 80% viditeľnosťou
	
	# Pridanie vnútorného okraja (padding), aby text nebol nalepený na okraji pozadia
	player_bg.content_margin_left = 10
	player_bg.content_margin_right = 10
	player_bg.content_margin_top = 5
	player_bg.content_margin_bottom = 5
	player_bg.set_corner_radius_all(15)
	
	# Aplikovanie pozadia na stav "normal"
	player_label.add_theme_stylebox_override("normal", player_bg)
	add_child(player_label)
		
	# --- OPPONENT LABEL ---
	opponent_label = Label.new()
	opponent_label.position = Vector2(1050, 10)
	opponent_label.add_theme_font_size_override("font_size", 20)
	opponent_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	
	# Vytvorenie pozadia pre oponenta (môžeš použiť iné farby, ak chceš)
	var opponent_bg = StyleBoxFlat.new()
	opponent_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8) 
	opponent_bg.content_margin_left = 10
	opponent_bg.content_margin_right = 10
	opponent_bg.content_margin_top = 5
	opponent_bg.content_margin_bottom = 5
	opponent_bg.set_corner_radius_all(15)
	
	opponent_label.add_theme_stylebox_override("normal", opponent_bg)
	add_child(opponent_label)
	
var mana_crystals: Array = []
var current_mana: int = 0

func _create_mana_bar():
	var container = HBoxContainer.new()
	container.position = Vector2(350, 10)  # ← hore
	container.add_theme_constant_override("separation", 10)
	add_child(container)
	
	for i in range(10):
		var crystal = Panel.new()
		crystal.custom_minimum_size = Vector2(45, 50)
				
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.4, 0.8)
				# Hexagon tvar cez skosené rohy
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.skew = Vector2(0.3, 0.0)  # skosenie = hexagon efekt
		style.border_color = Color(0.4, 0.4, 0.8)
		style.set_border_width_all(2)
		crystal.add_theme_stylebox_override("panel", style)
				
		var label = Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.8))
		crystal.add_child(label)
				
		container.add_child(crystal)
		mana_crystals.append(crystal)
		
	unit_count_label = Label.new()
	unit_count_label.position = Vector2(900, 15)
	unit_count_label.add_theme_font_size_override("font_size", 16)
	unit_count_label.add_theme_color_override("font_color", Color(1, 1, 1))
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg.set_corner_radius_all(8)
	bg.content_margin_left = 8
	bg.content_margin_right = 8
	bg.content_margin_top = 3
	bg.content_margin_bottom = 3
	unit_count_label.add_theme_stylebox_override("normal", bg)
	add_child(unit_count_label)

func _update_mana_crystals(mana: int):


	current_mana = mana
	var mana_int = int(mana)
	
	for i in range(mana_crystals.size()):
		var crystal = mana_crystals[i]
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)

		if i < mana:
			style.bg_color = Color(0.3, 0.3, 1.0, 0.9)
			style.border_color = Color(0.6, 0.6, 1.0)
			style.skew = Vector2(0.3, 0.0)
			crystal.get_child(0).add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			style.bg_color = Color(0.2, 0.2, 0.4, 0.8)
			style.border_color = Color(0.4, 0.4, 0.8)
			style.skew = Vector2(0.3, 0.0)
			crystal.get_child(0).add_theme_color_override("font_color", Color(0.5, 0.5, 0.8))
		crystal.add_theme_stylebox_override("panel", style)

func _update_card_cooldowns(cooldowns: Dictionary):
	for wrapper in $DeckButtons.get_children():
		var card_id = wrapper.get_meta("card_id", "")
		var cd = cooldowns.get(card_id, 0.0)
		if cd > 0.0:
			wrapper.modulate = Color(0.5, 0.5, 0.5)
			var cd_label = wrapper.get_node_or_null("CooldownLabel")
			if cd_label == null:
				cd_label = Label.new()
				cd_label.name = "CooldownLabel"
				cd_label.position = Vector2(20, 25)
				cd_label.z_index = 2
				cd_label.add_theme_font_size_override("font_size", 14)
				cd_label.add_theme_color_override("font_color", Color(1, 1, 1))
				wrapper.add_child(cd_label)
			cd_label.text = "%.1fs" % cd
		else:
			wrapper.modulate = Color(1, 1, 1)
			var cd_label = wrapper.get_node_or_null("CooldownLabel")
			if cd_label:
				cd_label.queue_free()
