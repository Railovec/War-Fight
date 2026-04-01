extends Button


func _on_pressed() -> void:
	pass # Replace with function body.


func _gui_input(event):
	if event is InputEventMouseButton :

		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			Global.play_click()
			

			for child in self.get_children():
				if child is TextureRect:
					child.texture = null
					for i in range(Global.deck.size()):
						if self.get_child(0) == get_child(i):
							
								Global.deck[i] = ""
								Global.save_game()
								print("🗑️ Deck slot ", i, " vymazaný")
