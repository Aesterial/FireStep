extends Node

signal input_mode_changed(mode: String)

var workshop_summary: String = ""
var final_success: bool = false
var final_title: String = ""
var final_body: String = ""
var final_highlights: Array[String] = []

var input_mode: String = "keyboard"
var mouse_sensitivity: float = 0.0026
var gamepad_look_sensitivity: float = 3.0
var gamepad_deadzone: float = 0.2

var start_time_msec: int = 0
var end_time_msec: int = 0
var total_errors: int = 0

func _ready() -> void:
	_ensure_actions()


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
	if full_reset:
		start_time_msec = Time.get_ticks_msec()
		total_errors = 0
	end_time_msec = 0
	workshop_summary = ""
	final_success = false
	final_title = ""
	final_body = ""
	final_highlights = []


func add_error() -> void:
	total_errors += 1


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


func get_prompt_string(text: String) -> String:
	# Strip any existing hardcoded bracket prefixes from old code.
	var clean_text = text
	if clean_text.begins_with("[E] "):
		clean_text = clean_text.substr(4)
	
	if input_mode == "keyboard":
		return "[E] " + clean_text
	else:
		return "[A] " + clean_text
