extends NPC
class_name ProfessorNPC

const SCENARIO_TRIVIA: String = "trivia"
const SCENARIO_WORDLE: String = "wordle"
const ProfessorReplayChoiceScript = preload("res://src/features/menu/features/dialog/professor_replay_choice.gd")

var _pending_scenarios: Array[String] = []
var _show_replay_choice_after_dialog: bool = false


func _ready() -> void:
	super._ready()
	EventBus.dialog_finished.connect(_on_dialog_finished)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	call_deferred("_restore_state")


func _restore_state() -> void:
	Global.normalize_professor_challenge()
	var results: Dictionary = ScoreManager.get_minigame_results()
	if not results.has("trivia") and not results.has("wordle"):
		return

	var enrique := _get_enrique()
	if Global.professor_challenge.get("show_enrique", false) and enrique:
		enrique.visible = true

	if results.has("trivia"):
		_apply_trivia_dialogs_for_outcome(_get_trivia_narrative_outcome(), enrique, true)
	if results.has("wordle") and Global.professor_challenge.get("first_arc_complete", false):
		_apply_wordle_dialogs(bool(results["wordle"].get("passed", false)), enrique, true)


func _on_interact_pressed() -> void:
	if ProfessorReplayChoice.is_active():
		return
	Global.normalize_professor_challenge()
	_prepare_repeat_dialogs()
	super._on_interact_pressed()
	_schedule_pending_scenarios()


func _on_dialog_finished() -> void:
	if _show_replay_choice_after_dialog:
		_show_replay_choice_after_dialog = false
		Global.professor_challenge["replay_sessions"] = int(Global.professor_challenge.get("replay_sessions", 0)) + 1
		SaveManager.mark_dirty()
		_show_replay_choice()
		return

	if _pending_scenarios.is_empty():
		return

	var enrique := _get_enrique()
	if not ScoreManager.get_minigame_results().has("trivia"):
		if enrique:
			enrique.visible = true
		Global.professor_challenge["show_enrique"] = true
		SaveManager.mark_dirty()

	for scenario_id: String in _pending_scenarios:
		_push_scenario_notification(scenario_id)
	_pending_scenarios.clear()


func _on_minigame_completed(game_id: String, success: bool) -> void:
	if game_id != SCENARIO_TRIVIA and game_id != SCENARIO_WORDLE:
		return

	var enrique := _get_enrique()
	Global.professor_challenge["show_enrique"] = true

	if game_id == SCENARIO_TRIVIA:
		var outcome := _get_trivia_narrative_outcome()
		if outcome != "tie":
			Global.professor_challenge["first_arc_complete"] = true
		_apply_trivia_dialogs_for_outcome(outcome, enrique, false)
	elif game_id == SCENARIO_WORDLE:
		Global.professor_challenge["trivia_tied"] = false
		Global.professor_challenge["first_arc_complete"] = true
		_apply_wordle_dialogs(success, enrique, false)

	Global.dialogs_seen.erase("npc_" + name)
	if enrique:
		Global.dialogs_seen.erase("npc_" + enrique.name)
	SaveManager.mark_dirty()


func _schedule_pending_scenarios() -> void:
	_pending_scenarios.clear()
	_show_replay_choice_after_dialog = false
	var results: Dictionary = ScoreManager.get_minigame_results()

	if not results.has("trivia"):
		_pending_scenarios = [SCENARIO_TRIVIA]
		return

	if _is_story_tiebreaker_pending():
		_pending_scenarios = [SCENARIO_WORDLE]
		return

	if not Global.dialogs_seen.has("npc_" + name):
		return

	_show_replay_choice_after_dialog = true


func _is_story_tiebreaker_pending() -> bool:
	return (
		Global.professor_challenge.get("trivia_tied", false)
		and not Global.professor_challenge.get("first_arc_complete", false)
	)


func _show_replay_choice() -> void:
	if ProfessorReplayChoice.is_active():
		return

	var choice: ProfessorReplayChoice = ProfessorReplayChoiceScript.new()
	get_tree().root.add_child(choice)
	choice.option_selected.connect(_on_replay_option_selected)
	choice.open()


func _on_replay_option_selected(scenario_id: String) -> void:
	_push_scenario_notification(scenario_id)


func _prepare_repeat_dialogs() -> void:
	if not Global.dialogs_seen.has("npc_" + name):
		return

	var enrique := _get_enrique()
	var results: Dictionary = ScoreManager.get_minigame_results()
	var replays: int = int(Global.professor_challenge.get("replay_sessions", 0))

	if _is_story_tiebreaker_pending():
		dialog_lines_repeat.assign([
			"El empate sigue sin resolverse.",
			"El director quiere ver el desempate por escrito: abre el Wordle en tu celular cuando estés listo.",
		])
		if enrique:
			enrique.dialog_lines_repeat.assign(_enrique_tie_repeat_lines())
		return

	if not results.has("trivia"):
		return

	var positive_tone := _has_positive_replay_tone()
	dialog_lines_repeat.assign(_professor_replay_lines(positive_tone, replays))
	if enrique:
		enrique.dialog_lines_repeat.assign(_enrique_replay_lines(positive_tone, replays, results))


