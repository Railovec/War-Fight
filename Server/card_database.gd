extends Node

var cards := {}

func _ready():
	register_cards()

func register_cards():

	# ══════════════════════════════════════════
	# KAMENNÁ DOBA
	# ══════════════════════════════════════════

	_add({
		"id": "spawn_jaskynny_muz",
		"cost": 3, "type": "spawn", "unit_type": "jaskynny_muz",
		"speed": 2, "era": "stone"
	})
	_add({
		"id": "spawn_lovec",
		"cost": 4, "type": "spawn", "unit_type": "lovec",
		"speed": 0.0, "era": "stone"   # ranged — nestojí, stojí na mieste
	})
	_add({
		"id": "spawn_saman",
		"cost": 6, "type": "spawn", "unit_type": "saman",
		"speed": 1, "era": "stone"
	})
	_add({
		"id": "spawn_mamut",
		"cost": 8, "type": "spawn", "unit_type": "mamut",
		"speed": 1, "era": "stone"
	})
	_add({
		"id": "spawn_faklar",
		"cost": 7, "type": "spawn", "unit_type": "faklar",
		"speed": 2.4, "era": "stone"
	})
	_add({
		"id": "spawn_jaskynny_strelec",
		"cost": 4, "type": "spawn", "unit_type": "jaskynny_strelec",
		"speed": 0.0, "era": "stone"
	})

	# ══════════════════════════════════════════
	# BRONZOVÁ DOBA
	# ══════════════════════════════════════════

	_add({
		"id": "spawn_bronzovy_vojak",
		"cost": 4, "type": "spawn", "unit_type": "bronzovy_vojak",
		"speed": 2.4, "era": "bronze"
	})
	_add({
		"id": "spawn_vojnovy_voz",
		"cost": 7, "type": "spawn", "unit_type": "vojnovy_voz",
		"speed": 10.0, "era": "bronze"
	})
	_add({
		"id": "spawn_lukostrelec",
		"cost": 5, "type": "spawn", "unit_type": "lukostrelec",
		"speed": 0.0, "era": "bronze"
	})
	_add({
		"id": "spawn_faraon",
		"cost": 9, "type": "spawn", "unit_type": "faraon",
		"speed": 2.0, "era": "bronze"
	})

	# ══════════════════════════════════════════
	# ŽELEZNÁ DOBA
	# ══════════════════════════════════════════

	_add({
		"id": "spawn_legionar",
		"cost": 5, "type": "spawn", "unit_type": "legionar",
		"speed": 3, "era": "iron"
	})
	_add({
		"id": "spawn_balistar",
		"cost": 8, "type": "spawn", "unit_type": "balistar",
		"speed": 0.4, "era": "iron"
	})
	_add({
		"id": "spawn_gladiator",
		"cost": 6, "type": "spawn", "unit_type": "gladiator",
		"speed": 4.0, "era": "iron"
	})
	_add({
		"id": "spawn_saboter",
		"cost": 7, "type": "spawn", "unit_type": "saboter",
		"speed": 6.0, "era": "iron"
	})

	# ══════════════════════════════════════════
	# STREDOVEK
	# ══════════════════════════════════════════

	_add({
		"id": "spawn_rytier",
		"cost": 6, "type": "spawn", "unit_type": "rytier",
		"speed": 2.0, "era": "medieval"
	})
	_add({
		"id": "spawn_trebuchet",
		"cost": 9, "type": "spawn", "unit_type": "trebuchet",
		"speed": 0.2, "era": "medieval"
	})
	_add({
		"id": "spawn_mnich",
		"cost": 5, "type": "spawn", "unit_type": "mnich",
		"speed": 2.0, "era": "medieval"
	})
	_add({
		"id": "spawn_drak",
		"cost": 10, "type": "spawn", "unit_type": "drak",
		"speed": 8.0, "era": "medieval"
	})

	# ══════════════════════════════════════════
	# PRIEMYSELNÁ DOBA
	# ══════════════════════════════════════════

	_add({
		"id": "spawn_musketier",
		"cost": 5, "type": "spawn", "unit_type": "musketier",
		"speed": 0.0, "era": "industrial"
	})
	_add({
		"id": "spawn_parny_tank",
		"cost": 10, "type": "spawn", "unit_type": "parny_tank",
		"speed": 1.6, "era": "industrial"
	})
	_add({
		"id": "spawn_inzinier",
		"cost": 7, "type": "spawn", "unit_type": "inzinier",
		"speed": 2.0, "era": "industrial"
	})
	_add({
		"id": "spawn_dynamiter",
		"cost": 6, "type": "spawn", "unit_type": "dynamiter",
		"speed": 6.0, "era": "industrial"
	})

	# ══════════════════════════════════════════
	# DRUHÁ SVETOVÁ VOJNA
	# ══════════════════════════════════════════

	_add({
		"id": "spawn_vojak_ww2",
		"cost": 4, "type": "spawn", "unit_type": "vojak_ww2",
		"speed": 4.0, "era": "ww2"
	})
	_add({
		"id": "spawn_panzer",
		"cost": 10, "type": "spawn", "unit_type": "panzer",
		"speed": 3, "era": "ww2"
	})
	_add({
		"id": "spawn_odstrelec",
		"cost": 7, "type": "spawn", "unit_type": "odstrelec",
		"speed": 0.0, "era": "ww2"
	})
	_add({
		"id": "letecky_utok",
		"cost": 8, "type": "spell", "unit_type": "",
		"speed": 0.0, "era": "ww2"
	})


func _add(data: Dictionary):
	var c := Card.new()
	c.id = data["id"]
	c.cost = data["cost"]
	c.type = data["type"]
	c.unit_type = data.get("unit_type", "")
	c.speed = data.get("speed", 1.0)
	c.speed = c.speed*2.5
	c.era = data.get("era", "stone")
	cards[c.id] = c
