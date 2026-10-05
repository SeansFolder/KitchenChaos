class_name SaveManager

const SAVE_PATH := "user://kitchen_chaos_save.json"
const SLOT_COUNT := 3

static var active_slot: int = 1

static func set_active_slot(slot: int) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		push_error("Save slot must be between 1 and %d; got %d." % [SLOT_COUNT, slot])
		return
	active_slot = slot

static func slot_path(slot: int) -> String:
	if slot == 1:
		return SAVE_PATH
	return "user://kitchen_chaos_slot_%d.json" % slot

static func slot_exists(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	return FileAccess.file_exists(slot_path(slot))

static func load_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT:
		push_error("Cannot load invalid save slot: %d." % slot)
		return {}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open save slot %d for reading (error %d)." % [slot, FileAccess.get_open_error()])
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_warning("Save slot %d contains invalid data and will be treated as empty." % slot)
	return {}

static func save_game(data: Dictionary) -> void:
	var existing := load_game()
	for key in data.keys():
		existing[key] = data[key]
	_write_slot(active_slot, existing)

static func save_upgrades(upgrades: Dictionary) -> void:
	var data := load_game()
	data["upgrades"] = upgrades
	_write_slot(active_slot, data)

static func load_game() -> Dictionary:
	return load_slot(active_slot)

static func load_upgrades() -> Dictionary:
	var data := load_game()
	if data.has("upgrades") and data["upgrades"] is Dictionary:
		return data["upgrades"]
	return {}

static func _write_slot(slot: int, data: Dictionary) -> void:
	if slot < 1 or slot > SLOT_COUNT:
		push_error("Cannot write invalid save slot: %d." % slot)
		return
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save slot %d for writing (error %d)." % [slot, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data))
	file.close()
