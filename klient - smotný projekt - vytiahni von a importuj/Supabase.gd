extends Node

const URL := "https://husqgjpehttjiozhpvwl.supabase.co" 
const KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1c3FnanBlaHR0amlvemhwdndsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODE3MTcsImV4cCI6MjA4OTY1NzcxN30.21hhd62jUGz4Yd27LegMZDVEmelO6sfaKY7sV8oU2Mw"


func _headers() -> PackedStringArray:
	return [
		"Content-Type: application/json",
		"apikey: " + KEY,
		"Authorization: Bearer " + KEY,
		"Prefer: return=representation"
	]


# Prihlási hráča — ak existuje vráti dáta, ak nie vytvorí nového
func login(uuid: String, username: String) -> Dictionary:
	var result = await _request(
		"/rest/v1/players?id=eq." + uuid + "&select=*",
		HTTPClient.METHOD_GET, ""
	)

	if result.size() > 0:
		print("✅ Existujúci hráč nájdený: ", result[0].get("username", ""))
		return result[0]

	# Nový hráč
	var body := JSON.stringify({
		"id": uuid,
		"username": username,
		"trophies": 100
	})
	var created = await _request("/rest/v1/players", HTTPClient.METHOD_POST, body)

	if created.size() > 0:
		print("✅ Nový hráč vytvorený: ", username)
		return created[0]

	print("❌ Login zlyhal")
	return {}


# Aktualizuje trofeje a win/loss po skončení zápasu
func update_after_match(uuid: String, won: bool) -> void:
	var player = await get_player(uuid)
	if player.is_empty():
		return

	var trophy_change := 30 if won else -20
	var new_trophies: int = max(0, int(player.get("trophies", 0)) + trophy_change)

	var body := JSON.stringify({
		"trophies": new_trophies,
		"wins": int(player.get("wins", 0)) + (1 if won else 0),
		"losses": int(player.get("losses", 0)) + (0 if won else 1)
	})

	await _request(
		"/rest/v1/players?id=eq." + uuid,
		HTTPClient.METHOD_PATCH, body
	)

	Global.trophies = new_trophies
	Global.save_game()
	print("✅ Trofeje aktualizované: ", new_trophies)


# Načíta jedného hráča podľa UUID
func get_player(uuid: String) -> Dictionary:
	var result = await _request(
		"/rest/v1/players?id=eq." + uuid + "&select=*",
		HTTPClient.METHOD_GET, ""
	)
	if result.size() > 0:
		return result[0]
	return {}


# Top 10 hráčov pre leaderboard
func get_leaderboard() -> Array:
	var result = await _request(
		"/rest/v1/players?select=username,trophies&order=trophies.desc&limit=10",
		HTTPClient.METHOD_GET, ""
	)
	return result


# Interná pomocná funkcia — všetky HTTP requesty idú cez ňu
func _request(endpoint: String, method: int, body: String) -> Array:
	var http := HTTPRequest.new()
	add_child(http)

	var err := http.request(URL + endpoint, _headers(), method, body)

	if err != OK:
		push_error("❌ Supabase request error: " + str(err))
		http.queue_free()
		return []

	var response: Array = await http.request_completed
	http.queue_free()

	var response_code: int = response[1]
	var response_body: PackedByteArray = response[3]
	var text := response_body.get_string_from_utf8()

	# print("🌐 Supabase [", response_code, "] ", endpoint, " → ", text)  # ← pridaj tento riadok

	if response_code >= 400:
		push_error("❌ Supabase HTTP " + str(response_code) + ": " + text)
		return []

	var parsed = JSON.parse_string(text)
	if parsed == null:
		return []

	if typeof(parsed) == TYPE_ARRAY:
		return parsed

	return [parsed]
