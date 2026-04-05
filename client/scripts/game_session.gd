extends Node

signal input_mode_changed(mode: String)

const AUTH_SCENE_PATH := "res://scenes/Auth.tscn"
const SESSION_STATE_PATH := "user://firestep_session.json"
const PENDING_SEANCE_PATH := "user://firestep_pending_seance.json"

var workshop_summary: String = ""
var final_success: bool = false
var final_title: String = ""
var final_body: String = ""
var final_highlights: Array[String] = []
var save_status_text: String = ""

var input_mode: String = "keyboard"
var mouse_sensitivity: float = 0.0026
var gamepad_look_sensitivity: float = 3.0
var gamepad_deadzone: float = 0.2

var start_time_msec: int = 0
var start_time_unix_msec: int = 0
var end_time_msec: int = 0
var end_time_unix_msec: int = 0
var total_errors: int = 0
var action_log: Array[Dictionary] = []
var next_action_id: int = 1
var session_token: String = ""
var session_verified: bool = false
var user_profile: Dictionary = {}


func _ready() -> void:
	_ensure_actions()
	load_auth_state()


func _input(event: InputEvent) -> void:
	var new_mode = input_mode
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		new_mode = "keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.2:
			return
		new_mode = "gamepad"

	if new_mode != input_mode:
		input_mode = new_mode
		input_mode_changed.emit(input_mode)


func _add_key(action: String, keycode: int) -> void:
	var ev = InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_joy_button(action: String, button: int) -> void:
	var ev = InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func _add_joy_axis(action: String, axis: int, dir: float) -> void:
	var ev = InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = dir
	InputMap.action_add_event(action, ev)


func _ensure_actions() -> void:
	var action_names = ["move_forward", "move_back", "move_left", "move_right", "look_up", "look_down", "look_left", "look_right", "interact", "sprint", "toggle_pointer", "restart_scene", "ui_accept"]
	for a in action_names:
		if not InputMap.has_action(a):
			InputMap.add_action(a, gamepad_deadzone)
		else:
			InputMap.action_set_deadzone(a, gamepad_deadzone)

	_add_key("move_forward", KEY_W)
	_add_key("move_back", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)

	_add_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)

	_add_joy_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_joy_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_add_joy_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)

	_add_key("interact", KEY_E)
	_add_joy_button("interact", JOY_BUTTON_A)

	_add_key("sprint", KEY_SHIFT)
	_add_joy_button("sprint", JOY_BUTTON_LEFT_STICK)

	_add_key("toggle_pointer", KEY_ESCAPE)
	_add_joy_button("toggle_pointer", JOY_BUTTON_START)

	_add_key("restart_scene", KEY_R)
	_add_joy_button("restart_scene", JOY_BUTTON_Y)

	_add_key("ui_accept", KEY_ENTER)
	_add_key("ui_accept", KEY_SPACE)
	_add_joy_button("ui_accept", JOY_BUTTON_A)


func reset_session(full_reset: bool = false) -> void:
	if full_reset or start_time_msec == 0:
		start_time_msec = Time.get_ticks_msec()
		start_time_unix_msec = _now_unix_msec()
		total_errors = 0
		action_log = []
		next_action_id = 1
		_clear_pending_seance_file()

	end_time_msec = 0
	end_time_unix_msec = 0
	workshop_summary = ""
	final_success = false
	final_title = ""
	final_body = ""
	final_highlights = []
	save_status_text = ""


func add_error() -> void:
	total_errors += 1
	record_action("scenario/error_detected")


func get_elapsed_time_string() -> String:
	var elapsed = Time.get_ticks_msec() - start_time_msec
	var seconds = elapsed / 1000
	var minutes = seconds / 60
	seconds = seconds % 60
	return "%d:%02d" % [minutes, seconds]


func set_workshop_summary(summary: String) -> void:
	workshop_summary = summary


