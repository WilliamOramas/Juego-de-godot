class_name AiProvider
extends Node

## AiProvider
## Interfaz abstracta para proveedores de Inteligencia Artificial (Strategy Pattern).

# Se emite internamente para que AiClient pueda propagar el evento
@warning_ignore("unused_signal")
signal request_completed(success: bool, response_text: String, error_msg: String, custom_callback: Callable, npc_name: String)

func is_configured() -> bool:
	return false

func generate_npc_response(_npc_name: String, _system_prompt: String, _history: Array[AIMessage]) -> void:
	push_error("generate_npc_response() no implementado en el proveedor de IA.")

func generate_content(_system_prompt: String, _user_message: String, _generation_config: Dictionary, _callback: Callable) -> void:
	push_error("generate_content() no implementado en el proveedor de IA.")

func cancel_requests() -> void:
	pass
