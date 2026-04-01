extends Control

@onready var grid = $ScrollContainer/GridContainer
@onready var card_name_label = $InfoPanel/MarginContainer/VBoxContainer/CardName
@onready var card_level_label = $InfoPanel/MarginContainer/VBoxContainer/CardLevel
@onready var upgrade_btn = $InfoPanel/MarginContainer/VBoxContainer/UpgradeButton
@onready var gold_cost_label = $InfoPanel/MarginContainer/VBoxContainer/GoldCost
@onready var doc_scroll = $InfoPanel/MarginContainer/VBoxContainer/ScrollContainer

const UPGRADE_GOLD_COST = 100
var selected_card_id: String = ""
var doc_label: RichTextLabel

const ERAS = {
	"Kamenná": ["spawn_jaskynny_muz", "spawn_lovec", "spawn_saman", "spawn_mamut", "spawn_jaskynny_strelec", "spawn_faklar"],
	"Bronzová": ["spawn_bronzovy_vojak", "spawn_vojnovy_voz", "spawn_lukostrelec", "spawn_faraon"],
	"Železná": ["spawn_legionar", "spawn_balistar", "spawn_gladiator", "spawn_saboter"],
	"Stredovek": ["spawn_rytier", "spawn_trebuchet", "spawn_mnich", "spawn_drak"],
	"Priemyselná": ["spawn_musketier", "spawn_parny_tank", "spawn_inzinier", "spawn_dynamiter"],
	"WW2": ["spawn_vojak_ww2", "spawn_panzer", "spawn_odstrelec"]
}

