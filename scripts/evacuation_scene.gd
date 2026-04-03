extends Node3D

const Interactable = preload("res://scripts/interactable.gd")

@export var corridor_visual_scene: PackedScene
@export var assembly_visual_scene: PackedScene
@export var wall_material: StandardMaterial3D
@export var floor_material: StandardMaterial3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var assembly_terminal: Interactable
var danger_door: Interactable
var assembly_light: OmniLight3D


func _ready() -> void:
	_configure_player_spawn()
	_configure_environment()
	_build_world()
	_connect_signals()
	_setup_hud()


func _configure_player_spawn() -> void:
	player.global_position = Vector3(0.0, 0.0, 6.0)
	player.rotation_degrees = Vector3(0.0, 180.0, 0.0)


func _configure_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.07, 0.08, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.68, 0.74)
	environment.ambient_light_energy = 1.1
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment


func _build_world() -> void:
	var root := Node3D.new()
	root.name = "WorldRoot"
	add_child(root)

	root.add_child(_make_box_body("Floor", Vector3(12.0, 0.2, 18.0), Vector3(0.0, -0.1, 0.0), Color(0.2, 0.22, 0.25)))
	root.add_child(_make_box_body("LeftWall", Vector3(0.3, 3.6, 18.0), Vector3(-6.0, 1.8, 0.0), Color(0.24, 0.25, 0.28)))
	root.add_child(_make_box_body("RightWall", Vector3(0.3, 3.6, 18.0), Vector3(6.0, 1.8, 0.0), Color(0.24, 0.25, 0.28)))
	root.add_child(_make_box_body("BackWall", Vector3(12.0, 3.6, 0.3), Vector3(0.0, 1.8, 8.9), Color(0.26, 0.26, 0.31)))

	var gate_frame := _make_box_body("GateFrame", Vector3(12.0, 0.5, 0.3), Vector3(0.0, 3.2, -8.9), Color(0.22, 0.23, 0.26))
	root.add_child(gate_frame)
	root.add_child(_make_box_body("GateSideLeft", Vector3(1.5, 3.6, 0.3), Vector3(-5.25, 1.8, -8.9), Color(0.22, 0.23, 0.26)))
	root.add_child(_make_box_body("GateSideRight", Vector3(1.5, 3.6, 0.3), Vector3(5.25, 1.8, -8.9), Color(0.22, 0.23, 0.26)))

	root.add_child(_make_visual_box(Vector3(1.8, 0.04, 12.0), Vector3(0.0, 0.02, 0.5), Color(0.16, 0.68, 0.28), true))
	root.add_child(_make_visual_box(Vector3(3.8, 0.04, 0.36), Vector3(0.0, 0.02, -5.7), Color(0.16, 0.68, 0.28), true))
	root.add_child(_make_visual_box(Vector3(2.2, 0.04, 2.2), Vector3(0.0, 0.02, -7.0), Color(0.16, 0.68, 0.28), true))

	root.add_child(_make_label("Маршрут эвакуации", Vector3(0.0, 2.8, 3.8), Color(0.96, 0.95, 0.86)))
	root.add_child(_make_label("Пункт сбора", Vector3(0.0, 1.0, -7.0), Color(0.78, 1.0, 0.82)))
	root.add_child(_make_label("Назад к цеху", Vector3(4.2, 2.1, 2.8), Color(1.0, 0.82, 0.82)))

	if corridor_visual_scene != null:
		var corridor_visual := corridor_visual_scene.instantiate()
		root.add_child(corridor_visual)

	if assembly_visual_scene != null:
		var assembly_visual := assembly_visual_scene.instantiate()
		root.add_child(assembly_visual)

	assembly_light = OmniLight3D.new()
	assembly_light.position = Vector3(0.0, 2.2, -7.0)
	assembly_light.light_color = Color(0.24, 0.95, 0.4)
	assembly_light.light_energy = 4.6
	assembly_light.omni_range = 6.0
	root.add_child(assembly_light)

	assembly_terminal = _make_interactable_panel(
		"AssemblyTerminal",
		"assembly",
		"[E] Подтвердить эвакуацию",
		Vector3(0.0, 1.1, -7.0),
		Vector3(0.5, 0.7, 0.3),
		Color(0.18, 0.72, 0.28),
		"СБОР"
	)
	root.add_child(assembly_terminal)

	danger_door = _make_interactable_panel(
		"DangerDoor",
		"danger",
		"[E] Вернуться к оборудованию",
		Vector3(4.6, 1.2, 2.8),
		Vector3(0.3, 0.8, 1.0),
		Color(0.82, 0.18, 0.12),
		"ОПАСНО"
	)
	root.add_child(danger_door)

	root.add_child(_make_box_body("DangerDoorFrame", Vector3(0.2, 2.4, 1.6), Vector3(4.9, 1.2, 2.8), Color(0.18, 0.18, 0.2)))


