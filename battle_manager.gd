extends Node


var units: Array = []
const TICK_RATE := 0.2
const MANA_RATE := 1
const ATTACK_RANGE := 1.5
var game_started := false


func _ready() -> void:
	# ✅ Len jeden timer — odstránený duplicitný start_tick_loop()
	var t := Timer.new()
	t.wait_time = TICK_RATE
	t.autostart = true
	t.timeout.connect(tick)
	add_child(t)

	init_players()
	start_mana_loop()


func start_mana_loop():
	while true:
		await get_tree().create_timer(MANA_RATE).timeout

		if not game_started:
			continue

		regenerate_mana()
		for id in players.keys():
			print("Player ", id, " mana: ", players[id].mana)


func regenerate_mana():
	for p in players.values():
		p.mana = min(p.mana + 1, p.max_mana)


func tick():
	if not game_started:
		return
	apply_buffs()         # ✅ Vždy ako prvé
	move_units()
	handle_combat()
	cleanup_dead_units()
	check_base_hit()

	var snap = get_game_snapshot()
	print(snap)

	var client := get_tree().get_root().find_child("Client", true, false)
	if client:
		client.update_snapshot(snap)


func apply_buffs():
	# Reset všetkých jednotiek na ich base hodnoty
	for u in units:
		u.attack_speed = u.base_attack_speed

	# Aplikuj buffy od živých support jednotiek
	for buffer in units:
		if not buffer.is_support:
			continue
		# ✅ Opravené odsadenie — tento loop teraz skutočne beží
		for u in units:
			if u.owner_id == buffer.owner_id and u != buffer:
				u.attack_speed = u.attack_speed * (1.0 - buffer.attack_speed_buff)


func handle_combat():
	for attacker in units:

		attacker.attack_cooldown = max(0, attacker.attack_cooldown - TICK_RATE)

		var target = get_target(attacker)
		if target == null:
			continue

		if abs(attacker.position - target.position) <= ATTACK_RANGE:

			if attacker.attack_cooldown > 0:
				continue

			target.hp -= attacker.damage
			attacker.attack_cooldown = attacker.attack_speed
			print("Unit ID:", attacker.spawn_id, " owner: ", attacker.owner_id, " útočí na: ", target.spawn_id, " owner: ", target.owner_id, " so silou: ", attacker.damage, " -> target HP: ", target.hp)


func get_target(attacker: Unit) -> Unit:
	var best_target: Unit = null
	var best_distance := INF

	for u in units:
		if u.owner_id == attacker.owner_id:
			continue

		var distance = abs(u.position - attacker.position)

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
		u.attack_speed = 1.0

	if card.unit_type == "vojak_rychly":
		u.hp = 100
		u.damage = 5
		u.attack_speed = 0.5

	if card.unit_type == "velitel":
		u.hp = 80
		u.damage = 3
		u.attack_speed = 1.5
		u.is_support = true
		u.attack_speed_buff = 0.4

	# ✅ Vždy uložiť base_attack_speed — pre všetky typy jednotiek
	u.base_attack_speed = u.attack_speed

	units.append(u)
	print("Spawned: ", card.unit_type, " speed:", u.speed, " for player:", owner_id)


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
	bases[1] = 150
	bases[2] = 1002
	bases_hp[1] = 100
	bases_hp[2] = 100


func check_base_hit():
	for u in units:
		if u.owner_id == 1 and u.position >= bases[2] - 1:
			bases_hp[2] -= u.damage
			print("Player 1 unit ", u.spawn_id, " niči Player 2 base! DAMAGE: ", u.damage, " base HP: ", bases_hp[2])
		elif u.owner_id == 2 and u.position <= bases[1] + 1:
			bases_hp[1] -= u.damage
			print("Player 2 unit ", u.spawn_id, " ničí Player 1 base! DAMAGE: ", u.damage, " base HP: ", bases_hp[1])

	if bases_hp[1] <= 0 and game_started:
		print_rich("[color=green]HRÁČ Č 2 VYHRAL[/color]")
		game_started = false
		await get_tree().create_timer(TICK_RATE).timeout
		get_parent().game_over(2)

	elif bases_hp[2] <= 0 and game_started:
		print_rich("[color=green]HRÁČ Č 1 VYHRAL[/color]")
		game_started = false
		await get_tree().create_timer(0.5).timeout
		get_parent().game_over(1)


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
			"speed": u.speed,
			"is_support": u.is_support   # ✅ Klient môže zobraziť ikonu veliteľa
		})

	for id in players.keys():
		snapshot["players"][str(id)] = {   # ✅ String kľúče — konzistentné s klientom
			"mana": players[id].mana,
			"max_mana": players[id].max_mana
		}

	for id in bases.keys():
		snapshot["players"]["base_hp_%d" % id] = bases_hp[id]

	return snapshot


func client_play_card(player_id: int, card_id: String):
	print("📥 CLIENT REQUEST:", player_id, card_id)
	play_card(player_id, card_id)


func start_game():
	print("🎮 BattleManager: hra začína")
	game_started = true


func reset_game():
	print("🔄 BattleManager: reset hry")
	units.clear()
	next_spawn_id = 1
	game_started = false
	init_players()
	print("✅ BattleManager: pripravený na novú hru")
