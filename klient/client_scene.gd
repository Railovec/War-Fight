extends Node2D

var last_snapshot: Dictionary = {}  # tu uklada snapshot

func _ready() -> void:
	print("✅ Client ready")
	pass

func _process(delta: float) -> void:
	pass

# funkcia na prijatie snapshotu zo servera
func update_snapshot(snapshot: Dictionary):
	last_snapshot = snapshot
	queue_redraw()

func _draw():
	if last_snapshot.is_empty():
		return

	# kreslí jednotky
	for u in last_snapshot["units"]:
		var color = Color(1,0,0) if u["owner"]==1 else Color(0,0,1)
		# pozícia musí byť Vector2(x, y)
		var pos = Vector2(u["pos"], 50 + u["owner"] * 20)  # Y offset, aby neboli na sebe, x5 aby sa pohyb videl
		draw_rect(Rect2(pos, Vector2(10,10)), color)

	# Voliteľne: môžeš kresliť base ako veľké rect
	for id in [1,2]:
		var base_hp = last_snapshot["players"]["base_hp_%d" % id]
		# napr. nakresliť na fixnú X pozíciu
		var base_pos = Vector2(0 if id==1 else 100, 50 + id*20)
		draw_rect(Rect2(base_pos, Vector2(20,20)), Color(0,1,0))
