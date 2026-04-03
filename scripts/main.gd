extends Node3D

const Interactable = preload("res://scripts/interactable.gd")
const FLOOR_TEXTURE: Texture2D = preload("res://assets/textures/variation-c.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/textures/variation-a.png")
const CEILING_TEXTURE: Texture2D = preload("res://assets/textures/variation-b.png")
const DETAIL_TANK_SCENE: PackedScene = preload("res://assets/models/detail-tank.glb")
const CHIMNEY_SMALL_SCENE: PackedScene = preload("res://assets/models/chimney-small.glb")
const CHIMNEY_MEDIUM_SCENE: PackedScene = preload("res://assets/models/chimney-medium.glb")

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

var floor_surface_material: StandardMaterial3D
var wall_surface_material: StandardMaterial3D
var ceiling_surface_material: StandardMaterial3D
var beam_material: StandardMaterial3D
var accent_metal_material: StandardMaterial3D

var smoke_intensity: float = 0.55
var smoke_target: float = 0.55
var machine_color_target: Color = Color(0.33, 0.38, 0.44)
var visual_state: String = "warning"


func _ready() -> void:
	_configure_player_spawn()
	_configure_environment()
	_configure_materials()
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
	player.global_position = Vector3(5.0, 0.0, 3.8)
	player.rotation_degrees = Vector3(0.0, -126.0, 0.0)


func _configure_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.07, 0.08, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.54, 0.6, 0.68)
	environment.ambient_light_energy = 1.15
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.16, 0.18, 0.2)
	environment.fog_density = 0.012
	world_environment.environment = environment


func _configure_materials() -> void:
	floor_surface_material = _make_textured_material(FLOOR_TEXTURE, Vector3(4.4, 4.4, 1.0), 0.96, 0.0, Color(0.86, 0.88, 0.9))
	wall_surface_material = _make_textured_material(WALL_TEXTURE, Vector3(2.3, 1.4, 1.0), 0.9, 0.0, Color(0.92, 0.93, 0.95))
	ceiling_surface_material = _make_textured_material(CEILING_TEXTURE, Vector3(2.2, 2.2, 1.0), 0.92, 0.05, Color(0.86, 0.88, 0.9))
	beam_material = _make_metal_material(Color(0.16, 0.18, 0.22), 0.62, 0.22)
	accent_metal_material = _make_metal_material(Color(0.22, 0.26, 0.3), 0.45, 0.18)


func _build_world() -> void:
	var world_root := Node3D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)

	_build_room(world_root)
	_build_guidance(world_root)
	_build_machine(world_root)
	_build_support_props(world_root)
	_build_safe_zone(world_root)
	_build_exit(world_root)
	_build_lighting(world_root)


func _build_room(parent: Node3D) -> void:
	parent.add_child(_make_box_body("Floor", Vector3(16.0, 0.2, 12.0), Vector3(0.0, -0.1, 0.0), Color(0.2, 0.22, 0.25), floor_surface_material))
	parent.add_child(_make_box_body("Ceiling", Vector3(16.0, 0.2, 12.0), Vector3(0.0, 4.0, 0.0), Color(0.18, 0.19, 0.22), ceiling_surface_material))
	parent.add_child(_make_box_body("BackWall", Vector3(16.0, 4.2, 0.3), Vector3(0.0, 2.0, -5.85), Color(0.25, 0.26, 0.29), wall_surface_material))
	parent.add_child(_make_box_body("FrontWall", Vector3(16.0, 4.2, 0.3), Vector3(0.0, 2.0, 5.85), Color(0.25, 0.26, 0.29), wall_surface_material))
	parent.add_child(_make_box_body("LeftWallUpper", Vector3(0.3, 4.2, 6.0), Vector3(-7.85, 2.0, 2.95), Color(0.25, 0.26, 0.29), wall_surface_material))
	parent.add_child(_make_box_body("LeftWallRear", Vector3(0.3, 4.2, 4.8), Vector3(-7.85, 2.0, -3.45), Color(0.25, 0.26, 0.29), wall_surface_material))
	parent.add_child(_make_box_body("DoorLintel", Vector3(0.3, 1.0, 1.6), Vector3(-7.85, 3.5, -0.35), Color(0.17, 0.18, 0.2), beam_material))
	parent.add_child(_make_box_body("RightWall", Vector3(0.3, 4.2, 12.0), Vector3(7.85, 2.0, 0.0), Color(0.25, 0.26, 0.29), wall_surface_material))

	for beam_z in [-4.3, -1.1, 2.1, 4.8]:
		parent.add_child(_make_box_body("RoofBeam%0.1f" % beam_z, Vector3(15.5, 0.18, 0.38), Vector3(0.0, 3.55, beam_z), Color(0.16, 0.18, 0.22), beam_material))

	for column in [
		Vector3(-4.4, 1.75, -4.6),
		Vector3(-4.4, 1.75, 4.6),
		Vector3(3.6, 1.75, -4.6),
		Vector3(3.6, 1.75, 4.6),
	]:
		parent.add_child(_make_box_body("Column", Vector3(0.35, 3.5, 0.35), column, Color(0.19, 0.2, 0.24), beam_material))

	parent.add_child(_make_visual_box(Vector3(7.2, 0.16, 0.16), Vector3(-0.3, 3.78, -2.25), Color(0.24, 0.27, 0.32), false, accent_metal_material))
	parent.add_child(_make_visual_box(Vector3(7.2, 0.16, 0.16), Vector3(-0.3, 3.78, 2.25), Color(0.24, 0.27, 0.32), false, accent_metal_material))
	parent.add_child(_make_visual_box(Vector3(0.22, 0.22, 8.7), Vector3(6.85, 3.64, 0.1), Color(0.3, 0.32, 0.36), false, accent_metal_material))
	parent.add_child(_make_visual_box(Vector3(0.22, 0.22, 8.7), Vector3(6.35, 3.64, 0.1), Color(0.3, 0.32, 0.36), false, accent_metal_material))

	for window_pos in [
		Vector3(0.0, 2.8, -5.68),
		Vector3(0.0, 2.8, 5.68),
	]:
		parent.add_child(_make_visual_box(Vector3(5.6, 0.85, 0.04), window_pos, Color(0.32, 0.48, 0.66, 0.82), true))


