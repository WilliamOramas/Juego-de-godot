extends Node

const MAX_ENTRIES: int = 200
const MAX_DIALOG_ENTRIES: int = 50
const MAX_DESC_LENGTH: int = 150

var _entries: Array[JournalEntry] = []
var _dialog_count: int = 0


func add_entry(category: JournalEntry.Category, title: String, description: String, icon_path: String = "") -> void:
	var entry := JournalEntry.new()
	entry.timestamp = Time.get_ticks_msec() / 1000.0
	entry.category = category
	entry.title = title
	entry.description = _truncate(description)
	entry.icon_path = icon_path
	_entries.append(entry)

	if category == JournalEntry.Category.DIALOG:
		_dialog_count += 1
		if _dialog_count > MAX_DIALOG_ENTRIES:
			_trim_oldest_dialog()

	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()

	EventBus.journal_entry_added.emit(entry)


func add_minigame_entry(title: String, description: String) -> void:
	add_entry(JournalEntry.Category.MINIGAME, title, description)


func add_dialog_entry(npc_name: String, lines: Array[String]) -> void:
	var combined := ""
	for line in lines:
		if combined.length() > 0:
			combined += " | "
		combined += line
	add_entry(JournalEntry.Category.DIALOG, npc_name, combined)


func add_quest_entry(title: String, description: String) -> void:
	add_entry(JournalEntry.Category.QUEST, title, description)


func add_system_entry(title: String, description: String) -> void:
	add_entry(JournalEntry.Category.SYSTEM, title, description)


func get_entries() -> Array[JournalEntry]:
	return _entries.duplicate()


func get_filtered(category: JournalEntry.Category) -> Array[JournalEntry]:
	return _entries.filter(func(e): return e.category == category)


func get_entry_count() -> int:
	return _entries.size()


func clear() -> void:
	_entries.clear()
	_dialog_count = 0


func serialize() -> Array:
	return _entries.map(func(e): return {
		"timestamp": e.timestamp,
		"category": e.category,
		"title": e.title,
		"description": e.description,
		"icon_path": e.icon_path,
	})


func deserialize(data: Array) -> void:
	_entries.clear()
	_dialog_count = 0
	for d in data:
		var entry := JournalEntry.new()
		entry.timestamp = d.get("timestamp", 0.0)
		entry.category = d.get("category", JournalEntry.Category.SYSTEM) as JournalEntry.Category
		entry.title = d.get("title", "")
		entry.description = d.get("description", "")
		entry.icon_path = d.get("icon_path", "")
		_entries.append(entry)
		if entry.category == JournalEntry.Category.DIALOG:
			_dialog_count += 1


func _truncate(text: String) -> String:
	if text.length() <= MAX_DESC_LENGTH:
		return text
	return text.substr(0, MAX_DESC_LENGTH) + "..."


func _trim_oldest_dialog() -> void:
	var i := 0
	while i < _entries.size() and _dialog_count > MAX_DIALOG_ENTRIES:
		if _entries[i].category == JournalEntry.Category.DIALOG:
			_entries.remove_at(i)
			_dialog_count -= 1
		else:
			i += 1
