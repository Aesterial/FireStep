extends Node3D

const Interactable = preload("res://scripts/interactable.gd")

@export var workshop_props_scene: PackedScene
@export var machine_visual_scene: PackedScene
@export var wall_material: StandardMaterial3D
@export var floor_material: StandardMaterial3D

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var scenario: ScenarioState = $ScenarioState
@onready var hud: CanvasLayer = $HUD

var smoke_root: Node3D
var smoke_puffs: Array[MeshInstance3D] = []
var smoke_materials: Array[StandardMaterial3D] = []
var warning_light: OmniLight3D
var warning_indicator_material: StandardMaterial3D
var machine_body_material: StandardMaterial3D
var emergency_stop_material: StandardMaterial3D
var exit_panel_material: StandardMaterial3D
var safe_zone_material: StandardMaterial3D
var exit_light: OmniLight3D
var safe_zone_area: Area3D
var machine_panel: Interactable
var exit_panel: Interactable

var smoke_intensity: float = 0.55
var smoke_target: float = 0.55
var machine_color_target: Color = Color(0.31, 0.36, 0.42)
var visual_state: String = "warning"


func _ready() -> void:
	_configure_player_spawn()
	_configure_environment()
	_build_world()
	_connect_signals()
	scenario.begin()


func _unhandled_input(event: InputEvent) -> void:
	if scenario.is_finished() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_restart_scenario()


func _process(delta: float) -> void:
	smoke_intensity = move_toward(smoke_intensity, smoke_target, delta * 0.65)
	_update_smoke()
	_update_warning_flash()
	machine_body_material.albedo_color = machine_body_material.albedo_color.lerp(machine_color_target, delta * 2.0)

	if visual_state == "failure":
		exit_light.light_energy = lerpf(exit_light.light_energy, 0.6, delta * 2.5)


func _configure_player_spawn() -> void:
	player.global_position = Vector3(4.4, 0.0, 3.2)
	player.rotation_degrees = Vector3(0.0, -118.0, 0.0)


func _configure_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.09, 0.11)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.68, 0.75)
	environment.ambient_light_energy = 1.2
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment


func _build_world() -> void:
	var world_root := Node3D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)

	_build_room(world_root)
	_build_guidance(world_root)
	_build_machine(world_root)
	_build_safe_zone(world_root)
	_build_exit(world_root)


func _build_room(parent: Node3D) -> void:
	parent.add_child(_make_box_body("Floor", Vector3(15.0, 0.2, 11.0), Vector3(0.0, -0.1, 0.0), Color(0.18, 0.2, 0.22)))
	parent.add_child(_make_box_body("BackWall", Vector3(15.0, 3.8, 0.3), Vector3(0.0, 1.9, -5.4), Color(0.23, 0.24, 0.28)))
	parent.add_child(_make_box_body("FrontWall", Vector3(15.0, 3.8, 0.3), Vector3(0.0, 1.9, 5.4), Color(0.23, 0.24, 0.28)))
	parent.add_child(_make_box_body("LeftWall", Vector3(0.3, 3.8, 11.0), Vector3(-7.35, 1.9, 0.0), Color(0.25, 0.26, 0.3)))
	parent.add_child(_make_box_body("RightWall", Vector3(0.3, 3.8, 11.0), Vector3(7.35, 1.9, 0.0), Color(0.25, 0.26, 0.3)))

	if workshop_props_scene != null:
		var props_root := workshop_props_scene.instantiate()
		parent.add_child(props_root)
	else:
		parent.add_child(_make_visual_box(Vector3(1.6, 1.2, 1.2), Vector3(-2.8, 0.6, -1.4), Color(0.36, 0.28, 0.18), false))
		parent.add_child(_make_visual_box(Vector3(1.2, 0.8, 1.2), Vector3(-2.8, 1.55, -1.4), Color(0.39, 0.31, 0.2), false))
		parent.add_child(_make_visual_box(Vector3(1.0, 1.0, 1.4), Vector3(5.0, 0.5, -3.8), Color(0.22, 0.24, 0.2), false))