func _build_guidance(parent: Node3D) -> void:
	parent.add_child(_make_visual_box(Vector3(7.3, 0.035, 0.38), Vector3(-0.65, 0.018, 1.45), Color(0.95, 0.74, 0.14), true))
	parent.add_child(_make_visual_box(Vector3(0.38, 0.035, 3.8), Vector3(-4.15, 0.018, 2.7), Color(0.95, 0.74, 0.14), true))
	parent.add_child(_make_visual_box(Vector3(0.38, 0.035, 4.0), Vector3(-4.95, 0.018, -0.9), Color(0.18, 0.72, 0.3), true))
	parent.add_child(_make_visual_box(Vector3(2.2, 0.035, 0.38), Vector3(-5.95, 0.018, -3.0), Color(0.18, 0.72, 0.3), true))

	for stripe_pos in [-2.0, -1.2, -0.4, 0.4, 1.2, 2.0]:
		parent.add_child(_make_visual_box(Vector3(0.34, 0.03, 1.3), Vector3(2.9, 0.016, stripe_pos), Color(0.9, 0.66, 0.12), true, null, Vector3(0.0, 18.0, 0.0)))


func _build_machine(parent: Node3D) -> void:
	var machine_root := Node3D.new()
	machine_root.name = "MachineRig"
	machine_root.position = Vector3(1.6, 0.0, 0.15)
	parent.add_child(machine_root)

	machine_body_material = _make_metal_material(Color(0.33, 0.38, 0.44), 0.5, 0.18)

	var plinth_material := _make_metal_material(Color(0.14, 0.16, 0.2), 0.72, 0.08)
	machine_root.add_child(_make_visual_box(Vector3(3.3, 0.18, 2.6), Vector3(0.0, 0.09, 0.0), Color(0.14, 0.16, 0.2), false, plinth_material))

	var machine_body := StaticBody3D.new()
	machine_body.name = "MachineBody"
	machine_root.add_child(machine_body)

	var body_mesh := MeshInstance3D.new()
	var body_shape := BoxMesh.new()
	body_shape.size = Vector3(2.8, 1.0, 1.9)
	body_mesh.mesh = body_shape
	body_mesh.material_override = machine_body_material
	body_mesh.position = Vector3(0.0, 0.62, 0.0)
	machine_body.add_child(body_mesh)

	var body_collision := CollisionShape3D.new()
	var body_collision_shape := BoxShape3D.new()
	body_collision_shape.size = Vector3(2.8, 1.0, 1.9)
	body_collision.shape = body_collision_shape
	body_collision.position = Vector3(0.0, 0.62, 0.0)
	machine_body.add_child(body_collision)

	for tank_position in [Vector3(-0.7, 1.28, -0.46), Vector3(-0.7, 1.28, 0.46)]:
		var tank_mesh := MeshInstance3D.new()
		var tank := CylinderMesh.new()
		tank.top_radius = 0.33
		tank.bottom_radius = 0.33
		tank.height = 1.75
		tank_mesh.mesh = tank
		tank_mesh.material_override = machine_body_material
		tank_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		tank_mesh.position = tank_position
		machine_root.add_child(tank_mesh)

	var cabinet_material := _make_metal_material(Color(0.2, 0.24, 0.28), 0.36, 0.12)
	machine_root.add_child(_make_visual_box(Vector3(0.9, 1.34, 0.84), Vector3(1.0, 0.86, 0.52), Color(0.2, 0.24, 0.28), false, cabinet_material))
	machine_root.add_child(_make_visual_box(Vector3(0.84, 0.22, 2.1), Vector3(0.36, 1.24, 0.0), Color(0.2, 0.24, 0.28), false, cabinet_material))
	machine_root.add_child(_make_visual_box(Vector3(1.75, 0.12, 0.12), Vector3(-1.02, 1.82, 0.0), Color(0.24, 0.27, 0.31), false, accent_metal_material))
	machine_root.add_child(_make_visual_box(Vector3(0.12, 1.32, 0.12), Vector3(-1.85, 1.22, 0.0), Color(0.24, 0.27, 0.31), false, accent_metal_material))

	warning_indicator_material = _make_metal_material(Color(1.0, 0.2, 0.1), 0.24, 0.0)
	warning_indicator_material.emission_enabled = true
	warning_indicator_material.emission = Color(1.0, 0.2, 0.1)
	warning_indicator_material.emission_energy_multiplier = 2.0

	var warning_indicator := MeshInstance3D.new()
	var warning_mesh := SphereMesh.new()
	warning_mesh.radius = 0.16
	warning_mesh.height = 0.32
	warning_indicator.mesh = warning_mesh
	warning_indicator.material_override = warning_indicator_material
	warning_indicator.position = Vector3(1.05, 2.1, 0.52)
	machine_root.add_child(warning_indicator)

	warning_light = OmniLight3D.new()
	warning_light.position = Vector3(1.05, 2.1, 0.52)
	warning_light.light_color = Color(1.0, 0.18, 0.12)
	warning_light.light_energy = 4.0
	warning_light.omni_range = 5.4
	machine_root.add_child(warning_light)

	smoke_root = Node3D.new()
	smoke_root.name = "SmokeRoot"
	smoke_root.position = Vector3(-1.75, 1.9, 0.0)
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

	emergency_stop_material = _make_panel_material(Color(0.95, 0.15, 0.12))
	var emergency_stop := _make_interactable_panel(
		"EmergencyStop",
		"emergency_stop",
		"[E] Аварийная остановка",
		Vector3(2.25, 1.14, -0.92),
		Vector3(0.42, 0.42, 0.42),
		emergency_stop_material,
		"СТОП"
	)
	machine_root.add_child(emergency_stop)

	machine_panel = _make_interactable_panel(
		"MachinePanel",
		"machine_panel",
		"[E] Пытаться спасать оборудование",
		Vector3(1.52, 1.08, 1.05),
		Vector3(0.7, 0.65, 0.22),
		_make_panel_material(Color(0.95, 0.68, 0.08)),
		"ЩИТ"
	)
	machine_root.add_child(machine_panel)

	machine_root.add_child(_make_label("GEN-01 / Компрессор", Vector3(0.15, 2.75, 0.0), Color(1.0, 0.96, 0.82), 38))


