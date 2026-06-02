extends Resource
class_name QuestObjective

enum ObjectiveType {
	TALK_TO_NPC,
	REACH_SCENE,
	COMPLETE_MINIGAME,
	CUSTOM,
}

@export var objective_id: String = ""
@export var description: String = ""
@export var type: ObjectiveType = ObjectiveType.TALK_TO_NPC
@export var target_id: String = ""
@export var is_optional: bool = false
