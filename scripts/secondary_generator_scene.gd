extends Node3D

const Interactable = preload("res://scripts/interactable.gd")
const FLOOR_TEXTURE: Texture2D = preload("res://assets/textures/variation-c.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/textures/variation-b.png")
const DETAIL_TANK_SCENE: PackedScene = preload("res://assets/models/detail-tank.glb")
const CHIMNEY_SMALL_SCENE: PackedScene = preload("res://assets/models/chimney-small.glb")

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var generator_disabled: bool = false
var generator_body_material: StandardMaterial3D
var switch_material: StandardMaterial3D
var exit_panel_material: StandardMaterial3D
var warning_light: OmniLight3D
var status_lamp_material: StandardMaterial3D
var exit_light: OmniLight3D
var smoke_root: Node3D
var smoke_puffs: Array[MeshInstance3D] = []
var smoke_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_configure_player_spawn()
	_configure_environment()
	_build_world()
	_connect_signals()
	_setup_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _process(delta: float) -> void:
	_update_warning_light()
	_update_smoke(delta)


func _configure_player_spawn() -> void:
	player.global_position = Vector3(4.2, 0.0, 2.8)
	player.rotation_degrees = Vector3(0.0, -140.0, 0.0)


func _configure_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.06, 0.07, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.54, 0.6, 0.68)
	environment.ambient_light_energy = 1.1
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment


func _build_world() -> void:
	var root := Node3D.new()
	root.name = "WorldRoot"
	add_child(root)

	var floor_material := _make_textured_material(FLOOR_TEXTURE, Vector3(3.3, 3.3, 1.0), 0.95, Color(0.88, 0.9, 0.92))
	var wall_material := _make_textured_material(WALL_TEXTURE, Vector3(1.9, 1.2, 1.0), 0.9, Color(0.94, 0.95, 0.98))
	var dark_metal := _make_metal_material(Color(0.17, 0.19, 0.23), 0.62, 0.18)

	root.add_child(_make_box_body(Vector3(11.0, 0.2, 9.0), Vector3(0.0, -0.1, 0.0), floor_material))
	root.add_child(_make_box_body(Vector3(11.0, 0.2, 9.0), Vector3(0.0, 3.8, 0.0), wall_material))
	root.add_child(_make_box_body(Vector3(11.0, 4.0, 0.3), Vector3(0.0, 1.9, -4.35), wall_material))
	root.add_child(_make_box_body(Vector3(11.0, 4.0, 0.3), Vector3(0.0, 1.9, 4.35), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 4.0, 9.0), Vector3(5.35, 1.9, 0.0), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 4.0, 3.4), Vector3(-5.35, 1.9, 2.65), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 1.2, 1.9), Vector3(-5.35, 3.4, -1.95), dark_metal))
	root.add_child(_make_box_body(Vector3(0.3, 1.4, 3.7), Vector3(-5.35, 0.7, -2.85), dark_metal))

	for beam_z in [-2.9, 0.0, 2.9]:
		root.add_child(_make_box_body(Vector3(10.6, 0.18, 0.35), Vector3(0.0, 3.4, beam_z), dark_metal))

	root.add_child(_make_visual_box(Vector3(0.26, 0.26, 6.4), Vector3(4.4, 3.55, 0.0), Color(0.26, 0.29, 0.34), false, dark_metal))
	root.add_child(_make_visual_box(Vector3(0.26, 0.26, 6.4), Vector3(3.8, 3.55, 0.0), Color(0.26, 0.29, 0.34), false, dark_metal))
	root.add_child(_make_visual_box(Vector3(2.4, 0.04, 0.34), Vector3(1.2, 0.02, 1.0), Color(0.95, 0.74, 0.14), true))
	root.add_child(_make_visual_box(Vector3(0.34, 0.04, 2.8), Vector3(-0.95, 0.02, -0.4), Color(0.95, 0.74, 0.14), true))
	root.add_child(_make_visual_box(Vector3(2.8, 0.04, 0.34), Vector3(-3.1, 0.02, -2.4), Color(0.18, 0.72, 0.3), true))

	root.add_child(_make_scene_prop(DETAIL_TANK_SCENE, Vector3(4.15, 0.0, -3.1), Vector3(1.9, 1.9, 1.9), Vector3(0.0, 90.0, 0.0)))
	root.add_child(_make_scene_prop(CHIMNEY_SMALL_SCENE, Vector3(3.2, 0.0, 3.25), Vector3(1.4, 1.4, 1.4), Vector3.ZERO))

	_build_generator(root)
	_build_exit(root)
	_build_lights(root)