func _build_support_props(parent: Node3D) -> void:
	var catwalk_material := _make_metal_material(Color(0.18, 0.2, 0.24), 0.78, 0.06)
	parent.add_child(_make_visual_box(Vector3(4.6, 0.16, 1.55), Vector3(4.9, 0.08, -4.1), Color(0.18, 0.2, 0.24), false, catwalk_material))
	parent.add_child(_make_visual_box(Vector3(2.2, 1.5, 0.16), Vector3(4.9, 0.92, -4.8), Color(0.24, 0.27, 0.31), false, accent_metal_material))
	parent.add_child(_make_visual_box(Vector3(0.16, 1.2, 1.55), Vector3(6.95, 0.68, -4.1), Color(0.24, 0.27, 0.31), false, accent_metal_material))

	for prop in [
		{"position": Vector3(-5.85, 0.0, -4.1), "scale": Vector3(2.1, 2.1, 2.1), "rotation": Vector3(0.0, 18.0, 0.0)},
		{"position": Vector3(-5.25, 0.0, 4.25), "scale": Vector3(2.0, 2.0, 2.0), "rotation": Vector3(0.0, -20.0, 0.0)},
	]:
		parent.add_child(_make_scene_prop(DETAIL_TANK_SCENE, prop.position, prop.scale, prop.rotation))

	parent.add_child(_make_scene_prop(CHIMNEY_SMALL_SCENE, Vector3(6.2, 0.0, 4.35), Vector3(1.45, 1.45, 1.45), Vector3(0.0, 0.0, 0.0)))
	parent.add_child(_make_scene_prop(CHIMNEY_MEDIUM_SCENE, Vector3(5.0, 0.0, 4.2), Vector3(1.25, 1.25, 1.25), Vector3(0.0, 0.0, 0.0)))

	for rack_pos in [Vector3(5.75, 0.58, 2.9), Vector3(5.75, 0.58, 1.25)]:
		parent.add_child(_make_visual_box(Vector3(1.3, 1.16, 0.82), rack_pos, Color(0.24, 0.27, 0.31), false, accent_metal_material))
		parent.add_child(_make_visual_box(Vector3(1.05, 0.22, 0.66), rack_pos + Vector3(0.0, 0.52, 0.0), Color(0.82, 0.56, 0.12), false))

	parent.add_child(_make_visual_box(Vector3(1.95, 0.88, 0.92), Vector3(-5.6, 0.44, 1.25), Color(0.3, 0.22, 0.16), false))
	parent.add_child(_make_visual_box(Vector3(1.35, 0.14, 0.96), Vector3(-5.6, 0.95, 1.25), Color(0.22, 0.24, 0.26), false, accent_metal_material))
	parent.add_child(_make_visual_box(Vector3(1.55, 1.05, 0.78), Vector3(-5.45, 0.52, 0.1), Color(0.18, 0.2, 0.24), false, accent_metal_material))


