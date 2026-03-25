extends Control

@onready var grid = $ScrollContainer/GridContainer
@onready var card_name_label = $InfoPanel/MarginContainer/VBoxContainer/CardName
@onready var card_level_label = $InfoPanel/MarginContainer/VBoxContainer/CardLevel
@onready var upgrade_btn = $InfoPanel/MarginContainer/VBoxContainer/UpgradeButton
@onready var gold_cost_label = $InfoPanel/MarginContainer/VBoxContainer/GoldCost

const UPGRADE_GOLD_COST = 100
var selected_card_id: String = ""

const ERAS = {
	"Kamenná": ["spawn_jaskynny_muz", "spawn_lovec", "spawn_saman", "spawn_mamut"],
	"Bronzová": ["spawn_bronzovy_vojak", "spawn_vojnovy_voz", "spawn_lukostrelec", "spawn_faraon"],
	"Železná": ["spawn_legionar", "spawn_balistar", "spawn_gladiator", "spawn_saboter"],
	"Stredovek": ["spawn_rytier", "spawn_trebuchet", "spawn_mnich", "spawn_drak"],
	"Priemyselná": ["spawn_musketier", "spawn_parny_tank", "spawn_inzinier", "spawn_dynamiter"],
	"WW2": ["spawn_vojak_ww2", "spawn_panzer", "spawn_odstrelec"]
}

func _ready():
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	_build_card_grid()
	_update_info_panel()

func _build_card_grid():
	for child in grid.get_children():
		child.queue_free()
	
	for era_name in ERAS.keys():
		# Era sekcia
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 5)
		grid.add_child(vbox)
				
				# Era nadpis
		var era_label = Label.new()
		era_label.text = "── " + era_name + " ──"
		era_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		vbox.add_child(era_label)
				
				# HFlowContainer pre karty
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
	selected_card_id = card_id
	_update_info_panel()

func _update_info_panel():
	if selected_card_id == "":
		card_name_label.text = "Vyber kartu"
		card_level_label.text = ""
		gold_cost_label.text = ""
		upgrade_btn.disabled = true
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

func _cards_needed(level: int) -> int:
	return 5 * int(pow(2, level - 1))

func _get_card_image(card_id: String) -> String:
	for img_path in Global.card_image_to_id.keys():
		if Global.card_image_to_id[img_path] == card_id:
			return img_path
	return ""

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://menu/startovascena.tscn")
