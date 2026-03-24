extends Node2D



var tuknutetlacitko


func _on_button_2_pressed() -> void:
	tuknutetlacitko=$Button2


func _on_button_pressed() -> void:
	tuknutetlacitko=$Button


func _on_button_3_pressed() -> void:
	tuknutetlacitko=$Button3


func _on_button_4_pressed() -> void:
	tuknutetlacitko=$Button4


func _on_button_5_pressed() -> void:
	tuknutetlacitko=$Button5


func _on_button_6_pressed() -> void:
	tuknutetlacitko=$Button6


func _on_button_7_pressed() -> void:
	tuknutetlacitko=$Button7


func _on_button_8_pressed() -> void:
	tuknutetlacitko=$Button8


func _on_button_9_pressed() -> void:
	tuknutetlacitko=$Button9


func _on_button_10_pressed() -> void:
	tuknutetlacitko=$Button10
	
func _gui_input(event):
	if event is InputEventMouseButton :
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			for child in tuknutetlacitko.get_children():
				if child is TextureRect:
					child.texture = null
					for i in range(Global.deck.size()):
						if tuknutetlacitko == get_child(i):
								Global.deck[i] = ""
								Global.save_game()
								print("🗑️ Deck slot ", i, " vymazaný")