const CARD_DOCS = {
	"spawn_jaskynny_muz": {
		"name": "Jaskynný muž", "era": "Kamenná doba",
		"hp": 90, "dmg": 9, "speed": 1.0, "attack_speed": "1.0s", "range": "Melee", "cost": 3,
		"mechanic": "Žiadny špeciálny efekt. Najlacnejšia jednotka v hre.",
		"tip": "Ideálny na zaplavenie nepriateľa množstvom. Hraj ich 3-4 naraz."
	},
	"spawn_lovec": {
		"name": "Lovec", "era": "Kamenná doba",
		"hp": 80, "dmg": 14, "speed": 0.0, "attack_speed": "1.2s", "range": "80px", "cost": 4,
		"mechanic": "Stojí na mieste a útočí na diaľku. Nepohybuje sa smerom k nepriateľom.",
		"tip": "Umiestni za frontovými jednotkami — krytý tank ho ochráni."
	},
	"spawn_saman": {
		"name": "Šaman", "era": "Kamenná doba",
		"hp": 100, "dmg": 2, "speed": 0.5, "attack_speed": "1.0s", "range": "Melee", "cost": 6,
		"mechanic": "Každý tik lieči všetky spojenecké jednotky o +8 HP. Kým žije.",
		"tip": "Priorita súpera ho zabiť. Drž ho za frontou a chráň ho."
	},
	"spawn_mamut": {
		"name": "Mamut", "era": "Kamenná doba",
		"hp": 300, "dmg": 22, "speed": 0.5, "attack_speed": "2.0s", "range": "Melee", "cost": 8,
		"mechanic": "Pri smrti exploduje — dá 35 DMG všetkým nepriateľom v dosahu 50px.",
		"tip": "Pošli ho priamo do zhluku nepriateľov. Výbuch pri death je reward."
	},
	"spawn_faklar": {
		"name": "Fakľar", "era": "Kamenná doba",
		"hp": 110, "dmg": 12, "speed": 1.2, "attack_speed": "1.0s",
		"range": "Melee", "cost": 7,
		"mechanic": "Pri každom útoku zapáli nepriateľa — cieľ horí 3 sekundy a stráca 5 HP za tik. Oheň sa nedá stackovať.",
		"tip": "Kombinuj s pomalými tankami — burn robí damage kým tank drží nepriateľa na mieste."
	},
	"spawn_jaskynny_strelec": {
		"name": "Jaskynný strelec", "era": "Kamenná doba",
		"hp": 70, "dmg": 16, "speed": 0.0, "attack_speed": "1.5s",
		"range": "100px", "cost": 4,
		"mechanic": "Stojí na mieste a útočí prakom na diaľku. Prvý výstrel má nulový cooldown — útočí okamžite po spawnovaní.",
		"tip": "Lacný ranged damage. Daj za frontovú líniu — jaskynný muž ho ochráni."
	},
	"spawn_bronzovy_vojak": {
		"name": "Bronzový vojak", "era": "Bronzová doba",
		"hp": 120, "dmg": 13, "speed": 1.2, "attack_speed": "1.0s", "range": "Melee", "cost": 4,
		"mechanic": "Štandardný vojak bez špeciálneho efektu.",
		"tip": "Hlavná bojová sila Bronzovej doby. Hraj ich konzistentne."
	},
	"spawn_vojnovy_voz": {
		"name": "Vojnový voz", "era": "Bronzová doba",
		"hp": 180, "dmg": 16, "speed": 5.0, "attack_speed": "0.8s", "range": "Melee + Splash 15px", "cost": 7,
		"mechanic": "Veľmi rýchly. Útok má splash polomer 15px — zasahuje viacero nepriateľov naraz.",
		"tip": "Efektívny proti skupinkám. Rýchlosť 5.0 ho dostane na front veľmi rýchlo."
	},
	"spawn_lukostrelec": {
		"name": "Lukostrelec", "era": "Bronzová doba",
		"hp": 80, "dmg": 20, "speed": 0.0, "attack_speed": "1.5s", "range": "120px", "cost": 5,
		"mechanic": "Targeting: LOWEST HP — vždy útočí na najslabšiu nepriateľskú jednotku.",
		"tip": "Výborný na dostrieľanie oslabených jednotiek. Kombinuj s tankami vpredu."
	},
	"spawn_faraon": {
		"name": "Faraón", "era": "Bronzová doba",
		"hp": 160, "dmg": 6, "speed": 1.0, "attack_speed": "1.5s", "range": "Melee", "cost": 9,
		"mechanic": "Kým žije, všetky spojenecké jednotky útočia o 30% rýchlejšie.",
		"tip": "Najhodnotnejšia support jednotka Bronzovej doby. Súper ho musí zabiť čo najskôr."
	},
	"spawn_legionar": {
		"name": "Legionár", "era": "Železná doba",
		"hp": 150, "dmg": 15, "speed": 1.5, "attack_speed": "1.0s", "range": "Melee", "cost": 5,
		"mechanic": "Formácia: ak sú 2+ legionári do 30px od seba, každý dostane +30% max HP.",
		"tip": "Vždy hraj minimálne 2 legionárov naraz. Samotný legionár je priemerný."
	},
	"spawn_balistar": {
		"name": "Balistar", "era": "Železná doba",
		"hp": 100, "dmg": 38, "speed": 0.2, "attack_speed": "3.0s", "range": "60px + Splash 20px", "cost": 8,
		"mechanic": "Útočí každé 3 sekundy ale s obrovským splash poškodením v okruhu 20px.",
		"tip": "Pomalý ale devastujúci. Chráň ho — zomrie rýchlo ak sa dostane do melee."
	},
	"spawn_gladiator": {
		"name": "Gladiátor", "era": "Železná doba",
		"hp": 150, "dmg": 24, "speed": 2.0, "attack_speed": "1.0s", "range": "Melee", "cost": 6,
		"mechanic": "Targeting: HIGHEST HP — vždy útočí na najpevnejšiu nepriateľskú jednotku.",
		"tip": "Prirodzený counter na tanky. Pošli ho priamo proti Mamutom a Parným tankom."
	},
	"spawn_saboter": {
		"name": "Sabotér", "era": "Železná doba",
		"hp": 130, "dmg": 12, "speed": 3.0, "attack_speed": "1.0s", "range": "Melee", "cost": 7,
		"mechanic": "Ignoruje všetky nepriateľské jednotky — ide priamo na základňu.",
		"tip": "Súper ho musí aktívne zastaviť. Kombinuj s útočnou armádou pre rozptýlenie."
	},
	"spawn_rytier": {
		"name": "Rytier", "era": "Stredovek",
		"hp": 200, "dmg": 17, "speed": 1.0, "attack_speed": "1.2s", "range": "Melee", "cost": 6,
		"mechanic": "Shield: kým má viac ako 50% HP, blokuje 50% každého prichádzajúceho poškodenia.",
		"tip": "Efektívnych prvých 100 HP je vlastne 200 HP vďaka shieldu. Skvelý tank."
	},
	"spawn_trebuchet": {
		"name": "Trebuchet", "era": "Stredovek",
		"hp": 80, "dmg": 45, "speed": 0.1, "attack_speed": "4.0s", "range": "Priamy útok na základňu", "cost": 9,
		"mechanic": "Útočí priamo na súperovu základňu bez ohľadu na pozíciu iných jednotiek.",
		"tip": "Extrémny tlak na základňu. Súper ho musí zničiť aktívne."
	},
	"spawn_mnich": {
		"name": "Mních", "era": "Stredovek",
		"hp": 90, "dmg": 0, "speed": 1.0, "attack_speed": "1.0s", "range": "Support", "cost": 5,
		"mechanic": "Neútočí vôbec. Každý tik lieči spojeneckú jednotku s najnižším HP o +18 HP.",
		"tip": "Silnejší healer ako Šaman (18 vs 8 HP). Skvelý s Rytiermi a Parným tankom."
	},
	"spawn_drak": {
		"name": "Drak", "era": "Stredovek",
		"hp": 280, "dmg": 28, "speed": 4.0, "attack_speed": "1.2s", "range": "Melee", "cost": 10,
		"mechanic": "Preskočí prvú líniu — útočí na jednotky vzdialené viac ako 100px, alebo priamo na základňu.",
		"tip": "Výborný counter na ranged jednotky schované za frontou."
	},
	"spawn_musketier": {
		"name": "Musketier", "era": "Priemyselná doba",
		"hp": 80, "dmg": 25, "speed": 0.0, "attack_speed": "2.5s", "range": "700px", "cost": 5,
		"mechanic": "Prvý výstrel má nulový cooldown — útočí okamžite po spawnovaní.",
		"tip": "Vysoký DMG ale pomalý. Prvý výstrel zadarmo ho robí silným v prvom momente."
	},
	"spawn_parny_tank": {
		"name": "Parný tank", "era": "Priemyselná doba",
		"hp": 380, "dmg": 32, "speed": 0.8, "attack_speed": "1.5s", "range": "Melee", "cost": 10,
		"mechanic": "Neprestáva sa pohybovať počas útoku — pokračuje smerom k cieľu aj keď útočí.",
		"tip": "Nedá sa zastaviť. Dobehne až k základni aj s celou armádou pred ním."
	},
	"spawn_inzinier": {
		"name": "Inžinier", "era": "Priemyselná doba",
		"hp": 120, "dmg": 6, "speed": 1.0, "attack_speed": "1.0s", "range": "Melee", "cost": 7,
		"mechanic": "Každé 3 sekundy postaví barikádu (HP 80) na svojej pozícii.",
		"tip": "Výborný na spomalenie nepriateľského útoku. Pošli ho dopredu pred ostatnými."
	},
	"spawn_dynamiter": {
		"name": "Dynamitér", "era": "Priemyselná doba",
		"hp": 90, "dmg": 6, "speed": 3.0, "attack_speed": "1.0s", "range": "Melee", "cost": 6,
		"mechanic": "Pri smrti exploduje — dá 90 DMG všetkým nepriateľom v dosahu 60px.",
		"tip": "Pošli ho priamo do najhustejšieho zhluku nepriateľov. Death explosion je jeho hlavná sila."
	},
	"spawn_vojak_ww2": {
		"name": "Vojak WW2", "era": "Druhá svetová vojna",
		"hp": 110, "dmg": 18, "speed": 2.0, "attack_speed": "1.0s", "range": "Melee", "cost": 4,
		"mechanic": "Spawn 2 jednotky naraz za cenu jednej karty.",
		"tip": "Najlepší value v hre — 2× vojaci s 110 HP a 18 DMG za 4 many."
	},
	"spawn_panzer": {
		"name": "Panzer", "era": "Druhá svetová vojna",
		"hp": 380, "dmg": 35, "speed": 1.5, "attack_speed": "2.0s", "range": "Melee", "cost": 10,
		"mechanic": "Prebíja sa cez jednotky — pri kontakte dá 20 DMG každej nepriateľskej jednotke vedľa neho.",
		"tip": "Najodolnejšia jednotka v hre. Kombinuj s Mníchom pre maximálnu výdrž."
	},
	"spawn_odstrelec": {
		"name": "Odstrelec", "era": "Druhá svetová vojna",
		"hp": 70, "dmg": 55, "speed": 0.0, "attack_speed": "4.0s", "range": "200px", "cost": 7,
		"mechanic": "Targeting: HIGHEST HP. Útočí raz za 4s ale spomaľuje cieľ o 1 sekundu (speed × 0.3).",
		"tip": "Najväčší single-target DMG v hre. Výborný counter na Panzera a Rytiera."
	},
}