func set_final_result(success: bool, title: String, body: String, highlights: Array[String]) -> void:
	final_success = success
	final_title = title
	final_body = body
	final_highlights = highlights.duplicate()
	end_time_msec = Time.get_ticks_msec()
	end_time_unix_msec = _now_unix_msec()
	record_action("scenario/result/%s" % ("success" if success else "failure"))
	_submit_finished_seance()


func get_prompt_string(text: String) -> String:
	var clean_text = text
	if clean_text.begins_with("[E] "):
		clean_text = clean_text.substr(4)

	if input_mode == "keyboard":
		return "[E] " + clean_text
	else:
		return "[A] " + clean_text


func ensure_authenticated(tree: SceneTree) -> bool:
	if is_authenticated():
		return true

	tree.change_scene_to_file(AUTH_SCENE_PATH)
	return false


func is_authenticated() -> bool:
	return session_verified and not session_token.is_empty()


func apply_authenticated_session(token: String, profile: Dictionary) -> void:
	session_token = token.strip_edges()
	session_verified = not session_token.is_empty()
	user_profile = profile.duplicate(true)
	save_auth_state()


func clear_authenticated_session() -> void:
	session_token = ""
	session_verified = false
	user_profile = {}
	save_auth_state()


func load_auth_state() -> void:
	if not FileAccess.file_exists(SESSION_STATE_PATH):
		return

	var file := FileAccess.open(SESSION_STATE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	session_token = str(parsed.get("sessionToken", ""))
	session_verified = not session_token.is_empty()
	var profile = parsed.get("user", {})
	user_profile = profile.duplicate(true) if typeof(profile) == TYPE_DICTIONARY else {}


func save_auth_state() -> void:
	var file := FileAccess.open(SESSION_STATE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify({
		"sessionToken": session_token,
		"user": user_profile,
	}))


func record_action(action_name: String) -> void:
	if start_time_unix_msec <= 0:
		return

	action_log.append({
		"id": next_action_id,
		"action": action_name,
		"atUnixMs": _now_unix_msec(),
	})
	next_action_id += 1
	_persist_pending_seance(end_time_unix_msec > 0)


func flush_pending_seance() -> void:
	if not is_authenticated():
		return
	if not FileAccess.file_exists(PENDING_SEANCE_PATH):
		return

	var file := FileAccess.open(PENDING_SEANCE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if int(parsed.get("doneAtUnixMs", 0)) <= 0:
		return

	parsed["sessionToken"] = session_token
	file = FileAccess.open(PENDING_SEANCE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(parsed))

	var response = ApiClient.save_seance(PENDING_SEANCE_PATH)
	if response.get("success", false):
		save_status_text = "Прохождение синхронизировано."
		_clear_pending_seance_file()
	else:
		save_status_text = "Не удалось досохранить прошлую сессию: %s" % str(response.get("error", "unknown error"))


func _submit_finished_seance() -> void:
	_persist_pending_seance(true)

	if not is_authenticated():
		save_status_text = "Сессия сохранена локально. После повторной авторизации данные можно синхронизировать."
		return

	var response = ApiClient.save_seance(PENDING_SEANCE_PATH)
	if response.get("success", false):
		save_status_text = "Прохождение синхронизировано."
		_clear_pending_seance_file()
	else:
		save_status_text = "Ошибка синхронизации: %s. Данные оставлены локально." % str(response.get("error", "unknown error"))


func _persist_pending_seance(finalized: bool) -> void:
	if start_time_unix_msec <= 0:
		return

	var done_at := end_time_unix_msec if finalized else 0
	var file := FileAccess.open(PENDING_SEANCE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify({
		"sessionToken": session_token,
		"errors": total_errors,
		"startedAtUnixMs": start_time_unix_msec,
		"doneAtUnixMs": done_at,
		"actions": action_log,
	}))


func _clear_pending_seance_file() -> void:
	if FileAccess.file_exists(PENDING_SEANCE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING_SEANCE_PATH))


func _now_unix_msec() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
