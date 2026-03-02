extends Node


var units: Array = [] # všetky jednotky v hre
const TICK_RATE := 0.2 # ako často beží hra (sekundy)
const MANA_RATE := 1
const ATTACK_RANGE := 1.5


func _ready() -> void:
	var t := Timer.new()
	t.wait_time = 0.2
	t.autostart = true
	t.timeout.connect(tick)
	add_child(t)
	
	init_players()   
	start_tick_loop()
	start_mana_loop()
	
	# testy
	# await get_tree().create_timer(8.5).timeout
	# play_card(2, "spawn_vojak")
	# await get_tree().create_timer(2).timeout
	# play_card(1, "spawn_vojak_rychly")
	
	
	
func start_tick_loop():
	while true:
		await get_tree().create_timer(TICK_RATE).timeout
		tick()

func start_mana_loop():
	while true:
		await get_tree().create_timer(MANA_RATE).timeout
		regenerate_mana()
		for id in players.keys():
			print("Player ", id, " mana: ", players[id].mana)
		
func regenerate_mana():
	for p in players.values():
		p.mana = min(p.mana + 1, p.max_mana)

func tick():
	# print("TICK")

	move_units()
	handle_combat()
	cleanup_dead_units()
	check_base_hit()

	var snap = get_game_snapshot()
	# print("--- SNAPSHOT ---")
	print(snap)

	var client := get_tree().get_root().find_child("Client", true, false)
	if client:
		client.update_snapshot(snap)
	else:
		pass
		# print("❌ Client nenájdený")

func handle_combat():
	var units_copy = units.duplicate() # kópia pre bezpečný update

	for attacker in units_copy:
		var target = get_target(attacker)
		if target == null:
			continue
		
		if abs(attacker.position - target.position) <= ATTACK_RANGE:
			target.hp -= attacker.damage
			print("Unit ID:", attacker.spawn_id, " owner: ", attacker.owner_id, " útočí na: ", target.spawn_id, " owner: ", target.owner_id, " so silou: ", attacker.damage, " -> target HP: ", target.hp)


func get_target(attacker: Unit) -> Unit:
	var best_target: Unit = null
	var best_distance := INF

	for u in units:
		# ignoruj vlastných
		if u.owner_id == attacker.owner_id:
			continue

		var distance = abs(u.position - attacker.position)

		# vyber najbližšieho
		if distance < best_distance:
			best_distance = distance
			best_target = u

	return best_target

func cleanup_dead_units():
	units = units.filter(func(u): return u.is_alive())



func move_units():
	for u in units:
		var enemy = get_target(u)
		
		var destination: float
		if enemy != null:
			destination = enemy.position
		else:
			if u.owner_id == 1:
				destination = bases[2]
			else:
				destination = bases[1]

		if abs(u.position - destination) <= ATTACK_RANGE:
			continue

		# smer pohybu k cieľu
		if destination > u.position:
			u.position += u.speed
		else:
			u.position -= u.speed


func play_card(player_id: int, card_id: String):
	var card = get_node("../CardDatabase").cards.get(card_id)
	if card == null:
		print("Neznáma karta")
		return

	var player = players.get(player_id)
	if player == null:
		print("Neznámy hráč")
		return

	if player.mana < card.cost:
		print("Hráč ", player_id, " nemá dosť many")
		return

	# odčítaj manu
	player.mana -= card.cost

	if card.type == "spawn":
		spawn_unit(player_id, card)

	print("Hráč ", player_id, " zahral kartu ", card_id, " mana: ", player.mana)


var next_spawn_id: int = 1
func spawn_unit(owner_id: int, card):
	var u = Unit.new()
	u.owner_id = owner_id
	u.spawn_id = next_spawn_id
	next_spawn_id += 1

	if owner_id == 1:
		u.position = 150
	else:
		u.position = 1002

	u.speed = card.speed   

	if card.unit_type == "vojak":
		u.hp = 100
		u.damage = 10

	if card.unit_type == "vojak_rychly":
		u.hp = 60
		u.damage = 6

	units.append(u)
	print("Spawned: ", card.unit_type, " speed:", u.speed, " for player:", owner_id)




# func spawn_test_units():
#	for i in range(9):
#		var u = Unit.new()
#		u.spawn_id = i+1 							# 1. hp 50 
#		u.hp = 50 + i*10 							# 2. hp 60
#		u.damage = 5 + i*2 							# 1. hp 70
#		u.owner_id = 1 if i % 2 == 0 else 2 		# 2. hp 80
#		units.append(u)

var bases := {}
var players := {}
var bases_hp := {}
func init_players():
	players[1] = {
		"mana": 0,
		"max_mana": 10
	}
	players[2] = {
		"mana": 0,
		"max_mana": 10
	}
	bases[1] = 150      # Player 1 base na 0
	bases[2] = 1002    # Player 2 base na 100
	bases_hp[1] = 100
	bases_hp[2] = 100   


func check_base_hit():
	for u in units:
		if u.owner_id == 1 and u.position >= bases[2]-1: # karta stojí na 99 preto -1
			bases_hp[2] -= u.damage
			print("Player 1 unit ", u.spawn_id, " niči Player 2 base! GAMAGE: ", u.damage, " base HP: ", bases_hp[2])
		elif u.owner_id == 2 and u.position <= bases[1]+1: # karta stojí na 1 preto +1
			bases_hp[1] -= u.damage
			print("Player 2 unit", u.spawn_id, " ničil Player 1 base! GAMAGE: ", u.damage, " base HP: ", bases_hp[1])
			
		if bases_hp[1] <= 0:
			print_rich("[color=green]HRÁČ Č 2 VYHRAL [/color]")
		elif bases_hp[2] <= 0:
			print_rich("[color=green]HRÁČ Č 1 VYHRAL [/color]")


func get_game_snapshot() -> Dictionary:
	var snapshot := {
		"units": [],
		"players": {}
	}

	for u in units:
		snapshot["units"].append({
			"id": u.spawn_id,
			"owner": u.owner_id,
			"hp": u.hp,
			"pos": u.position,
			"speed": u.speed
		})

	for id in players.keys():
		snapshot["players"][id] = {
			"mana": players[id].mana,
			"max_mana": players[id].max_mana
		}

	for id in bases.keys():
		snapshot["players"]["base_hp_%d" % id] = bases_hp[id]

	return snapshot


func client_play_card(player_id: int, card_id: String):
	print("📥 CLIENT REQUEST:", player_id, card_id)
	play_card(player_id, card_id)