func _build_safe_zone(parent: Node3D) -> void:
	safe_zone_area = Area3D.new()
	safe_zone_area.name = "SafeZone"
	safe_zone_area.position = Vector3(-4.95, 0.0, 2.95)
	parent.add_child(safe_zone_area)

	var safe_shape := CollisionShape3D.new()
	var safe_collision := CylinderShape3D.new()
	safe_collision.radius = 1.45
	safe_collision.height = 2.4
	safe_shape.shape = safe_collision
	safe_shape.position = Vector3(0.0, 1.2, 0.0)
	safe_zone_area.add_child(safe_shape)

	var safe_marker := MeshInstance3D.new()
	var safe_mesh := CylinderMesh.new()
	safe_mesh.top_radius = 1.7
	safe_mesh.bottom_radius = 1.7
	safe_mesh.height = 0.05
	safe_marker.mesh = safe_mesh
	safe_zone_material = StandardMaterial3D.new()
	safe_zone_material.albedo_color = Color(0.15, 0.58, 0.22, 0.75)
	safe_zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	safe_zone_material.emission_enabled = true
	safe_zone_material.emission = Color(0.22, 0.85, 0.35)
	safe_zone_material.emission_energy_multiplier = 1.8
	safe_marker.material_override = safe_zone_material
	safe_marker.global_position = Vector3(-4.95, 0.03, 2.95)
	parent.add_child(safe_marker)

	parent.add_child(_make_visual_box(Vector3(3.2, 0.12, 0.12), Vector3(-4.95, 0.8, 1.35), Color(0.28, 0.72, 0.38), false, accent_metal_material))
	parent.add_child(_make_label("БЕЗОПАСНАЯ ЗОНА", Vector3(-4.95, 0.22, 4.3), Color(0.72, 1.0, 0.76), 34))


func _build_exit(parent: Node3D) -> void:
	parent.add_child(_make_box_body("ExitFrameRear", Vector3(0.2, 2.45, 1.95), Vector3(-7.45, 1.22, -0.35), Color(0.16, 0.18, 0.2), beam_material))

	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.14, 2.3, 1.68)
	door.mesh = door_mesh
	var door_material := _make_metal_material(Color(0.11, 0.18, 0.17), 0.65, 0.06)
	door.material_override = door_material
	door.position = Vector3(-7.18, 1.15, -0.35)
	parent.add_child(door)

	exit_panel_material = _make_panel_material(Color(0.82, 0.2, 0.15))
	exit_panel = _make_interactable_panel(
		"ExitPanel",
		"exit",
		"[E] Выйти из цеха",
		Vector3(-6.72, 1.15, -0.35),
		Vector3(0.25, 0.52, 0.52),
		exit_panel_material,
		"ВЫХОД"
	)
	parent.add_child(exit_panel)

	exit_light = OmniLight3D.new()
	exit_light.position = Vector3(-6.9, 2.05, -0.35)
	exit_light.light_color = Color(0.92, 0.16, 0.12)
	exit_light.light_energy = 2.2
	exit_light.omni_range = 4.2
	parent.add_child(exit_light)

	parent.add_child(_make_label("ВЫХОД В ПЕРЕХОД", Vector3(-5.85, 2.72, -0.35), Color(0.9, 1.0, 0.9), 32))