func _connect_signals() -> void:
	player.prompt_changed.connect(hud.set_interaction_prompt)
	player.interact_requested.connect(_on_player_interact)


func _setup_hud() -> void:
	hud.set_objective("5. Пройдите к пункту сбора и подтвердите эвакуацию.")
	hud.set_hint("Следуйте по зелёной разметке. Не возвращайтесь в опасную зону.")
	hud.set_warning_banner("[ЭВАКУАЦИЯ] Двигайтесь к безопасной точке сбора.", "warning")
	hud.show_feedback("Этап эвакуации начался. Завершите маршрут и отметьтесь на пункте сбора.", "info")


func _on_player_interact(interactable: Interactable) -> void:
	match interactable.action_id:
		"assembly":
			_complete_success()
		"danger":
			_complete_failure(
				"Тренировка не пройдена",
				"Возврат к оборудованию после начала эвакуации создал лишний риск для человека."
			)


func _complete_success() -> void:
	GameSession.set_final_result(
		true,
		"Тренировка пройдена",
		"Вы остановили оборудование, создали дистанцию, вызвали помощь и завершили эвакуацию на пункте сбора.",
		[
			"Аварийная остановка выполнена",
			"Безопасная дистанция соблюдена",
			"Помощь вызвана до выхода из зоны риска",
			"Эвакуация завершена в пункте сбора"
		]
	)
	get_tree().change_scene_to_file("res://scenes/Debrief.tscn")


func _complete_failure(title: String, body: String) -> void:
	GameSession.set_final_result(
		false,
		title,
		body,
		[
			"Ошибка: выбран возврат в опасную зону",
			"Приоритет безопасности людей нарушен"
		]
	)
	get_tree().change_scene_to_file("res://scenes/Debrief.tscn")


func _make_box_body(name: String, size: Vector3, position: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh

	var material: StandardMaterial3D
	if name == "Floor" and floor_material != null:
		material = floor_material
	elif name.contains("Wall") and wall_material != null:
		material = wall_material
	else:
		material = StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.92

	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	return body


func _make_visual_box(size: Vector3, position: Vector3, color: Color, emissive: bool) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.0
	mesh_instance.material_override = material
	return mesh_instance


func _make_interactable_panel(
	name: String,
	action_id: String,
	prompt_text: String,
	position: Vector3,
	size: Vector3,
	color: Color,
	label_text: String
) -> Interactable:
	var area := Interactable.new()
	area.name = name
	area.action_id = action_id
	area.prompt_text = prompt_text
	area.position = position

	var collision := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = size
	collision.shape = collision_shape
	area.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.0
	mesh_instance.material_override = material
	area.add_child(mesh_instance)

	area.add_child(_make_label(label_text, Vector3(0.0, 0.72, 0.0), Color(1.0, 1.0, 1.0)))
	return area


func _make_label(text: String, position: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.font_size = 38
	label.outline_size = 8
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	return label