func _push_scenario_notification(scenario_id: String) -> void:
	match scenario_id:
		SCENARIO_TRIVIA:
			PhoneHud.push_notification(
				"TRIVIA ACADÉMICA",
				_get_trivia_notification_body(),
				true,
				SCENARIO_TRIVIA
			)
		SCENARIO_WORDLE:
			PhoneHud.push_notification(
				_get_wordle_notification_title(),
				_get_wordle_notification_body(),
				true,
				SCENARIO_WORDLE
			)


func _get_trivia_notification_body() -> String:
	var replays: int = int(Global.professor_challenge.get("replay_sessions", 0))
	if replays <= 0:
		return "El profesor Méndez te ha retado.\n[Q] Iniciar Trivia vs Enrique"
	if replays == 1:
		return "Simulacro extra de trivia.\n[Q] Repasar preguntas vs Enrique"
	return "Otra ronda de trivia de práctica.\n[Q] Iniciar Trivia vs Enrique"


func _get_wordle_notification_title() -> String:
	if _is_story_tiebreaker_pending():
		return "DESEMPATE WORDLE"
	return "WORDLE MÉDICO"


func _get_wordle_notification_body() -> String:
	if _is_story_tiebreaker_pending():
		return "Empate en la trivia: desempate obligatorio.\n[Q] Iniciar Wordle vs Enrique"
	var replays: int = int(Global.professor_challenge.get("replay_sessions", 0))
	if replays <= 1:
		return "Práctica de términos médicos.\n[Q] Iniciar Wordle vs Enrique"
	return "Otra sesión de Wordle.\n[Q] Iniciar Wordle vs Enrique"


func _get_trivia_narrative_outcome() -> String:
	var stored := String(Global.professor_challenge.get("last_trivia_result", ""))
	if stored in ["win", "loss", "tie"]:
		return stored

	if Global.last_minigame_outcome.get("game_id") == "trivia":
		var recent := String(Global.last_minigame_outcome.get("result", ""))
		if recent in ["win", "loss", "tie"]:
			return recent

	var results: Dictionary = ScoreManager.get_minigame_results()
	if not results.has("trivia"):
		return ""

	if Global.professor_challenge.get("trivia_tied", false):
		return "tie"
	if bool(results["trivia"].get("passed", false)):
		return "win"
	return "loss"


func _has_positive_replay_tone() -> bool:
	var outcome := _get_trivia_narrative_outcome()
	if outcome == "win":
		return true

	var results: Dictionary = ScoreManager.get_minigame_results()
	if results.has("wordle") and bool(results["wordle"].get("passed", false)):
		return true

	return false


func _apply_trivia_dialogs_for_outcome(outcome: String, enrique: NPC, from_restore: bool) -> void:
	if outcome == "tie" and _is_story_tiebreaker_pending():
		_apply_trivia_dialogs(false, true, enrique, from_restore)
		return
	if outcome == "win" or _has_positive_replay_tone():
		_apply_trivia_dialogs(true, false, enrique, from_restore)
		return
	if outcome == "loss":
		_apply_trivia_dialogs(false, false, enrique, from_restore)
		return

	_apply_trivia_dialogs(false, false, enrique, from_restore)


