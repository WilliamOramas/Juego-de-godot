class_name CloudSaveMapper
extends RefCounted

static func extract_completed_scenarios(completed: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(completed) != TYPE_DICTIONARY:
		return result
	var completed_dict := completed as Dictionary
	for key: Variant in completed_dict.keys():
		if completed_dict[key]:
			result.append(String(key))
	result.sort()
	return result


static func extract_slot_summary(user_id: String, slot: int, slot_data: Dictionary) -> Dictionary:
	var score_stats: Dictionary = slot_data.get("score_stats", {}) as Dictionary
	var completed: Dictionary = slot_data.get("completed_scenarios", {}) as Dictionary
	return {
		"user_id": user_id,
		"slot": slot,
		"ultima_escena": String(slot_data.get("last_scene", "")),
		"puntaje": int(score_stats.get("score", 0)),
		"escenarios_completados": extract_completed_scenarios(completed),
		"quests_completadas": int(score_stats.get("quests_completed", 0)),
	}


static func extract_all_slots(save_data: Dictionary, user_id: String) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for key: String in save_data.keys():
		if not key.begins_with("slot_"):
			continue
		var slot_value: Variant = save_data[key]
		if typeof(slot_value) != TYPE_DICTIONARY:
			continue
		var slot_num := int(key.trim_prefix("slot_"))
		summaries.append(extract_slot_summary(user_id, slot_num, slot_value as Dictionary))
	summaries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	return summaries
