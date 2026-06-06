extends PanelContainer
class_name InteractPrompt

var _on_interact_callback: Callable
var _float_tween: Tween = null

@onready var prompt_texture: TextureRect = %PromptTexture

func setup(on_interact: Callable) -> void:
	_on_interact_callback = on_interact

	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, AnimHelper.PROMPT_POP_IN)
	tween.tween_callback(_start_float)

func _start_float() -> void:
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(self, "position:y", position.y - 6, AnimHelper.PROMPT_FLOAT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(self, "position:y", position.y + 6, AnimHelper.PROMPT_FLOAT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_interact_pressed() -> void:
	if _on_interact_callback.is_valid():
		_on_interact_callback.call()

func set_button_visible(is_shown: bool) -> void:
	prompt_texture.visible = is_shown

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and prompt_texture.visible and not DialogBox.is_open:
			_on_interact_pressed()
			get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _float_tween:
		_float_tween.kill()
		_float_tween = null
