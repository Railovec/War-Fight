extends Node2D

@onready var gold_label = $VBoxContainer/GoldLabel
@onready var name_label = $VBoxContainer/NameLabel
@onready var wheel_scene = $CanvasLayer
@onready var game_over_scene = $Control

@onready var arena_vbox = $ScrollContainer/ArenaVbox

const ARENAS = [
	{"name": "Kamenná doba", "min": 0, "max": 299,
	 "cards": ["spawn_jaskynny_muz", "spawn_lovec", "spawn_saman", "spawn_mamut", "spawn_faklar", "spawn_jaskynny_strelec"],
	 "color": Color(0.8, 0.6, 0.3)},
	{"name": "Bronzová doba", "min": 300, "max": 599,
	 "cards": ["spawn_bronzovy_vojak", "spawn_vojnovy_voz", "spawn_lukostrelec", "spawn_faraon"],
	 "color": Color(0.7, 0.5, 0.2)},
	{"name": "Železná doba", "min": 600, "max": 999,
	 "cards": ["spawn_legionar", "spawn_balistar", "spawn_gladiator", "spawn_saboter"],
	 "color": Color(0.6, 0.6, 0.7)},
	{"name": "Stredovek", "min": 1000, "max": 1499,
	 "cards": ["spawn_rytier", "spawn_trebuchet", "spawn_mnich", "spawn_drak"],
	 "color": Color(0.5, 0.4, 0.6)},
	{"name": "Priemyselná doba", "min": 1500, "max": 1999,
	 "cards": ["spawn_musketier", "spawn_parny_tank", "spawn_inzinier", "spawn_dynamiter"],
	 "color": Color(0.4, 0.5, 0.6)},
	{"name": "WW2", "min": 2000, "max": 9999,
	 "cards": ["spawn_vojak_ww2", "spawn_panzer", "spawn_odstrelec"],
	 "color": Color(0.5, 0.4, 0.3)},
]


func _ready() -> void:
	game_over_scene.visible = false
	if Global.username == "":
		$TextureRect2.show()
	else:
		_supabase_login()
	
	# Zobraz trofeje hneď pri načítaní
	$VBoxContainer/TrophyLabel.text = "🏆 " + str(Global.trophies)
	$VBoxContainer/GoldLabel.text = "💰 " + str(Global.gold)
	$VBoxContainer/NameLabel.text = "👤 " + Global.username
	if Global.game_over_shown:
		Global.game_over_shown = false
		if Global.last_match_won:
			Global.last_match_won = false
			game_over_scene.show_result(true)
		else:
			game_over_scene.show_result(false)
		
	_build_arena_road()



func _on_button_pressed() -> void:
	Global.play_click()
	get_tree().change_scene_to_file("res://client/ClientScene.tscn")

	

func _on_upgrade_pressed() -> void:
	Global.play_click()
	get_tree().change_scene_to_file("res://upgrade.tscn")

	

func _on_equip_pressed() -> void:
	Global.play_click()
	get_tree().change_scene_to_file("res://scroll.tscn")

	

func _on_quit_pressed() -> void:
	Global.play_click()
	get_tree().quit()

	

func _on_line_edit_text_submitted(new_text: String) -> void:
	var name_input := new_text.strip_edges()
	if name_input.length() < 2:
		return

	Global.username = name_input
	$TextureRect2.hide()
	_supabase_login()


func _supabase_login() -> void:
	if Global.username == "":
		$TextureRect2.show()
		return

	var player_data = await Supabase.login(Global.player_db_id, Global.username)

	if player_data.is_empty():
		print("❌ Chyba pri prihlasovaní")
		return

	Global.trophies = player_data.get("trophies", 100)
	Global.gold = int(player_data.get("gold", 0))
	
	var saved_deck = player_data.get("deck", [])
	if saved_deck.size() == 6:
		Global.deck = saved_deck
	
	# Načítaj karty — len raz
	var player_cards = await Supabase.get_player_cards(Global.player_db_id)
	Global.owned_cards = []
	Global.card_counts = {}
	Global.card_levels = {}
	for pc in player_cards:
		var cid = pc.get("card_id", "")
		Global.owned_cards.append(cid)
		Global.card_counts[cid] = int(pc.get("count", 1))
		Global.card_levels[cid] = int(pc.get("level", 1))
	
	Global.save_game()
	$VBoxContainer/TrophyLabel.text = "🏆 " + str(Global.trophies)
	print("✅ Prihlásený: ", Global.username, " | Trofeje: ", Global.trophies)


func _build_arena_road():
	for child in arena_vbox.get_children():
		child.queue_free()
	
	var trophies = Global.trophies
	
	for i in range(ARENAS.size() - 1, -1, -1):
		var arena = ARENAS[i]
		var is_current = trophies >= arena.min and trophies <= arena.max
		var is_unlocked = trophies >= arena.min
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 100)
		
		var style = StyleBoxFlat.new()
		if is_current:
			style.bg_color = Color(arena.color.r, arena.color.g, arena.color.b, 0.9)
			style.border_color = Color(1, 1, 0)
			style.set_border_width_all(3)
		elif is_unlocked:
			style.bg_color = Color(arena.color.r, arena.color.g, arena.color.b, 0.5)
		else:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		panel.add_child(hbox)
		
		# Ľavá časť — info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = ("🔒 " if not is_unlocked else "⚔️ ") + arena.name
		name_label.add_theme_font_size_override("font_size", 16)
		if is_current:
			name_label.add_theme_color_override("font_color", Color(1, 1, 0))
		elif not is_unlocked:
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info_vbox.add_child(name_label)
		
		var trophy_label = Label.new()
		trophy_label.text = "🏆 %d - %d" % [arena.min, arena.max] if arena.max < 9999 else "🏆 %d+" % arena.min
		trophy_label.add_theme_font_size_override("font_size", 12)
		trophy_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		info_vbox.add_child(trophy_label)
		
		if is_current:
			var bar = ProgressBar.new()
			bar.min_value = arena.min
			bar.max_value = arena.max
			bar.value = trophies
			bar.custom_minimum_size = Vector2(0, 12)
			bar.show_percentage = false
			info_vbox.add_child(bar)
		
		# Pravá časť — karty
		var cards_hbox = HBoxContainer.new()
		hbox.add_child(cards_hbox)
		
		for card_id in arena.cards:
			var img_path = _get_card_image(card_id)
			if img_path != "":
				var tex = load(img_path)
				if tex:
					var tr = TextureRect.new()
					tr.texture = tex
					tr.custom_minimum_size = Vector2(100, 100)
					tr.size = Vector2(100, 100)
					tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					if not is_unlocked:
						tr.modulate = Color(0.3, 0.3, 0.3)
					cards_hbox.add_child(tr)
		
		arena_vbox.add_child(panel)
		
		if i > 0:
			var sep = Label.new()
			sep.text = "▲"
			sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sep.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			arena_vbox.add_child(sep)
	await get_tree().process_frame  # počkaj kým sa vykreslí
	$ScrollContainer.scroll_vertical = $ScrollContainer.get_v_scroll_bar().max_value

func _get_card_image(card_id: String) -> String:
	for img_path in Global.card_image_to_id.keys():
		if Global.card_image_to_id[img_path] == card_id:
			return img_path
	return ""
