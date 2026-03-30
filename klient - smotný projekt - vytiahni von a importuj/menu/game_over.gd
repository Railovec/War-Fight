extends CanvasLayer

var player_won: bool = false

func show_result(won: bool):
	player_won = won  # ← ulož lokálne
	visible = true
	if won:
		$VBoxContainer/ResultLabel.text = "VYHRAL SI! 🏆"
		$VBoxContainer/ResultLabel.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		$VBoxContainer/SubtitleLabel.text = "+30 trofejí"
		$ContinueButton.text = "Točiť koleso! 🎰"
	else:
		$VBoxContainer/ResultLabel.text = "PREHRAL SI! 💀"
		$VBoxContainer/ResultLabel.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		$VBoxContainer/SubtitleLabel.text = "-20 trofejí"
		$ContinueButton.text = "Späť do menu"

func _on_continue_button_pressed():
	Global.play_click()
	visible = false
	if player_won:
		var wheel = get_parent().get_node("CanvasLayer")
		wheel.show_wheel()
		await get_tree().create_timer(0.5).timeout
		wheel.spin()
