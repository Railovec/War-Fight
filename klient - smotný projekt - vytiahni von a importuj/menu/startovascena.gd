extends Node2D


func _ready() -> void:

	if Global.meno==null:
		$LineEdit.show()

		

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ClientScene.tscn")


func _on_upgrade_pressed() -> void:
	get_tree().change_scene_to_file("res://ClientScene.tscn")


func _on_equip_pressed() -> void:
	get_tree().change_scene_to_file("res://ClientScene.tscn")


func _on_quit_pressed() -> void:
	pass # Replace with function body.


func _on_line_edit_text_submitted(new_text: String) -> void:
	Global.meno=$LineEdit.text
	$LineEdit.hide()
