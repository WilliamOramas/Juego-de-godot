extends Resource
class_name JournalEntry

enum Category { MINIGAME, DIALOG, QUEST, SYSTEM }

@export var timestamp: float = 0.0
@export var category: Category = Category.SYSTEM
@export var title: String = ""
@export var description: String = ""
@export var icon_path: String = ""