func _build_lighting(parent: Node3D) -> void:
	for light_pos in [
		Vector3(-3.8, 3.7, -2.25),
		Vector3(-3.8, 3.7, 2.25),
		Vector3(2.2, 3.7, -2.25),
		Vector3(2.2, 3.7, 2.25),
	]:
		var strip_root := Node3D.new()
		strip_root.position = light_pos
		parent.add_child(strip_root)

		strip_root.add_child(_make_visual_box(Vector3(2.1, 0.08, 0.42), Vector3.ZERO, Color(0.88, 0.92, 0.96), true))

		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0.0, -0.2, 0.0)
		lamp.light_color = Color(0.9, 0.94, 1.0)
		lamp.light_energy = 1.6
		lamp.omni_range = 6.4
		strip_root.add_child(lamp)


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
		hud.show_feedback("Переход к резервному генератору...", "info")
		_queue_scene_change("res://scenes/SecondaryGenerator.tscn", 0.9)
	else:
		GameSession.set_final_result(
			false,
			title,
			body,
			[
				"Ошибка допущена на первом этапе в цехе",
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
			machine_color_target = Color(0.33, 0.38, 0.44)
			emergency_stop_material.albedo_color = Color(0.95, 0.15, 0.12)
			exit_panel_material.albedo_color = Color(0.82, 0.2, 0.15)
			safe_zone_material.emission_energy_multiplier = 1.8
		"stopped":
			smoke_target = 0.38
			machine_color_target = Color(0.28, 0.33, 0.38)
			emergency_stop_material.albedo_color = Color(0.58, 0.12, 0.1)
			safe_zone_material.emission_energy_multiplier = 2.4
		"alarm_raised":
			smoke_target = 0.32
			machine_color_target = Color(0.28, 0.33, 0.38)
			exit_panel_material.albedo_color = Color(0.16, 0.7, 0.26)
			exit_panel_material.emission = Color(0.16, 0.7, 0.26)
			exit_light.light_color = Color(0.22, 0.92, 0.35)
			exit_light.light_energy = 4.5
			safe_zone_material.emission_energy_multiplier = 1.5
		"failure":
			smoke_target = 1.15
			machine_color_target = Color(0.46, 0.2, 0.18)
			exit_panel_material.albedo_color = Color(0.82, 0.2, 0.15)
			exit_panel_material.emission = Color(0.82, 0.2, 0.15)
			safe_zone_material.emission_energy_multiplier = 0.8
		"success":
			smoke_target = 0.2
			machine_color_target = Color(0.24, 0.31, 0.28)
			exit_panel_material.albedo_color = Color(0.16, 0.7, 0.26)
			exit_panel_material.emission = Color(0.16, 0.7, 0.26)
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


func _make_box_body(
	name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	material: Material = null
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material if material != null else _make_metal_material(color, 0.9, 0.04)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	return body


func _make_visual_box(
	size: Vector3,
	position: Vector3,
	color: Color,
	emissive: bool,
	material: Material = null,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees

	var applied_material := material
	if applied_material == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = color
		fallback.roughness = 0.7
		if emissive:
			fallback.emission_enabled = true
			fallback.emission = color
			fallback.emission_energy_multiplier = 1.0
		applied_material = fallback

	mesh_instance.material_override = applied_material
	return mesh_instance


func _make_interactable_panel(
	name: String,
	action_id: String,
	prompt_text: String,
	position: Vector3,
	size: Vector3,
	material: StandardMaterial3D,
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
	mesh_instance.material_override = material
	area.add_child(mesh_instance)

	area.add_child(_make_label(label_text, Vector3(0.0, 0.56, 0.0), Color(1.0, 1.0, 1.0), 34))
	return area


func _make_label(text: String, position: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.font_size = font_size
	label.outline_size = 8
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	return label


func _make_scene_prop(scene: PackedScene, position: Vector3, scale_value: Vector3, rotation_value: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = position
	root.scale = scale_value
	root.rotation_degrees = rotation_value
	root.add_child(scene.instantiate())
	return root


func _make_textured_material(
	texture: Texture2D,
	uv_scale: Vector3,
	roughness: float,
	metallic: float,
	tint: Color
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = texture
	material.uv1_scale = uv_scale
	material.roughness = roughness
	material.metallic = metallic
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material


func _make_metal_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_panel_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34
	material.metallic = 0.06
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.95
	return material
