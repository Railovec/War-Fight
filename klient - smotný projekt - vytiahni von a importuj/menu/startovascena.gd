extends Node2D

@onready var gold_label = $VBoxContainer/GoldLabel
@onready var name_label = $VBoxContainer/NameLabel

func _ready() -> void:
	if Global.username == "":
		$LineEdit.show()
	else:
		_supabase_login()
	
	# Zobraz trofeje hneď pri načítaní
	$VBoxContainer/TrophyLabel.text = "🏆 " + str(Global.trophies)
	$VBoxContainer/GoldLabel.text = "💰 " + str(Global.gold)
	$VBoxContainer/NameLabel.text = "👤 " + Global.username


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://client/ClientScene.tscn")


func _on_upgrade_pressed() -> void:
	get_tree().change_scene_to_file("res://upgrade.tscn")


func _on_equip_pressed() -> void:
	get_tree().change_scene_to_file("res://scroll.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_line_edit_text_submitted(new_text: String) -> void:
	var name_input := new_text.strip_edges()
	if name_input.length() < 2:
		return

	Global.username = name_input
	$LineEdit.hide()
	_supabase_login()


func _supabase_login() -> void:
	if Global.username == "":
		$LineEdit.show()
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