func _apply_trivia_dialogs(passed: bool, tied: bool, enrique: NPC, from_restore: bool) -> void:
	if tied and not Global.professor_challenge.get("first_arc_complete", false):
		dialog_lines.assign([
			"Cuatro rondas y nadie cayó. Empate técnico.",
			"Para cerrar el reto usaremos el Wordle de términos médicos. Cuando estés listo, habla conmigo y revisa tu celular.",
		])
		dialog_lines_repeat.assign([
			"El desempate sigue pendiente.",
			"Abre el Wordle en tu celular cuando quieras intentarlo.",
		])
		if enrique:
			enrique.dialog_lines.assign([
				"Empate... Eso solo significa que nadie dominó del todo.",
				"En el Wordle no vas a tener tanta suerte.",
			])
			enrique.dialog_lines_repeat.assign(_enrique_tie_repeat_lines())
		return

	if passed:
		dialog_lines.assign([
			"Impresionante. Enrique no pudo contigo en la trivia.",
			"Te ganaste los puntos extra. Si quieres repasar antes del parcial, vuelve a hablar conmigo.",
		])
		dialog_lines_repeat.assign([
			"El coordinador pidió una simulación extra antes del examen de salud.",
			"Elige qué practicar: trivia o Wordle, cada uno por separado.",
		])
		if enrique:
			enrique.dialog_lines.assign([
				"¡Tuviste suerte! Eso es todo...",
				"No me hables, estoy de mal humor.",
			])
			enrique.dialog_lines_repeat.assign([
				"¿Otra trivia? No creo que me ganes dos veces seguidas.",
				"El Wordle también está disponible si quieres practicar vocabulario.",
			])
		return

	dialog_lines.assign([
		"No fue suficiente esta vez. Enrique respondió mejor bajo presión.",
		"Pero equivocarse también enseña. Si quieres intentarlo de nuevo, habla conmigo más tarde.",
	])
	dialog_lines_repeat.assign([
		"La práctica hace al rescatista. El director autorizó repasar los retos.",
		"Elige trivia o Wordle: son modos independientes.",
	])
	if enrique:
		enrique.dialog_lines.assign([
			"Como dije, domino el tema mejor que tú.",
			"Si quieres, yo mismo te doy clases particulares... gratis, claro.",
		])
		enrique.dialog_lines_repeat.assign([
			"¿Vuelves? Esta vez no fallaré.",
			"Puedes practicar trivia o Wordle por tu cuenta.",
		])

	if from_restore:
		return


func _apply_wordle_dialogs(passed: bool, enrique: NPC, from_restore: bool) -> void:
	if passed:
		dialog_lines.assign([
			"Desempate resuelto. Ahora sí puedo decir que ganaste el reto completo.",
			"Buen dominio del vocabulario clínico. Los puntos extra siguen siendo tuyos.",
		])
		dialog_lines_repeat.assign([
			"Si quieres seguir practicando, elige trivia o Wordle por separado.",
			"Repasar no está de más antes del parcial.",
		])
		if enrique:
			enrique.dialog_lines.assign([
				"Esta vez el Wordle se te dio...",
				"La trivia sigue siendo otra historia.",
			])
			enrique.dialog_lines_repeat.assign([
				"Ganaste el desempate, no la guerra.",
				"¿Otra ronda? No me distraigas.",
			])
		return

	dialog_lines.assign([
		"Enrique ganó el Wordle. El desempate no salió a tu favor.",
		"Puedes volver a intentarlo cuando quieras; el aprendizaje importa más que el orgullo.",
	])
	dialog_lines_repeat.assign([
		"Nadie nace sabiendo todos los términos.",
		"Practica trivia o Wordle por separado desde tu celular.",
	])
	if enrique:
		enrique.dialog_lines.assign([
			"¡Sabía que las palabras de cinco letras eran mi terreno!",
			"La próxima vez estudia más.",
		])
		enrique.dialog_lines_repeat.assign([
			"¿Otra oportunidad? Adelante, necesitas la práctica.",
			"No te rindas... o sí, me da igual.",
		])

	if from_restore:
		return


func _professor_replay_lines(positive_tone: bool, replays: int) -> Array[String]:
	if replays <= 1:
		if positive_tone:
			return [
				"Repasar no está de más antes del parcial.",
				"Elige un modo: trivia o Wordle, cada uno por su cuenta.",
			]
		return [
			"Todos fallamos la primera vez. Lo importante es volver a intentarlo.",
			"Te dejaré elegir si practicas trivia o Wordle.",
		]

	return [
		"Otra sesión de práctica, ¿eh?",
		"Elige trivia o Wordle: son independientes.",
	]


func _enrique_replay_lines(positive_tone: bool, replays: int, results: Dictionary) -> Array[String]:
	var wordle_passed := bool(results.get("wordle", {}).get("passed", false)) if results.has("wordle") else false
	var trivia_won := _get_trivia_narrative_outcome() == "win"

	if replays <= 1:
		if positive_tone and trivia_won and wordle_passed:
			return [
				"Ganaste todo... por ahora.",
				"Si vuelves a jugar, no será tan fácil.",
			]
		if positive_tone:
			return [
				"¿Más trivia? No me subestimes otra vez.",
				"El Wordle también está ahí si te atreves.",
			]
		return [
			"¿Regresas? Bien, necesitas la práctica.",
			"Elige lo que quieras practicar.",
		]

	return [
		"Otra vez por aquí... el profe te tiene fichado.",
		"Trivia o Wordle, tú decides.",
	]


func _enrique_tie_repeat_lines() -> Array[String]:
	return [
		"Palabra por palabra te voy a ganar.",
		"¿Nervioso por el desempate?",
	]


func _get_enrique() -> NPC:
	return get_parent().get_node_or_null("Enrique") as NPC