func _ready():
	upgrade_btn.visible = false
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	_setup_doc_label()
	_build_card_grid()
	_update_info_panel()

func _setup_doc_label():
	doc_label = RichTextLabel.new()
	doc_label.bbcode_enabled = true
	doc_label.fit_content = true
	doc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	doc_scroll.add_child(doc_label)

func _build_card_grid():
	for child in grid.get_children():
		child.queue_free()
	
	for era_name in ERAS.keys():
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 5)
		grid.add_child(vbox)
		
		var era_label = Label.new()
		era_label.text = "── " + era_name + " ──"
		era_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		vbox.add_child(era_label)
		
		var flow = HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		vbox.add_child(flow)
		
		for card_id in ERAS[era_name]:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(80, 80)
			btn.expand_icon = true
			
			var img_path = _get_card_image(card_id)
			if img_path != "":
				var tex = load(img_path)
				if tex:
					btn.icon = tex
			
			var owns = Global.owns_card(card_id)
			var lvl = Global.card_levels.get(card_id, 1)
			var count = Global.card_counts.get(card_id, 0)
			var needed = _cards_needed(lvl)
			var gold_cost = UPGRADE_GOLD_COST * lvl
			
			if not owns:
				btn.modulate = Color(0.3, 0.3, 0.3)
				btn.disabled = true
			elif count >= needed and Global.gold >= gold_cost:
				btn.add_theme_stylebox_override("normal", _colored_style(Color(0.2, 0.8, 0.2, 0.5)))
			elif count < needed:
				btn.add_theme_stylebox_override("normal", _colored_style(Color(0.9, 0.5, 0.1, 0.5)))
			
			btn.text = "Lv" + str(lvl)
			btn.pressed.connect(func(): _select_card(card_id))
			flow.add_child(btn)

