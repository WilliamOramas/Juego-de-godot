class_name GameProtocol
extends RefCounted

const ESCENARIO_DESMAYO: int = 1
const ESCENARIO_RCP: int = 2
const ESCENARIO_TRIVIA: int = 3

const STEPS_DESMAYO: Array[String] = [
	"Verificar respuesta del paciente",
	"Verificar respiración",
	"Palpar pulso carotídeo",
	"Llamar al 112",
	"Elevar piernas",
	"Aflojar ropa ajustada",
	"Monitorear signos vitales",
]

const STEPS_RCP: Array[String] = [
	"Verificar escena segura",
	"30 compresiones torácicas",
	"2 respiraciones de rescate",
	"Ciclo completo 30:2",
	"Llamar al 112",
]

const STEPS_TRIVIA: Array[String] = [
	"Respuesta correcta a la trivia",
	"Respuesta incorrecta a la trivia",
	"Acierto Wordle",
	"Fallo Wordle",
]

const VALID_SESSION_RESULTS: Array[String] = ["Salvado", "Fallecido"]


static func get_protocol_steps(id_escenario: int) -> Array[String]:
	match id_escenario:
		ESCENARIO_DESMAYO:
			return STEPS_DESMAYO.duplicate()
		ESCENARIO_RCP:
			return STEPS_RCP.duplicate()
		ESCENARIO_TRIVIA:
			return STEPS_TRIVIA.duplicate()
		_:
			return []


static func resolve_session_result(success: bool, student_died: bool) -> String:
	if success and not student_died:
		return "Salvado"
	return "Fallecido"


static func collect_step_actions(step_data: Array) -> Array[String]:
	var actions: Array[String] = []
	for step_variant: Variant in step_data:
		if typeof(step_variant) != TYPE_DICTIONARY:
			continue
		var step := step_variant as Dictionary
		if step.has("protocolo_accion"):
			actions.append(String(step["protocolo_accion"]))
	return actions
