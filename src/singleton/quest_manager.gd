extends Node

var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

var _notif_queue: Array[Dictionary] = []
var _notif_busy: bool = false

func _ready() -> void:
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	EventBus.quest_started.connect(_on_quest_started)
	EventBus.objective_advanced.connect(_on_objective_advanced)
	EventBus.quest_completed.connect(_on_quest_completed)

func start_quest(quest_data: Variant) -> bool:
	if quest_data == null:
		return false
	if active_quests.has(quest_data.quest_id) or completed_quests.has(quest_data.quest_id):
		return false
	if quest_data.requires_quest != "" and not completed_quests.has(quest_data.requires_quest):
		EventBus.quest_blocked.emit(quest_data.quest_id, quest_data.requires_quest)
		return false
	var objectives: Dictionary = {}
	for obj in quest_data.objectives:
		objectives[obj.objective_id] = false
	active_quests[quest_data.quest_id] = {
		"quest_data": quest_data,
		"objectives": objectives,
	}
	SaveManager.mark_dirty()
	EventBus.quest_started.emit(quest_data.quest_id, quest_data.quest_name)
	return true

func advance_objective(quest_id: String, objective_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var quest: Dictionary = active_quests[quest_id]
	if not quest.objectives.has(objective_id):
		return
	quest.objectives[objective_id] = true
	SaveManager.mark_dirty()
	var obj_description := ""
	var qdata: Variant = quest.get("quest_data")
	if qdata:
		for obj in qdata.objectives:
			if obj.objective_id == objective_id:
				obj_description = obj.description
				break
	EventBus.objective_advanced.emit(quest_id, objective_id, obj_description)
	if _are_all_objectives_done(quest):
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var quest_name := ""
	var quest: Dictionary = active_quests.get(quest_id, {})
	if quest.has("quest_data"):
		quest_name = quest.quest_data.quest_name
	completed_quests[quest_id] = true
	active_quests.erase(quest_id)
	SaveManager.mark_dirty()
	EventBus.quest_completed.emit(quest_id, quest_name)

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

func is_objective_done(quest_id: String, objective_id: String) -> bool:
	if completed_quests.has(quest_id):
		return true
	if active_quests.has(quest_id):
		var quest: Dictionary = active_quests[quest_id]
		return quest.objectives.get(objective_id, false)
	return false

func get_quest_progress() -> Dictionary:
	var save_active: Dictionary = {}
	for qid in active_quests:
		save_active[qid] = {
			"objectives": active_quests[qid].objectives.duplicate(true),
		}
	return {
		"active_quests": save_active,
		"completed_quests": completed_quests.duplicate(true),
	}

func set_quest_progress(data: Dictionary) -> void:
	active_quests.clear()
	completed_quests.clear()
	if data.has("active_quests") and data["active_quests"] is Dictionary:
		for qid in data["active_quests"]:
			var entry: Dictionary = data["active_quests"][qid]
			var quest_data: Variant = _load_quest_data(qid)
			if quest_data:
				active_quests[qid] = {
					"quest_data": quest_data,
					"objectives": entry.get("objectives", {}).duplicate(true),
				}
	if data.has("completed_quests") and data["completed_quests"] is Dictionary:
		completed_quests = data["completed_quests"].duplicate(true)

func advance_talk_objectives(npc_name: String) -> void:
	_try_advance_objectives(QuestObjective.ObjectiveType.TALK_TO_NPC, npc_name)

func _try_advance_objectives(type: QuestObjective.ObjectiveType, target: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var qdata: Variant = quest.get("quest_data")
		if not qdata:
			continue
		for obj in qdata.objectives:
			if quest.objectives.get(obj.objective_id, false):
				continue
			if obj.type == type and obj.target_id == target:
				advance_objective(quest_id, obj.objective_id)

func _are_all_objectives_done(quest: Dictionary) -> bool:
	for obj_id in quest.objectives:
		if not quest.objectives[obj_id]:
			return false
	return true

func _on_scene_changed(scene_path: String) -> void:
	_try_advance_objectives(QuestObjective.ObjectiveType.REACH_SCENE, scene_path)

func _on_minigame_completed(game_id: String, success: bool) -> void:
	if success:
		_try_advance_objectives(QuestObjective.ObjectiveType.COMPLETE_MINIGAME, game_id)

func _load_quest_data(quest_id: String) -> Variant:
	var path := "res://src/quests/%s.tres" % quest_id
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _on_quest_started(_qid: String, qname: String) -> void:
	_show_notification("Nueva misi\u00f3n: \"" + qname + "\"", Color.GOLD)
	JournalManager.add_quest_entry("Misión iniciada", qname)

func _on_objective_advanced(_qid: String, _oid: String, desc: String) -> void:
	if desc != "":
		_show_notification(desc, Color.GREEN_YELLOW)
		JournalManager.add_quest_entry("Objetivo completado", desc)

func _on_quest_completed(_qid: String, qname: String) -> void:
	_show_notification("\u2B50 \u00a1Misi\u00f3n completada: \"" + qname + "\"!", Color.GOLD)
	JournalManager.add_quest_entry("Misión completada", qname)

func _show_notification(text: String, color: Color) -> void:
	_notif_queue.append({"text": text, "color": color})
	_process_notif_queue()

func _process_notif_queue() -> void:
	if _notif_busy or _notif_queue.is_empty():
		return
	_notif_busy = true
	var entry: Dictionary = _notif_queue.pop_front()
	var parent := get_tree().current_scene
	if not parent or not is_instance_valid(parent):
		_notif_busy = false
		return
	var notif := preload("res://src/menu/quest_notification.tscn").instantiate() as QuestNotification
	if not notif:
		_notif_busy = false
		return
	notif.done.connect(_on_notif_done)
	parent.add_child(notif)
	notif.setup(entry.text, entry.color)

func _on_notif_done() -> void:
	_notif_busy = false
	_process_notif_queue()
