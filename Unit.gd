extends Node

class_name Unit

var hp: int # v battle_managers
var damage: int # v battle_managers
var owner_id: int
var spawn_id: int
var position: float = 0
var speed: float 
var attack_speed: float = 1.0   # sekundy medzi útokmi
var attack_cooldown: float = 0.0 
var is_support: bool = false
var attack_speed_buff: float = 0.0
var base_attack_speed: float = 1.0  # uložená pôvodná hodnota


func is_alive() -> bool:
	return hp > 0
