extends Node2D


func _ready() -> void:
	if Global.username == "":
		$LineEdit.show()
	else:
		_supabase_login()
	
	# Zobraz trofeje hneď pri načítaní
	$TrophyLabel.text = "🏆 " + str(Global.trophies)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://client/ClientScene.tscn")


func _on_upgrade_pressed() -> void:
	get_tree().change_scene_to_file("res://client/ClientScene.tscn")


func _on_equip_pressed() -> void:
	get_tree().change_scene_to_file("res://client/ClientScene.tscn")


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
	Global.save_game()
	
	# Aktualizuj label po načítaní zo Supabase
	$TrophyLabel.text = "🏆 " + str(Global.trophies)
	print("✅ Prihlásený: ", Global.username, " | Trofeje: ", Global.trophies)