func _build_guidance(parent: Node3D) -> void:
	parent.add_child(_make_visual_box(Vector3(6.8, 0.03, 0.35), Vector3(-0.9, 0.015, 1.3), Color(0.95, 0.74, 0.14), true))
	parent.add_child(_make_visual_box(Vector3(0.35, 0.03, 3.3), Vector3(-4.15, 0.015, 2.7), Color(0.95, 0.74, 0.14), true))
	parent.add_child(_make_visual_box(Vector3(0.35, 0.03, 4.0), Vector3(-4.8, 0.015, -1.0), Color(0.18, 0.72, 0.3), true))
	parent.add_child(_make_visual_box(Vector3(2.0, 0.03, 0.35), Vector3(-5.8, 0.015, -3.0), Color(0.18, 0.72, 0.3), true))


func _build_machine(parent: Node3D) -> void:
	var machine_root := Node3D.new()
	machine_root.name = "MachineRig"
	machine_root.position = Vector3(1.6, 0.0, 0.2)
	parent.add_child(machine_root)

	machine_body_material = StandardMaterial3D.new()
	machine_body_material.albedo_color = Color(0.31, 0.36, 0.42)
	machine_body_material.metallic = 0.15
	machine_body_material.roughness = 0.55
	if machine_visual_scene != null:
		var machine_visual := machine_visual_scene.instantiate()
		machine_root.add_child(machine_visual)

		# Добавляем коллизию для импортированной модели, если её нет
		var static_body := StaticBody3D.new()
		machine_visual.add_child(static_body)
		var collision := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(2.0, 2.0, 2.0) # Примерный размер для станка
		collision.shape = box_shape
		collision.position = Vector3(0, 1.0, 0)
		static_body.add_child(collision)
	else:
		var machine_body := StaticBody3D.new()
		machine_body.name = "MachineBody"
		machine_root.add_child(machine_body)

		var body_mesh := MeshInstance3D.new()
		var body_shape := BoxMesh.new()
		body_shape.size = Vector3(2.6, 1.0, 1.8)
		body_mesh.mesh = body_shape
		body_mesh.material_override = machine_body_material
		body_mesh.position = Vector3(0.0, 0.5, 0.0)
		machine_body.add_child(body_mesh)

		var body_collision := CollisionShape3D.new()
		var body_collision_shape := BoxShape3D.new()
		body_collision_shape.size = Vector3(2.6, 1.0, 1.8)
		body_collision.shape = body_collision_shape
		body_collision.position = Vector3(0.0, 0.5, 0.0)
		machine_body.add_child(body_collision)

		var tank_mesh := MeshInstance3D.new()
		var tank := CylinderMesh.new()
		tank.top_radius = 0.42
		tank.bottom_radius = 0.42
		tank.height = 1.7
		tank_mesh.mesh = tank
		tank_mesh.material_override = machine_body_material
		tank_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		tank_mesh.position = Vector3(-0.3, 1.15, 0.0)
		machine_root.add_child(tank_mesh)

		var cabinet := MeshInstance3D.new()
		var cabinet_mesh := BoxMesh.new()
		cabinet_mesh.size = Vector3(0.9, 1.1, 0.8)
		cabinet.mesh = cabinet_mesh
		cabinet.material_override = machine_body_material
		cabinet.position = Vector3(0.85, 1.05, 0.45)
		machine_root.add_child(cabinet)

		var pipe := MeshInstance3D.new()
		var pipe_mesh := CylinderMesh.new()
		pipe_mesh.top_radius = 0.08
		pipe_mesh.bottom_radius = 0.08
		pipe_mesh.height = 1.6
		pipe.mesh = pipe_mesh
		pipe.material_override = machine_body_material
		pipe.position = Vector3(-0.95, 1.4, 0.0)
		machine_root.add_child(pipe)

	var warning_indicator := MeshInstance3D.new()
	var warning_mesh := SphereMesh.new()
	warning_mesh.radius = 0.16
	warning_mesh.height = 0.32
	warning_indicator.mesh = warning_mesh
	warning_indicator_material = StandardMaterial3D.new()
	warning_indicator_material.albedo_color = Color(1.0, 0.2, 0.1)
	warning_indicator_material.emission_enabled = true
	warning_indicator_material.emission = Color(1.0, 0.2, 0.1)
	warning_indicator_material.emission_energy_multiplier = 2.0
	warning_indicator.material_override = warning_indicator_material
	warning_indicator.position = Vector3(0.85, 1.85, 0.45)
	machine_root.add_child(warning_indicator)

	warning_light = OmniLight3D.new()
	warning_light.position = Vector3(0.85, 1.9, 0.45)
	warning_light.light_color = Color(1.0, 0.18, 0.12)
	warning_light.light_energy = 4.0
	warning_light.omni_range = 5.0
	machine_root.add_child(warning_light)

	smoke_root = Node3D.new()
	smoke_root.name = "SmokeRoot"
	smoke_root.position = Vector3(-0.85, 1.9, 0.0)
	machine_root.add_child(smoke_root)

	for index in range(5):
		var puff := MeshInstance3D.new()
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 0.18 + index * 0.03
		puff_mesh.height = 0.36 + index * 0.06
		puff.mesh = puff_mesh

		var puff_material := StandardMaterial3D.new()
		puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff_material.albedo_color = Color(0.2, 0.2, 0.2, 0.26)
		puff_material.roughness = 1.0
		puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = puff_material

		smoke_root.add_child(puff)
		smoke_puffs.append(puff)
		smoke_materials.append(puff_material)

	var emergency_stop := _make_interactable_panel(
		"EmergencyStop",
		"emergency_stop",
		"[E] Аварийная остановка",
		Vector3(2.05, 1.1, -0.8),
		Vector3(0.42, 0.42, 0.42),
		Color(0.95, 0.15, 0.12),
		"СТОП"
	)
	emergency_stop_material = emergency_stop.get_meta("display_material") as StandardMaterial3D
	machine_root.add_child(emergency_stop)

	machine_panel = _make_interactable_panel(
		"MachinePanel",
		"machine_panel",
		"[E] Пытаться спасать оборудование",
		Vector3(1.5, 1.0, 0.85),
		Vector3(0.6, 0.6, 0.2),
		Color(0.95, 0.68, 0.08),
		"ЩИТ"
	)
	machine_root.add_child(machine_panel)

	machine_root.add_child(_make_label("Компрессор", Vector3(0.0, 2.55, 0.0), Color(1.0, 0.96, 0.82)))


