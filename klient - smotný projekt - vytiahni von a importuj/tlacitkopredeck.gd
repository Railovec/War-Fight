extends Button

@onready var node_2d = $"../../../Node2D"
@onready var texture_rect = $TextureRect
@onready var texture_rect2 = $"../Button2/TextureRect"
@onready var texture_rect3 = $"../Button3/TextureRect"
@onready var texture_rect4 = $"../Button4/TextureRect"
@onready var texture_rect5 = $"../Button5/TextureRect"
@onready var texture_rect6 = $"../Button6/TextureRect"
@onready var texture_rect7 = $"../Button7/TextureRect"
@onready var texture_rect8 = $"../Button8/TextureRect"
@onready var texture_rect9= $"../Button9/TextureRect"
@onready var texture_rect10= $"../Button10/TextureRect"
@onready var texture_rect11= $"../Button11/TextureRect"
@onready var texture_rect12= $"../Button12/TextureRect"
@onready var texture_rect13= $"../Button13/TextureRect"
@onready var texture_rect14= $"../Button14/TextureRect"
@onready var texture_rect15= $"../Button15/TextureRect"
@onready var grid_container = $"../../GridContainer"

#zamykanie dam do globality pretoze ked budem hrat levly tam sa to ulozi...
var but
var e
var jeuz = false
var zz


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in grid_container.get_children():
		for x in i.get_children():
			if x.texture !=null:
				var card_id_r = Global.card_image_to_id.get(x.texture.get_path(), "")
				if not Global.owns_card(card_id_r):
					x.modulate = Color(0.4, 0.4, 0.4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass





#das im vlastne signaly tam urcis hodnoty napr c na obrazok textury co je v nom,bude to ako Pvz,ze budu pozamykane,
#cize chill,a bude ukavat vsetky ,ma mozes timer zemenit za dvojkklik je to v E scripte

func dvojklik():
	var a = 0
	jeuz=false
	for child in get_children():
		for bok in node_2d.get_children():
			for bok20 in bok.get_children():
				if but == 1:
					zz=  texture_rect.texture
				if but == 2:
					zz =  texture_rect2.texture
				if but == 3:
					zz =  texture_rect3.texture
				if but == 4:
					zz =  texture_rect4.texture
				if but == 5:
					zz =  texture_rect5.texture
				if but == 6:
					zz =  texture_rect6.texture
				if but == 7:
					zz =  texture_rect7.texture
				if but == 8:
					zz =  texture_rect8.texture
				if but == 9:
					zz =  texture_rect9.texture
				if but == 10:
					zz =  texture_rect10.texture
				if but == 11:
					zz =  texture_rect11.texture
				if but == 12:
					zz =  texture_rect12.texture
				if but == 13:
					zz = texture_rect13.texture
				if but == 14:
					zz = texture_rect14.texture
				if bok20.texture == zz:
					jeuz=true
				if bok20.texture != null:
					break
				var card_id_check = Global.card_image_to_id.get(zz.get_path(), "")
				if jeuz == false and a == 0 and Global.owns_card(card_id_check):
					bok20.texture = zz
					var slot_index = 0
					for i in range(node_2d.get_children().size()):
						var slot = node_2d.get_children()[i]
						for s in slot.get_children():
							if s == bok20:
								slot_index = i
					if zz != null:
						var image_path = zz.get_path()
						var card_id = Global.card_image_to_id.get(image_path, image_path)
						Global.deck[slot_index] = card_id
						Global.save_game()
						Supabase.save_deck(Global.player_db_id, Global.deck)
						print("💾 Deck slot ", slot_index, ": ", card_id)
				a = 1
				but =null


func _on_button_2_pressed():
	but = 2
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()
	


func _on_timer_timeout():
	e = false
	$"../../../Timer".stop()


func _on_pressed():
	but = 1
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()




func _on_button_3_pressed():
	but = 3
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_4_pressed():
	but = 4
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_5_pressed():
	but = 5
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_6_pressed():
	but = 6
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_7_pressed():
	but = 7
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_8_pressed():
	but = 8
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_9_pressed():
	but = 9
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()

func _on_button_10_pressed():
	but = 10
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_11_pressed():
	but = 11
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()


func _on_button_12_pressed():
	but = 12
	$"../../../Timer".stop()
	if e == true:
		dvojklik()
	e = true
	$"../../../Timer".start()

func _on_button_exit_pressed():
	get_tree().change_scene_to_file("res://menu/startovascena.tscn")
