extends Area3D
class_name Interactable

@export var action_id: String = ""
@export var prompt_text: String = "Нажмите E для взаимодействия"
@export var active: bool = true


func _ready() -> void:
	input_ray_pickable = active
	monitoring = active
	monitorable = active


func set_active(value: bool) -> void:
	active = value
	input_ray_pickable = value
	monitoring = value
	monitorable = value


func get_prompt() -> String:
	if not active:
		return ""
	return prompt_text