func _build_safe_zone(parent: Node3D) -> void:
	safe_zone_area = Area3D.new()
	safe_zone_area.name = "SafeZone"
	safe_zone_area.position = Vector3(-4.8, 0.0, 2.8)
	parent.add_child(safe_zone_area)

	var safe_shape := CollisionShape3D.new()
	var safe_collision := CylinderShape3D.new()
	safe_collision.radius = 1.4
	safe_collision.height = 2.4
	safe_shape.shape = safe_collision
	safe_shape.position = Vector3(0.0, 1.2, 0.0)
	safe_zone_area.add_child(safe_shape)

	var safe_marker := MeshInstance3D.new()
	var safe_mesh := CylinderMesh.new()
	safe_mesh.top_radius = 1.6
	safe_mesh.bottom_radius = 1.6
	safe_mesh.height = 0.04
	safe_marker.mesh = safe_mesh
	safe_zone_material = StandardMaterial3D.new()
	safe_zone_material.albedo_color = Color(0.15, 0.58, 0.22, 0.75)
	safe_zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	safe_zone_material.emission_enabled = true
	safe_zone_material.emission = Color(0.22, 0.85, 0.35)
	safe_zone_material.emission_energy_multiplier = 1.8
	safe_marker.material_override = safe_zone_material
	safe_marker.global_position = Vector3(-4.8, 0.02, 2.8)
	parent.add_child(safe_marker)

	parent.add_child(_make_label("БЕЗОПАСНАЯ ЗОНА", Vector3(-4.8, 0.16, 4.0), Color(0.72, 1.0, 0.76)))


