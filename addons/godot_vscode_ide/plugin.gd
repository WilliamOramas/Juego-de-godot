@tool
class_name GodotVSCodePlugin
extends EditorPlugin

const VSCODE_WEBVIEW_SCENE := preload("res://addons/godot_vscode_ide/vscode_webview.tscn")
const VSCODE_ICON := preload("res://addons/godot_vscode_ide/vscode-alt.svg")

var webview: VSCodeWebView
var output_timer: Timer = null
var main_loaded := false
var distraction_free_enabled_by_us := false
# Tunnel/process capture
var tunnel_process := {}
var tunnel_stdio: FileAccess = null
var tunnel_stderr: FileAccess = null
var _tunnel_in_url := false
var _tunnel_building_url := ""

func _enter_tree() -> void:
	_kill_all_tunnels()
	_setup_webview()
	_setup_menu_items()
	_auto_start_tunnel()

func _setup_webview() -> void:
	webview = VSCODE_WEBVIEW_SCENE.instantiate()
	if not webview:
		push_error("[VSCode] Failed to instantiate vscode_webview.tscn")
		return
	webview.visible = false
	webview.focus_mode = Control.FOCUS_ALL
	webview.update_url_from_project_settings()

	webview.ipc_message.connect(_on_ipc_message_main)
	webview.gui_input.connect(_on_webview_gui_input)

	get_editor_interface().get_editor_main_screen().add_child(webview)

func _setup_menu_items() -> void:
	add_tool_menu_item("Open developer tools", _open_dev_tools)
	add_tool_menu_item("Refresh VSCode view", _refresh_webview)
	add_tool_menu_item("Start tunnel", _start_code_tunnel)
	add_tool_menu_item("Stop tunnels", _kill_all_tunnels)

func _auto_start_tunnel() -> void:
	if ProjectSettings.get_setting("editor/ide/auto_start_tunnel", false):
		_start_code_tunnel()

func _handles(object: Object) -> bool:
	if object is Script:
		EditorInterface.set_main_screen_editor("Script")
	return object is Script

func _exit_tree():
	_kill_all_tunnels()
	remove_tool_menu_item("Open developer tools")
	remove_tool_menu_item("Refresh VSCode view")
	remove_tool_menu_item("Start tunnel")
	remove_tool_menu_item("Stop tunnels")
	if webview:
		webview.queue_free()
		webview = null

func _get_plugin_name() -> String:
	return "Code"

func _get_plugin_icon() -> Texture2D:
	return VSCODE_ICON

func _has_main_screen() -> bool:
	return true

func _make_visible(p_visible: bool) -> void:
	if not webview:
		return
	webview.update_url_from_project_settings()
	_initialize_webview_lazy()

	webview.visible = p_visible
	webview.grab_click_focus()
	webview.grab_focus()
	_handle_distraction_free_mode(p_visible)

func _initialize_webview_lazy() -> void:
	if main_loaded:
		return
	main_loaded = true
	webview.create_webview()

func _handle_distraction_free_mode(visible: bool) -> void:
	if not ProjectSettings.get_setting("editor/ide/distraction_free_mode", false):
		return
	var editor_interface := get_editor_interface()
	if visible:
		_enable_distraction_free(editor_interface)
	else:
		_disable_distraction_free(editor_interface)

func _enable_distraction_free(editor_interface: EditorInterface) -> void:
	if editor_interface.is_distraction_free_mode_enabled():
		return
	editor_interface.set_distraction_free_mode(true)
	distraction_free_enabled_by_us = true

func _disable_distraction_free(editor_interface: EditorInterface) -> void:
	if not distraction_free_enabled_by_us:
		return
	editor_interface.set_distraction_free_mode(false)
	distraction_free_enabled_by_us = false

func _refresh_webview() -> void:
	if webview and main_loaded:
		webview.reload()

func _on_ipc_message_main(message: String) -> void:
	if webview and main_loaded:
		webview.grab_click_focus()
		webview.grab_focus()

func _on_resource_selected(p_res: Resource, _p_property: String) -> void:
	if p_res is Script and p_res.resource_path != "":
		_open_script_in_vscode(p_res.resource_path)

func _on_script_open_request(p_script: Script) -> void:
	if p_script and p_script.resource_path != "":
		_open_script_in_vscode(p_script.resource_path)

func _process(delta: float) -> void:
	if webview:
		webview.update_webview()
	_update_tunnel_process()

func _update_tunnel_process() -> void:
	if tunnel_process.is_empty():
		return
	var stdio_text := tunnel_stdio.get_as_text()
	if stdio_text != "":
		_extract_vscode_url(stdio_text)

	var stderr_text := tunnel_stderr.get_as_text()
	if stderr_text != "":
		print("[VSCode] Error from tunnel: ", stderr_text)

func _extract_vscode_url(text: String) -> void:
	for line in text.split("\n"):
		_process_tunnel_chunk(line.strip_edges())

