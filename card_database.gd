extends Node

var cards := {}
var base_HP: int = 30

func _ready():
	register_cards()

func register_cards():
	# HP a DAMAGE sú zadané v battle_manager -> spawn_unit()
	
	var vojak = Card.new()
	vojak.id = "spawn_vojak"  #toto bude chodiť z klienta pre spawn
	vojak.cost = 6
	vojak.type = "spawn"
	vojak.unit_type = "vojak"
	vojak.speed = 1

	cards[vojak.id] = vojak
	
	var vojak_rychly = Card.new()
	vojak_rychly.id = "spawn_vojak_rychly" #toto bude chodiť z klienta pre spawn
	vojak_rychly.cost = 9
	vojak_rychly.type = "spawn"
	vojak_rychly.unit_type = "vojak_rychly"
	vojak_rychly.speed = 4
	
	cards[vojak_rychly.id] = vojak_rychly
	
	var velitel = Card.new()
	velitel.id = "spawn_velitel"
	velitel.cost = 8
	velitel.type = "spawn"
	velitel.unit_type = "velitel"
	velitel.speed = 0.5  # pomalý, support rola
	cards[velitel.id] = velitel
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
