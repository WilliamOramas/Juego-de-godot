extends TextureButton

@export var sound_on_texture: Texture2D = preload("res://src/assets/sprites/sound_on.svg")
@export var sound_off_texture: Texture2D = preload("res://src/assets/sprites/sound_off.svg")

func _ready() -> void:
	pressed.connect(_on_pressed)
	_update_icon()

func _on_pressed() -> void:
	Global.set_mute(!Global.is_muted)
	_update_icon()

func _update_icon() -> void:
	if Global.is_muted:
		texture_normal = sound_off_texture
	else:
		texture_normal = sound_on_texture