func _build_generator(parent: Node3D) -> void:
	var rig := Node3D.new()
	rig.position = Vector3(-1.25, 0.0, -0.8)
	parent.add_child(rig)

	generator_body_material = _make_metal_material(Color(0.36, 0.4, 0.46), 0.46, 0.16)
	rig.add_child(_make_visual_box(Vector3(3.1, 0.2, 2.1), Vector3(0.0, 0.1, 0.0), Color(0.14, 0.16, 0.2), false, _make_metal_material(Color(0.14, 0.16, 0.2), 0.72, 0.06)))
	rig.add_child(_make_visual_box(Vector3(2.6, 1.0, 1.8), Vector3(0.0, 0.62, 0.0), Color(0.36, 0.4, 0.46), false, generator_body_material))
	rig.add_child(_make_visual_box(Vector3(0.94, 1.28, 0.8), Vector3(0.92, 0.86, 0.44), Color(0.21, 0.24, 0.29), false, _make_metal_material(Color(0.21, 0.24, 0.29), 0.4, 0.1)))

	for tank_pos in [Vector3(-0.72, 1.24, -0.44), Vector3(-0.72, 1.24, 0.44)]:
		var tank_mesh := MeshInstance3D.new()
		var tank := CylinderMesh.new()
		tank.top_radius = 0.28
		tank.bottom_radius = 0.28
		tank.height = 1.6
		tank_mesh.mesh = tank
		tank_mesh.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		tank_mesh.position = tank_pos
		tank_mesh.material_override = generator_body_material
		rig.add_child(tank_mesh)

	status_lamp_material = _make_metal_material(Color(1.0, 0.22, 0.12), 0.22, 0.0)
	status_lamp_material.emission_enabled = true
	status_lamp_material.emission = Color(1.0, 0.22, 0.12)
	status_lamp_material.emission_energy_multiplier = 2.2
	var lamp := MeshInstance3D.new()
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.15
	lamp_mesh.height = 0.3
	lamp.mesh = lamp_mesh
	lamp.material_override = status_lamp_material
	lamp.position = Vector3(0.94, 1.98, 0.44)
	rig.add_child(lamp)

	warning_light = OmniLight3D.new()
	warning_light.position = Vector3(0.94, 2.0, 0.44)
	warning_light.light_color = Color(1.0, 0.24, 0.14)
	warning_light.light_energy = 4.6
	warning_light.omni_range = 5.2
	rig.add_child(warning_light)

	smoke_root = Node3D.new()
	smoke_root.position = Vector3(-1.72, 1.72, 0.0)
	rig.add_child(smoke_root)
	for index in range(4):
		var puff := MeshInstance3D.new()
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 0.16 + index * 0.03
		puff_mesh.height = 0.32 + index * 0.05
		puff.mesh = puff_mesh
		var smoke_material := StandardMaterial3D.new()
		smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_material.albedo_color = Color(0.18, 0.18, 0.18, 0.22)
		smoke_material.roughness = 1.0
		smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = smoke_material
		smoke_root.add_child(puff)
		smoke_puffs.append(puff)
		smoke_materials.append(smoke_material)

	switch_material = _make_panel_material(Color(0.95, 0.68, 0.08))
	parent.add_child(_make_interactable_panel(
		"GeneratorSwitch",
		"generator_switch",
		"[E] Отключить резервный генератор",
		Vector3(1.0, 1.1, -1.2),
		Vector3(0.58, 0.62, 0.26),
		switch_material,
		"GEN-02"
	))

	parent.add_child(_make_label("Резервный генератор", Vector3(-1.1, 2.6, -0.8), Color(1.0, 0.96, 0.84), 34))


func _build_exit(parent: Node3D) -> void:
	exit_panel_material = _make_panel_material(Color(0.82, 0.18, 0.14))
	parent.add_child(_make_interactable_panel(
		"ExitDoor",
		"exit_annex",
		"[E] Перейти к эвакуации",
		Vector3(-4.75, 1.18, -2.0),
		Vector3(0.24, 0.56, 0.9),
		exit_panel_material,
		"ШЛЮЗ"
	))
	parent.add_child(_make_visual_box(Vector3(0.16, 2.4, 1.7), Vector3(-5.08, 1.2, -2.0), Color(0.14, 0.18, 0.18), false, _make_metal_material(Color(0.14, 0.18, 0.18), 0.66, 0.06)))

	exit_light = OmniLight3D.new()
	exit_light.position = Vector3(-4.9, 2.0, -2.0)
	exit_light.light_color = Color(0.88, 0.18, 0.12)
	exit_light.light_energy = 2.2
	exit_light.omni_range = 3.6
	parent.add_child(exit_light)

	parent.add_child(_make_label("ПЕРЕХОД К ЭВАКУАЦИИ", Vector3(-3.65, 2.5, -2.0), Color(0.92, 0.98, 0.92), 28))


