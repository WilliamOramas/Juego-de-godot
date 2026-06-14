extends Node
class_name AnimHelper

# --- Panel Fade ---
const FADE_IN_DURATION := 0.15
const FADE_OUT_DURATION := 0.1

# --- Dialog Box ---
const DIALOG_SLIDE_IN := 0.3
const DIALOG_SLIDE_OUT := 0.25
const BLINK_SPEED := 0.5

# --- Scene Transition ---
const SCENE_FADE_OUT := 0.25
const SCENE_FADE_IN := 0.3

# --- Wipe Effect ---
const WIPE_IN_DURATION := 0.6
const WIPE_PAUSE := 0.3
const WIPE_OUT_DURATION := 0.6

# --- Player ---
const PLAYER_APPROACH := 1.2

# --- Interaction Prompt ---
const PROMPT_POP_IN := 0.25
const PROMPT_FLOAT := 1.2

static func fade_in(control: Control, duration: float = FADE_IN_DURATION) -> Tween:
	control.visible = true
	var tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)
	return tween

static func fade_out(control: Control, duration: float = FADE_OUT_DURATION, on_finished: Callable = Callable()) -> Tween:
	var tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 0.0, duration)
	if on_finished.is_valid():
		tween.tween_callback(on_finished)
	return tween
