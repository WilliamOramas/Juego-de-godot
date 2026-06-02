extends Node

var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

func _ready() -> void:
	EventBus.scene_changed.connect(_on_scene_changed)

func start_quest(quest_data: Variant) -> void:
	if quest_data == null:
		return
	if active_quests.has(quest_data.quest_id) or completed_quests.has(quest_data.quest_id):
		return
	var objectives: Dictionary = {}
	for obj in quest_data.objectives:
		objectives[obj.objective_id] = false
	active_quests[quest_data.quest_id] = {
		"quest_data": quest_data,
		"objectives": objectives,
	}
	SaveManager.mark_dirty()

func advance_objective(quest_id: String, objective_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var quest: Dictionary = active_quests[quest_id]
	if not quest.objectives.has(objective_id):
		return
	quest.objectives[objective_id] = true
	SaveManager.mark_dirty()
	if _are_all_objectives_done(quest):
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	completed_quests[quest_id] = true
	active_quests.erase(quest_id)
	SaveManager.mark_dirty()

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

func _are_all_objectives_done(quest: Dictionary) -> bool:
	for obj_id in quest.objectives:
		if not quest.objectives[obj_id]:
			return false
	return true

func _on_scene_changed(scene_path: String) -> void:
	for quest_id in active_quests:
		var quest: Dictionary = active_quests[quest_id]
		var qdata: Variant = quest.get("quest_data")
		if not qdata:
			continue
		for obj in qdata.objectives:
			if quest.objectives.get(obj.objective_id, false):
				continue
			if obj.type == QuestObjective.ObjectiveType.REACH_SCENE and obj.target_id == scene_path:
				advance_objective(quest_id, obj.objective_id)

func _load_quest_data(quest_id: String) -> Variant:
	return null
