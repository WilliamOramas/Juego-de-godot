extends NPC
class_name ProfessorNPC

var _waiting_for_trivia: bool = false
var _trivia_done: bool = false

func _ready() -> void:
	super._ready()
	EventBus.dialog_finished.connect(_on_dialog_finished)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	call_deferred("_restore_trivia_state")

func _restore_trivia_state() -> void:
	var results: Dictionary = ScoreManager.get_minigame_results()
	if results.has("trivia"):
		_trivia_done = true
		var enrique: NPC = get_parent().get_node_or_null("Enrique") as NPC
		_update_dialogs(results["trivia"]["passed"], enrique)

func _on_interact_pressed() -> void:
	super._on_interact_pressed()
	if not _trivia_done:
		_waiting_for_trivia = true

func _on_dialog_finished() -> void:
	if _waiting_for_trivia:
		_waiting_for_trivia = false
		
		# Hacemos aparecer a Enrique en la escena mágicamente
		var enrique: NPC = get_parent().get_node_or_null("Enrique") as NPC
		if enrique:
			enrique.visible = true
			
		# Empujamos la notificación del escenario "trivia" al celular
		# Esto obligará al jugador a abrir el celular o presionar [Q] para iniciar
		PhoneHud.push_notification("TRIVIA ACADÉMICA", "El profesor Méndez te ha retado.\n[Q] Iniciar Trivia vs Enrique", true, "trivia")

func _on_minigame_completed(game_id: String, success: bool) -> void:
	if game_id == "trivia":
		_trivia_done = true
		var enrique: NPC = get_parent().get_node_or_null("Enrique") as NPC
		_update_dialogs(success, enrique)
		
		# Resetear el estado para que digan las nuevas líneas principales la primera vez que les hables tras jugar
		Global.dialogs_seen.erase("npc_" + self.name)
		if enrique:
			Global.dialogs_seen.erase("npc_" + enrique.name)

func _update_dialogs(success: bool, enrique: NPC) -> void:
	if success:
		# El jugador ganó
		self.dialog_lines.assign(["Parece ser que Enrique estudia menos que tú. Me sorprende, pero te mereces esos puntos."])
		self.dialog_lines_repeat.assign(["Ya demostraste lo que sabes. Vuelve a tu asiento."])
		
		if enrique:
			enrique.dialog_lines.assign(["¡Tuviste suerte! Eso es todo...", "No me hables, estoy de mal humor."])
			enrique.dialog_lines_repeat.assign(["Déjame en paz."])
	else:
		# El jugador perdió
		self.dialog_lines.assign(["No me digas que quieres una revancha. Creo que el resultado quedó claro.", "Vuelve a tu asiento, Enrique demostró ser mejor."])
		self.dialog_lines_repeat.assign(["El resultado fue claro, no hay revanchas."])
		
		if enrique:
			enrique.dialog_lines.assign(["Como dije, soy un verdadero experto en el tema.", "Si quieres, yo mismo te doy clases para que aprendas algo."])
			enrique.dialog_lines_repeat.assign(["¿Necesitas que te explique de nuevo cómo funciona? ¡Jaja!"])
