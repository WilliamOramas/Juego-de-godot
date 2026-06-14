class_name AIMessage
extends RefCounted

enum Role {
	SYSTEM,
	USER,
	ASSISTANT
}

var role: Role
var content: String

func _init(_role: Role = Role.USER, _content: String = "") -> void:
	role = _role
	content = _content

func get_role_string() -> String:
	match role:
		Role.SYSTEM:
			return "system"
		Role.USER:
			return "user"
		Role.ASSISTANT:
			return "assistant"
		_:
			return "user"
