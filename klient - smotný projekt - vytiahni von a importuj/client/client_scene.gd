extends Node2D

@export var websocket_url := "ws://localhost:9080"

@onready var btn_vojak = get_node_or_null("vojak")
@onready var btn_rychly = get_node_or_null("rýchly vojak")

@onready var wheel_scene = $CanvasLayer

var socket := WebSocketPeer.new()
var last_snapshot: Dictionary = {}
var hrac: int = 1
var game_started := false
var opponent_name: String = ""
var opponent_trophies: int = 0
var supabase_updating := false
var match_requested := false


var projectile_nodes: Dictionary = {}
var projectile_scene = preload("res://units/ProjectileNode.tscn")

# Sleduje živé unit nody: spawn_id -> Node2D
var unit_nodes: Dictionary = {}

# Preload unit scény
var unit_scene = preload("res://units/UnitNode.tscn")

func _ready():
    var heartbeat_timer = Timer.new()
    heartbeat_timer.wait_time = 0.5
    heartbeat_timer.autostart = true
    heartbeat_timer.timeout.connect(func():
        if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
            socket.send_text(JSON.stringify({"type": "ping"}))
    )
    add_child(heartbeat_timer)

    socket.set_no_delay(true)
    print("🚀 Štartujem klienta...")
    var err := socket.connect_to_url(websocket_url, TLSOptions.client_unsafe())
    if err != OK:
        print("❌ Chyba pripojenia")
        set_process(false)

    socket.inbound_buffer_size = 65536 * 2
    socket.outbound_buffer_size = 65536


func _process(_delta):
    socket.poll()

    var state := socket.get_ready_state()

    if state == WebSocketPeer.STATE_OPEN:
        if not match_requested:
            match_requested = true
            client_ready()

        while socket.get_available_packet_count() > 0:
            var packet := socket.get_packet()
            if socket.was_string_packet():
                _on_message(packet.get_string_from_utf8())

    elif state == WebSocketPeer.STATE_CLOSED:
        var code = socket.get_close_code()
        var reason = socket.get_close_reason()
        print("⚠️ Spojenie prerušené. Kód: %d, Dôvod: %s" % [code, reason])
        if not supabase_updating:
            set_process(false)


func _on_message(text: String):
    var data = JSON.parse_string(text)
    if data == null or typeof(data) != TYPE_DICTIONARY:
        return

    var type = data.get("type", "")

    if type == "player_id":
        hrac = int(data.get("id", 1))
        opponent_name = data.get("opponent", "Súper")
        opponent_trophies = int(data.get("opponent_trophies", 0))
        print("🎮 Som hráč: ", hrac, " | Súper: ", opponent_name)

    elif type == "waiting":
        print("⏳ Čakám na súpera...")

    elif type == "game_start":
        print("🚀 Hra začala!")
        game_started = true

    elif type == "snapshot":
        var snapshot_data = data.get("data", {})
        update_snapshot(snapshot_data)

    elif type == "game_over":
        supabase_updating = true
        var won: bool = data.get("won", false)
        game_started = false
        if won:
            print("🏆 Vyhral si! +30 trofejí")
        else:
            print("💀 Prehral si! -20 trofejí")
        await Supabase.update_after_match(Global.player_db_id, won)
        supabase_updating = false
        # Zobraz koleso
        if won:
            wheel_scene.show_wheel()
            await get_tree().create_timer(1.0).timeout
            wheel_scene.spin()
        set_process(false)


func update_snapshot(snapshot: Dictionary):
    last_snapshot = snapshot
    var units_data: Array = snapshot.get("units", [])
    # print("📦 Snapshot — počet jednotiek: ", units_data.size())
    #for u in units_data:
        #print("  unit: ", u)
    var alive_ids := {}

    for u in units_data:
        var id: int = u.get("id", 0)
        alive_ids[id] = true

        if not unit_nodes.has(id):
            _spawn_unit_node(id, u)
        else:
            unit_nodes[id].update_from_snapshot(u)

    # Zmaž nody jednotiek ktoré už nie sú v snapshote
    for id in unit_nodes.keys():
        if not alive_ids.has(id):
            _remove_unit_node(id)
    
    # Projektily
    var projectiles_data: Array = snapshot.get("projectiles", [])
    var alive_proj_ids := {}

    for p in projectiles_data:
        #print("🎯 Projektil data: ", p)
        var pid: int = int(p.get("id", 0))
        #print("PID: ", pid, " má node: ", projectile_nodes.has(pid), " keys: ", projectile_nodes.keys())
        alive_proj_ids[pid] = true
        if not projectile_nodes.has(pid):
            print("🚀 Spawnujem projektil ID: ", pid, " pos: ", p.get("pos", 0.0))
            var node = projectile_scene.instantiate()
            add_child(node)
            projectile_nodes[pid] = node
            node.setup(p)
        else:
            projectile_nodes[pid].update_position(p.get("pos", 0.0))

    for pid in projectile_nodes.keys():
        if not alive_proj_ids.has(pid):
            projectile_nodes[pid].queue_free()
            projectile_nodes.erase(pid)
    # print("🎯 Projektily v snapshote: ", projectiles_data.size())
    queue_redraw()


func _spawn_unit_node(id: int, unit_data: Dictionary):
    var node = unit_scene.instantiate()
    node.position = Vector2(unit_data.get("pos", 0.0), 400)
    add_child(node)
    unit_nodes[id] = node
    var utype = unit_data.get("unit_type", "jaskynny_muz")
    node.setup(utype)
    node.update_from_snapshot(unit_data)


func _remove_unit_node(id: int):
    if unit_nodes.has(id):
        var node = unit_nodes[id]
        unit_nodes.erase(id)
        if node.has_method("play_death"):
            node.play_death()
        else:
            node.queue_free()


# _draw() len pre základne
func _draw():
    if last_snapshot.is_empty():
        return

    var players = last_snapshot.get("players", {})

    if players.has("base_hp_1"):
        var hp1 = players["base_hp_1"]
        draw_rect(Rect2(Vector2(150-40, 360), Vector2(40, 40)), Color.GREEN if hp1 > 0 else Color.RED)
        draw_string(ThemeDB.fallback_font, Vector2(110, 355), "HP: %d" % hp1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

    if players.has("base_hp_2"):
        var hp2 = players["base_hp_2"]
        draw_rect(Rect2(Vector2(1002+20, 360), Vector2(40, 40)), Color.GREEN if hp2 > 0 else Color.RED)
        draw_string(ThemeDB.fallback_font, Vector2(1022, 355), "HP: %d" % hp2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


# --- OVLÁDANIE ---

func request_play_card(card_id: String):
    if not game_started:
        return
    if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        socket.send_text(JSON.stringify({"type": "play_card", "card": card_id}))
        print("📤 Poslaná karta: ", card_id)


func _on_vojak_pressed():
    request_play_card("spawn_jaskynny_muz")

func _on_rýchly_vojak_pressed():
    request_play_card("spawn_musketier")


func client_ready():
    socket.send_text(JSON.stringify({
        "type": "find_match",
        "username": Global.username,
        "trophies": Global.trophies
    }))
    print("📤 Hľadám súpera... Trofeje: ", Global.trophies)