func _colored_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	return style

func _select_card(card_id: String):
	upgrade_btn.visible = true
	selected_card_id = card_id
	_update_info_panel()
	_update_doc(card_id)

func _update_doc(card_id: String):
	Global.play_click()
	var doc = CARD_DOCS.get(card_id, {})
	if doc.is_empty():
		doc_label.text = ""
		return
	
	var lvl = Global.card_levels.get(card_id, 1)
	var multiplier = 1.0 + (lvl - 1) * 0.1
	var hp_scaled = int(doc["hp"] * multiplier)
	var dmg_scaled = int(doc["dmg"] * multiplier)
	
	var txt = ""
	txt += "[color=#ffd700][b]%s[/b][/color]  [color=#aaaaaa]%s[/color]\n\n" % [doc["name"], doc["era"]]
	txt += "[color=#ff6666]❤️ HP:[/color] %d" % hp_scaled
	if lvl > 1: txt += " [color=#888888](base %d)[/color]" % doc["hp"]
	txt += "\n"
	txt += "[color=#ff9944]⚔️ DMG:[/color] %d" % dmg_scaled
	if lvl > 1: txt += " [color=#888888](base %d)[/color]" % doc["dmg"]
	txt += "\n"
	txt += "[color=#44aaff]💰 Mana:[/color] %d\n" % doc["cost"]
	txt += "[color=#ffffff]🏃 Speed:[/color] %.1f\n" % doc["speed"]
	txt += "[color=#ffffff]⏱️ Atk speed:[/color] %s\n" % doc["attack_speed"]
	txt += "[color=#ffffff]🎯 Dosah:[/color] %s\n\n" % doc["range"]
	txt += "[color=#88ff88][b]Mechanika:[/b][/color]\n[color=#dddddd]%s[/color]\n\n" % doc["mechanic"]
	txt += "[color=#ffcc44][b]💡 Tip:[/b][/color]\n[color=#dddddd]%s[/color]" % doc["tip"]
	
	doc_label.text = txt

func _update_info_panel():
	if selected_card_id == "":
		card_name_label.text = "Vyber kartu"
		card_level_label.text = ""
		gold_cost_label.text = ""
		upgrade_btn.visible = false
		if doc_label:
			doc_label.text = ""
		return
	
	var lvl = Global.card_levels.get(selected_card_id, 1)
	var count = Global.card_counts.get(selected_card_id, 0)
	var needed = _cards_needed(lvl)
	var gold_cost = UPGRADE_GOLD_COST * lvl
	
	card_name_label.text = selected_card_id.replace("spawn_", "").capitalize()
	card_level_label.text = "Level: %d | Karty: %d/%d 🃏" % [lvl, count, needed]
	gold_cost_label.text = "Cena: %d 💰 (máš: %d 💰)" % [gold_cost, Global.gold]
	upgrade_btn.disabled = count < needed or Global.gold < gold_cost or not Global.owns_card(selected_card_id)

func _on_upgrade_pressed():
	Global.play_clickdva()
	if selected_card_id == "":
		return
	var lvl = Global.card_levels.get(selected_card_id, 1)
	var gold_cost = UPGRADE_GOLD_COST * lvl
	
	Global.gold -= gold_cost
	Global.card_levels[selected_card_id] = lvl + 1
	Global.card_counts[selected_card_id] = Global.card_counts.get(selected_card_id, 0) - _cards_needed(lvl)
	Global.save_game()
	
	await Supabase.upgrade_card(Global.player_db_id, selected_card_id)
	await Supabase.add_gold(Global.player_db_id, -gold_cost)
	
	print("⬆️ Upgrade: ", selected_card_id, " → Lv", lvl + 1)
	_build_card_grid()
	_update_info_panel()
	_update_doc(selected_card_id)

func _cards_needed(level: int) -> int:
	return 5 * int(pow(2, level - 1))

func _get_card_image(card_id: String) -> String:
	for img_path in Global.card_image_to_id.keys():
		if Global.card_image_to_id[img_path] == card_id:
			return img_path
	return ""

func _on_back_button_pressed():
	Global.play_click()
	get_tree().change_scene_to_file("res://menu/startovascena.tscn")