func _build_exit(parent: Node3D) -> void:
	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.2, 2.3, 1.7)
	door.mesh = door_mesh
	var door_material := StandardMaterial3D.new()
	door_material.albedo_color = Color(0.12, 0.2, 0.18)
	door_material.roughness = 0.7
	door.material_override = door_material
	door.position = Vector3(-7.0, 1.15, -3.0)
	parent.add_child(door)

	exit_panel = _make_interactable_panel(
		"ExitPanel",
		"exit",
		"[E] Выйти из цеха",
		Vector3(-6.58, 1.15, -3.0),
		Vector3(0.25, 0.48, 0.48),
		Color(0.82, 0.2, 0.15),
		"ВЫХОД"
	)
	exit_panel_material = exit_panel.get_meta("display_material") as StandardMaterial3D
	parent.add_child(exit_panel)

	exit_light = OmniLight3D.new()
	exit_light.position = Vector3(-6.55, 2.0, -3.0)
	exit_light.light_color = Color(0.92, 0.16, 0.12)
	exit_light.light_energy = 2.2
	exit_light.omni_range = 4.5
	parent.add_child(exit_light)

	parent.add_child(_make_label("ВЫХОД", Vector3(-6.15, 2.7, -3.0), Color(0.9, 1.0, 0.9)))


func _connect_signals() -> void:
	player.prompt_changed.connect(hud.set_interaction_prompt)
	player.interact_requested.connect(_on_player_interact)
	safe_zone_area.body_entered.connect(_on_safe_zone_body_entered)

	scenario.objective_changed.connect(hud.set_objective)
	scenario.hint_changed.connect(hud.set_hint)
	scenario.banner_changed.connect(hud.set_warning_banner)
	scenario.feedback_requested.connect(hud.show_feedback)
	scenario.decision_requested.connect(_on_decision_requested)
	scenario.result_requested.connect(_on_result_requested)
	scenario.visuals_changed.connect(_apply_visual_state)

	hud.decision_selected.connect(scenario.submit_decision)
	hud.restart_requested.connect(_restart_scenario)


func _on_player_interact(interactable: Interactable) -> void:
	scenario.handle_action(interactable.action_id)


func _on_safe_zone_body_entered(body: Node) -> void:
	if body == player:
		scenario.on_safe_zone_entered()


func _on_decision_requested(visible: bool, title: String, body: String) -> void:
	hud.show_decision(visible, title, body)
	player.set_gameplay_enabled(not visible)


func _on_result_requested(success: bool, title: String, body: String) -> void:
	player.set_gameplay_enabled(false)
	if success:
		GameSession.set_workshop_summary(body)
		hud.show_feedback("Переход к этапу эвакуации...", "info")
		_queue_scene_change("res://scenes/Evacuation.tscn", 0.9)
	else:
		GameSession.set_final_result(
			false,
			title,
			body,
			[
				"Ошибка допущена на этапе реакции в цехе",
				"Приоритет безопасности людей не был соблюдён"
			]
		)
		hud.show_feedback("Неверное действие. Опасность усиливается...", "warning")
		_queue_scene_change("res://scenes/Debrief.tscn", 1.1)


func _apply_visual_state(state: String) -> void:
	visual_state = state

	match state:
		"warning":
			smoke_target = 0.55
			machine_color_target = Color(0.31, 0.36, 0.42)
			emergency_stop_material.albedo_color = Color(0.95, 0.15, 0.12)
			exit_panel_material.albedo_color = Color(0.82, 0.2, 0.15)
			safe_zone_material.emission_energy_multiplier = 1.8
		"stopped":
			smoke_target = 0.38
			machine_color_target = Color(0.28, 0.33, 0.38)
			emergency_stop_material.albedo_color = Color(0.58, 0.12, 0.1)
			safe_zone_material.emission_energy_multiplier = 2.4
		"alarm_raised":
			smoke_target = 0.34
			machine_color_target = Color(0.28, 0.33, 0.38)
			exit_panel_material.albedo_color = Color(0.16, 0.7, 0.26)
			exit_light.light_color = Color(0.22, 0.92, 0.35)
			exit_light.light_energy = 4.5
			safe_zone_material.emission_energy_multiplier = 1.5
		"failure":
			smoke_target = 1.15
			machine_color_target = Color(0.46, 0.2, 0.18)
			exit_panel_material.albedo_color = Color(0.82, 0.2, 0.15)
			safe_zone_material.emission_energy_multiplier = 0.8
		"success":
			smoke_target = 0.2
			machine_color_target = Color(0.24, 0.31, 0.28)
			exit_panel_material.albedo_color = Color(0.16, 0.7, 0.26)
			exit_light.light_color = Color(0.22, 0.92, 0.35)
			exit_light.light_energy = 5.0
			safe_zone_material.emission_energy_multiplier = 1.2


