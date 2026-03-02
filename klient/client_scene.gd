extends Node2D

var last_snapshot: Dictionary = {}  # tu uklada snapshot
@onready var server = get_tree().get_root().find_child("BattleManager", true, false)

func _ready():
	print("✅ Client ready")
	assert(server != null)


func _on_vojak_pressed():
	request_play_card("spawn_vojak")

func _on_rýchly_vojak_pressed():
	request_play_card("spawn_vojak_rychly")

func request_play_card(card_id: String):
	server.client_play_card(hrac, card_id)

func _process(delta: float) -> void:
	pass

# funkcia na prijatie snapshotu zo servera
func update_snapshot(snapshot: Dictionary):
	last_snapshot = snapshot
	var mana = snapshot["players"][1]["mana"]
	$"rýchly vojak".disabled = mana < 9
	$vojak.disabled = mana < 6
	
	queue_redraw()

func _draw():
	if last_snapshot.is_empty():
		return

	# kreslí jednotky
	for u in last_snapshot["units"]:
		var color = Color(1,0,0) if u["owner"]==1 else Color(0,0,1)
		# pozícia musí byť Vector2(x, y)
		var pos = Vector2(u["pos"], 400) # + u["owner"] * 20)  # Y offset, aby neboli na sebe, x5 aby sa pohyb videl
		draw_rect(Rect2(pos, Vector2(10,10)), color)

	# Voliteľne: môžeš kresliť base ako veľké rect
	for id in [1,2]:
		var base_hp = last_snapshot["players"]["base_hp_%d" % id]
		# napr. nakresliť na fixnú X pozíciu
		var base_pos = Vector2(150-20 if id==1 else 1002+20 , 390) # -+20 aby textury nechodili do seba
		draw_rect(Rect2(base_pos, Vector2(20,20)), Color(0,1,0))

var hrac: int = 1
func _on_check_button_toggled(toggled_on: bool):
	if toggled_on:
		hrac = 2
	else:
		hrac = 1
	