func _process_tunnel_chunk(chunk: String) -> void:
	print("[VSCode] ", chunk)
	
	if not _tunnel_in_url and chunk.find("https://vscode.dev/tunnel/") != -1:
		_tunnel_in_url = true
		_tunnel_building_url = ""
		var start_pos := chunk.find("https://vscode.dev/tunnel/")
		_tunnel_building_url += chunk.substr(start_pos) if start_pos != -1 else ""
		return
		
	if _tunnel_in_url and chunk.is_empty():
		var clean_url := _tunnel_building_url.strip_edges()
		print("[VSCode] Found tunnel at: ", clean_url)
		ProjectSettings.set_setting("editor/ide/vscode_url", clean_url)
		ProjectSettings.save()
		webview.update_url_from_project_settings()
		_tunnel_in_url = false
		_tunnel_building_url = ""
		return

	if _tunnel_in_url:
		_tunnel_building_url += chunk

func _cleanup_tunnel() -> void:
	_cleanup_output_timer()
	_kill_tunnel_pid()
	set_process(false)
	tunnel_process = {}
	tunnel_stdio = null
	tunnel_stderr = null

func _cleanup_output_timer() -> void:
	if not (output_timer and output_timer.is_inside_tree()):
		return
	output_timer.stop()
	output_timer.queue_free()
	output_timer = null

func _kill_tunnel_pid() -> void:
	var pid := int(tunnel_process.get("pid", -1))
	if pid == -1:
		return
	print("[VSCode] Killing tunnel with PID ", pid)
	OS.kill(pid)

func _kill_all_tunnels() -> void:
	var os_name = OS.get_name()
	print("[VSCode] Killing all VSCode tunnel processes on ", os_name)
	var result := []
	if os_name == "Windows":
		# Use PowerShell to find processes whose command line contains "code" and "tunnel" and terminate them.
		var ps_cmd = "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'code(\\.exe)?\\s+tunnel' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
		OS.execute("powershell", ["-NoProfile", "-Command", ps_cmd], result, true)
	else:
		# macOS/Linux: list and kill processes whose command line contains "code" and "tunnel".
		var output: Array = []
		var exit_code = OS.execute("ps", ["-axo", "pid=,command="], output, true)
		if exit_code != 0 or output.is_empty():
			print("[VSCode] Failed to list processes via ps.")
			return
		var output_text = str(output[0])
		var killed_any := false
		for line in output_text.split("\n"):
			var trimmed = line.strip_edges()
			if trimmed == "":
				continue
			var parts = trimmed.split(" ", false, 1)
			if parts.size() < 2:
				continue
			var pid_str = parts[0].strip_edges()
			var cmd = parts[1]
			var is_tunnel = (cmd.find("tunnel") != -1) and (cmd.find("code") != -1 or cmd.find("code-tunnel") != -1)
			if not is_tunnel:
				continue
			var pid = int(pid_str)
			print("[VSCode] Killing tunnel PID ", pid, ": ", cmd)
			OS.execute("kill", ["-9", str(pid)], [], true)
			killed_any = true
		if not killed_any:
			print("[VSCode] No tunnel processes found via ps.")
	for line in result:
		print("[VSCode] ", line)
	_cleanup_tunnel()

func _open_script_in_vscode(_script_path: String) -> void:
	# Esta función es un placeholder para futuras integraciones de apertura de archivos.
	# Actualmente, el editor de VSCode se sincroniza vía vscode.dev y el túnel de puertos.
	pass

func _start_code_tunnel() -> void:
	if !tunnel_process.is_empty():
		return

	var args = ["tunnel", "--accept-server-license-terms"]
	var process = _get_tunnel_process(args)
	if process.has("pid") and process.has("stdio"):
		tunnel_process = process
		tunnel_stdio = process["stdio"]
		tunnel_stderr = process["stderr"]
		set_process(true)
		print("[VSCode] Tunnel started with pid %d; capturing output..." % process["pid"])
	else:
		push_error("[VSCode] Failed to start VSCode tunnel (execute_with_pipe did not provide stdio)")

func _get_tunnel_process(args: Array):
	# Use execute_with_pipe to capture stdio/stderr handles (non-blocking)
	if OS.get_name() == "Windows":
		var code_path = _get_vscode_path_windows()
		if code_path == "":
			push_error("[VSCode] 'code' command not found in PATH.")
			return
		return OS.execute_with_pipe(code_path, args, false)
	else:
		return OS.execute_with_pipe("code", args, false)
			
func _get_vscode_path_windows() -> String:
	# Search the Windows PATH for the code command
	var output = []
	var exit_code = OS.execute("cmd.exe", ["/c", "where", "code"], output)
	if exit_code == 0 and output.size() > 0:
		var lines = output[0].split("\r\n")
		for line in lines:
			var path = line.strip_edges()
			if path.ends_with('.cmd'):
				print("[VSCode] Found executable at: ", path)
				return path
	return ""
	
func _open_dev_tools() -> void:
	if not webview:
		push_error("[VSCode] IDE: Main screen webview not available")
		return
	if not main_loaded:
		push_error("[VSCode] IDE: Main screen webview not loaded yet")
		return
	webview.open_devtools()

func _on_webview_gui_input(event: InputEvent) -> void:
	if event:
		# Prevent event propagation
		if get_viewport():
			get_viewport().set_input_as_handled()
