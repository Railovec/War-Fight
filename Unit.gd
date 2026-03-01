extends Node

class_name Unit

var hp: int # v battle_managers
var damage: int # v battle_managers
var owner_id: int
var spawn_id: int

var position: float = 0
var speed: float 

func is_alive() -> bool:
	return hp > 0