func _build_lights(parent: Node3D) -> void:
	for light_pos in [Vector3(-2.8, 3.55, -2.9), Vector3(-2.8, 3.55, 0.0), Vector3(-2.8, 3.55, 2.9)]:
		parent.add_child(_make_visual_box(Vector3(2.0, 0.08, 0.4), light_pos, Color(0.88, 0.92, 0.96), true))
		var lamp := OmniLight3D.new()
		lamp.position = light_pos + Vector3(0.0, -0.18, 0.0)
		lamp.light_color = Color(0.9, 0.94, 1.0)
		lamp.light_energy = 1.4
		lamp.omni_range = 5.2
		parent.add_child(lamp)


func _connect_signals() -> void:
	player.prompt_changed.connect(hud.set_interaction_prompt)
	player.interact_requested.connect(_on_player_interact)
	hud.restart_requested.connect(func() -> void:
		get_tree().reload_current_scene()
	)


func _setup_hud() -> void:
	hud.set_objective("5. Отключите резервный генератор и пройдите в шлюз эвакуации.")
	hud.set_hint("Панель отключения находится на модуле GEN-02. После отключения переход к выходу откроется.")
	hud.set_warning_banner("[МОДУЛЬ GEN-02] Резервный генератор всё ещё под нагрузкой.", "warning")
	hud.show_feedback("Покинуть производственный блок пока нельзя: сначала нужно обесточить соседний резервный генератор.", "info")


func _on_player_interact(interactable: Interactable) -> void:
	match interactable.action_id:
		"generator_switch":
			_disable_generator()
		"exit_annex":
			_try_exit()


func _disable_generator() -> void:
	if generator_disabled:
		hud.show_feedback("Резервный генератор уже обесточен.", "info")
		return

	generator_disabled = true
	switch_material.albedo_color = Color(0.18, 0.72, 0.28)
	switch_material.emission = Color(0.18, 0.72, 0.28)
	status_lamp_material.albedo_color = Color(0.2, 0.86, 0.34)
	status_lamp_material.emission = Color(0.2, 0.86, 0.34)
	exit_panel_material.albedo_color = Color(0.18, 0.72, 0.28)
	exit_panel_material.emission = Color(0.18, 0.72, 0.28)
	exit_light.light_color = Color(0.2, 0.92, 0.36)
	exit_light.light_energy = 4.6
	hud.set_objective("5. Резервный генератор отключён. Пройдите в шлюз эвакуации.")
	hud.set_hint("Опасная нагрузка снята. Двигайтесь к панели шлюза слева и завершайте переход к эвакуации.")
	hud.set_warning_banner("[МОДУЛЬ GEN-02] Питание снято. Переход к эвакуации разрешён.", "safe")
	hud.show_feedback("Резервный генератор отключён. Теперь можно безопасно уходить в эвакуационный коридор.", "success")


func _try_exit() -> void:
	if not generator_disabled:
		hud.show_feedback("Сначала отключите резервный генератор. Иначе соседний модуль остаётся под риском.", "warning")
		return

	if GameSession.workshop_summary.is_empty():
		GameSession.set_workshop_summary("Первичный очаг локализован, затем резервный генератор был обесточен перед эвакуацией.")
	else:
		GameSession.set_workshop_summary("%s После выхода из цеха резервный генератор был обесточен в соседнем модуле." % GameSession.workshop_summary)

	get_tree().change_scene_to_file("res://scenes/Evacuation.tscn")


func _update_warning_light() -> void:
	var pulse := 0.58 + 0.42 * sin(Time.get_ticks_msec() * 0.008)
	if generator_disabled:
		warning_light.visible = false
		status_lamp_material.emission_energy_multiplier = 1.2
		return

	warning_light.visible = true
	warning_light.light_energy = 3.0 + pulse * 2.0
	status_lamp_material.emission_energy_multiplier = 1.8 + pulse * 1.6


func _update_smoke(delta: float) -> void:
	var target := 0.08 if generator_disabled else 0.42
	var time := Time.get_ticks_msec() * 0.001
	for index in smoke_puffs.size():
		var puff := smoke_puffs[index]
		var material := smoke_materials[index]
		var rise := fmod(time * (0.3 + index * 0.05) + index * 0.18, 1.3)
		puff.position = Vector3(sin(time + index) * 0.12, rise * target * 2.0, cos(time * 1.2 + index) * 0.09)
		puff.scale = Vector3.ONE * (0.7 + rise * 0.22 + target)
		var alpha := clampf(0.04 + target * 0.4 - rise * 0.04, 0.02, 0.22)
		material.albedo_color = material.albedo_color.lerp(Color(0.18, 0.18, 0.18, alpha), delta * 3.0)


func _make_box_body(size: Vector3, position: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
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
	material: Material = null
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
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

	area.add_child(_make_label(label_text, Vector3(0.0, 0.56, 0.0), Color(1.0, 1.0, 1.0), 30))
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


func _make_textured_material(texture: Texture2D, uv_scale: Vector3, roughness: float, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.uv1_scale = uv_scale
	material.roughness = roughness
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
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.0
	return material
