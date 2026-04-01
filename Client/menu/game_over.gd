extends CanvasLayer

var player_won: bool = false

func show_result(won: bool):
	player_won = won  # ← ulož lokálne
	visible = true
	if won:
		$HBoxContainer/VBoxContainer/ResultLabel.text = "VYHRAL SI! 🏆"
		$HBoxContainer/VBoxContainer/ResultLabel.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		$HBoxContainer/VBoxContainer/SubtitleLabel.text = "+30 trofejí"
		$ContinueButton/Label.text = "Točiť koleso! 🎰"
	else:
		$HBoxContainer/VBoxContainer/ResultLabel.text = "PREHRAL SI! 💀"
		$HBoxContainer/VBoxContainer/ResultLabel.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		$HBoxContainer/VBoxContainer/SubtitleLabel.text = "-20 trofejí"
		$ContinueButton/Label.text = "Späť do menu"

func _on_continue_button_pressed():
	Global.music_player.play()
	Global.play_click()
	visible = false
	if player_won:
		var wheel = get_parent().get_node("CanvasLayer")
		wheel.show_wheel()
		await get_tree().create_timer(0.5).timeout
		wheel.spin()