func _update_smoke() -> void:
	var time: float = Time.get_ticks_msec() * 0.001
	for index in smoke_puffs.size():
		var puff: MeshInstance3D = smoke_puffs[index]
		var sway: float = sin(time * (1.4 + index * 0.2) + index) * 0.14
		var sway_z: float = cos(time * (1.2 + index * 0.23) + index * 0.7) * 0.12
		var rise: float = fmod(time * (0.38 + index * 0.05) + index * 0.22, 1.6)
		puff.position = Vector3(sway, rise * smoke_intensity * 1.2, sway_z)
		puff.scale = Vector3.ONE * (0.75 + rise * 0.25 + smoke_intensity * 0.55)

		var alpha: float = clampf(0.12 + smoke_intensity * 0.18 - rise * 0.03, 0.08, 0.38)
		var color: Color = Color(0.18, 0.18, 0.18, alpha)
		if visual_state == "failure":
			color = Color(0.25, 0.18, 0.18, clampf(alpha + 0.08, 0.12, 0.46))
		smoke_materials[index].albedo_color = color


func _update_warning_flash() -> void:
	var pulse: float = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)

	match visual_state:
		"warning":
			warning_light.visible = true
			warning_light.light_color = Color(1.0, 0.18, 0.12)
			warning_light.light_energy = 2.8 + pulse * 2.1
			warning_indicator_material.emission = Color(1.0, 0.18, 0.12)
			warning_indicator_material.emission_energy_multiplier = 1.8 + pulse * 1.8
		"stopped":
			warning_light.visible = true
			warning_light.light_color = Color(1.0, 0.52, 0.14)
			warning_light.light_energy = 2.0 + pulse * 1.3
			warning_indicator_material.emission = Color(1.0, 0.52, 0.14)
			warning_indicator_material.emission_energy_multiplier = 1.2 + pulse * 1.1
		"alarm_raised":
			warning_light.visible = true
			warning_light.light_color = Color(1.0, 0.62, 0.18)
			warning_light.light_energy = 1.8 + pulse * 1.1
			warning_indicator_material.emission = Color(1.0, 0.62, 0.18)
			warning_indicator_material.emission_energy_multiplier = 1.0 + pulse * 0.8
		"failure":
			warning_light.visible = true
			warning_light.light_color = Color(1.0, 0.05, 0.05)
			warning_light.light_energy = 5.0 + pulse * 3.0
			warning_indicator_material.emission = Color(1.0, 0.05, 0.05)
			warning_indicator_material.emission_energy_multiplier = 2.6 + pulse * 2.4
		"success":
			warning_light.visible = false
			warning_indicator_material.emission = Color(0.2, 0.72, 0.3)
			warning_indicator_material.emission_energy_multiplier = 1.2


func _restart_scenario() -> void:
	get_tree().reload_current_scene()


func _queue_scene_change(path: String, delay: float) -> void:
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void:
		get_tree().change_scene_to_file(path)
	)


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
		material.roughness = 0.95

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
	material.roughness = 0.7
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
	material.roughness = 0.4
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.8
	mesh_instance.material_override = material
	area.add_child(mesh_instance)

	area.add_child(_make_label(label_text, Vector3(0.0, 0.52, 0.0), Color(1.0, 1.0, 1.0)))
	area.set_meta("display_material", material)
	return area


func _make_label(text: String, position: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.font_size = 40
	label.outline_size = 8
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	return label
