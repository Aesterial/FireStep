extends Node3D

const Interactable = preload("res://scripts/interactable.gd")
const FLOOR_TEXTURE: Texture2D = preload("res://assets/textures/prototype/dark_04.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/textures/prototype/light_04.png")
const CEILING_TEXTURE: Texture2D = preload("res://assets/textures/prototype/dark_02.png")
const DETAIL_TANK_SCENE: PackedScene = preload("res://assets/models/detail-tank.glb")
const CHIMNEY_SMALL_SCENE: PackedScene = preload("res://assets/models/chimney-small.glb")

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var blocks_disabled: int = 0
var block_materials: Array[StandardMaterial3D] = []
var exit_panel_material: StandardMaterial3D
var warning_light: OmniLight3D
var exit_light: OmniLight3D
var main_lights: Array[OmniLight3D] = []


func _ready() -> void:
	if not GameSession.ensure_authenticated(get_tree()):
		return
	_configure_player_spawn()
	_configure_environment()
	_build_world()
	_connect_signals()
	_setup_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _configure_player_spawn() -> void:
	player.global_position = Vector3(0.0, 0.0, 4.0)
	player.rotation_degrees = Vector3(0.0, 0.0, 0.0)


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
	var ceiling_material := _make_textured_material(CEILING_TEXTURE, Vector3(3.3, 3.3, 1.0), 0.9, Color(0.88, 0.9, 0.92))

	root.add_child(_make_box_body(Vector3(12.0, 0.2, 12.0), Vector3(0.0, -0.1, 0.0), floor_material))
	root.add_child(_make_box_body(Vector3(12.0, 0.2, 12.0), Vector3(0.0, 4.0, 0.0), ceiling_material))
	root.add_child(_make_box_body(Vector3(12.0, 4.0, 0.3), Vector3(0.0, 1.9, -4.35), wall_material))
	root.add_child(_make_box_body(Vector3(11.0, 4.0, 0.3), Vector3(0.0, 1.9, 4.35), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 4.0, 12.0), Vector3(5.35, 1.9, 0.0), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 4.0, 12.0), Vector3(-5.35, 1.9, 0.0), wall_material))

	_build_equipment(root)
	_build_exit(root)
	_build_props(root)
	_build_lights(root)


func _build_props(parent: Node3D) -> void:
	var dark_metal := _make_metal_material(Color(0.17, 0.19, 0.23), 0.62, 0.18)
	var accent_metal := _make_metal_material(Color(0.24, 0.27, 0.31), 0.45, 0.18)

	for beam_z in [-3.5, 0.0, 3.5]:
		parent.add_child(_make_box_body(Vector3(11.6, 0.2, 0.4), Vector3(0.0, 3.8, beam_z), dark_metal))

	parent.add_child(_make_scene_prop(DETAIL_TANK_SCENE, Vector3(-4.8, 0.0, 4.8), Vector3(2.5, 2.5, 2.5), Vector3(0.0, 45.0, 0.0)))
	parent.add_child(_make_scene_prop(DETAIL_TANK_SCENE, Vector3(4.8, 0.0, 4.8), Vector3(2.5, 2.5, 2.5), Vector3(0.0, -45.0, 0.0)))

	parent.add_child(_make_scene_prop(CHIMNEY_SMALL_SCENE, Vector3(-4.8, 0.0, -4.5), Vector3(2.0, 2.0, 2.0), Vector3.ZERO))
	parent.add_child(_make_scene_prop(CHIMNEY_SMALL_SCENE, Vector3(4.8, 0.0, 0.5), Vector3(1.8, 1.8, 1.8), Vector3.ZERO))

	parent.add_child(_make_box_body(Vector3(1.8, 2.4, 1.8), Vector3(-4.8, 1.2, -4.8), dark_metal))
	parent.add_child(_make_box_body(Vector3(1.8, 2.4, 1.8), Vector3(4.8, 1.2, -4.8), dark_metal))


func _build_equipment(parent: Node3D) -> void:
	var mat1 := _make_panel_material(Color(0.95, 0.68, 0.08))
	block_materials.append(mat1)
	parent.add_child(_make_interactable_panel(
		"PowerBlock1",
		"block_1",
		"Отключить щиток 1",
		Vector3(0.0, 1.5, -5.6),
		Vector3(1.2, 1.4, 0.2),
		mat1,
		"ЩИТ 1"
	))

	var mat2 := _make_panel_material(Color(0.95, 0.68, 0.08))
	block_materials.append(mat2)
	var panel2 = _make_interactable_panel(
		"PowerBlock2",
		"block_2",
		"Отключить щиток 2",
		Vector3(-5.6, 1.5, 0.0),
		Vector3(0.2, 1.4, 1.2),
		mat2,
		"ЩИТ 2"
	)
	parent.add_child(panel2)
	var label2 = panel2.get_child(2) as Label3D
	label2.position = Vector3(0.16, 0.0, 0.0)
	label2.rotation_degrees = Vector3(0, 90, 0)

	var mat3 := _make_panel_material(Color(0.95, 0.68, 0.08))
	block_materials.append(mat3)
	var panel3 = _make_interactable_panel(
		"PowerBlock3",
		"block_3",
		"Отключить щиток 3",
		Vector3(5.6, 1.5, 0.0),
		Vector3(0.2, 1.4, 1.2),
		mat3,
		"ЩИТ 3"
	)
	parent.add_child(panel3)
	var label3 = panel3.get_child(2) as Label3D
	label3.position = Vector3(-0.16, 0.0, 0.0)
	label3.rotation_degrees = Vector3(0, -90, 0)


func _build_exit(parent: Node3D) -> void:
	exit_panel_material = _make_panel_material(Color(0.82, 0.18, 0.14))
	parent.add_child(_make_interactable_panel(
		"ExitDoor",
		"exit_annex",
		"Перейти к эвакуации",
		Vector3(3.0, 1.18, -5.6),
		Vector3(1.2, 2.36, 0.2),
		exit_panel_material,
		"ШЛЮЗ"
	))

	exit_light = OmniLight3D.new()
	exit_light.position = Vector3(3.0, 2.6, -5.0)
	exit_light.light_color = Color(0.88, 0.18, 0.12)
	exit_light.light_energy = 2.2
	exit_light.omni_range = 3.6
	parent.add_child(exit_light)

	parent.add_child(_make_label("ВЫХОД В КОРИДОР", Vector3(3.0, 2.8, -5.6), Color(0.92, 0.98, 0.92), 28))


func _build_lights(parent: Node3D) -> void:
	for light_pos in [Vector3(-2.5, 3.8, -2.5), Vector3(2.5, 3.8, -2.5), Vector3(-2.5, 3.8, 2.5), Vector3(2.5, 3.8, 2.5)]:
		var fixture = _make_visual_box(Vector3(1.5, 0.1, 0.4), light_pos, Color(0.8, 0.8, 0.8), true)
		parent.add_child(fixture)
		var lamp := OmniLight3D.new()
		lamp.position = light_pos + Vector3(0.0, -0.2, 0.0)
		lamp.light_color = Color(0.9, 0.95, 1.0)
		lamp.light_energy = 1.0
		lamp.omni_range = 8.0
		parent.add_child(lamp)
		main_lights.append(lamp)

	warning_light = OmniLight3D.new()
	warning_light.position = Vector3(0.0, 3.5, 0.0)
	warning_light.light_color = Color(1.0, 0.24, 0.14)
	warning_light.light_energy = 2.0
	warning_light.omni_range = 8.0
	parent.add_child(warning_light)


func _process(delta: float) -> void:
	_update_warning_light()


func _update_warning_light() -> void:
	var pulse := 0.58 + 0.42 * sin(Time.get_ticks_msec() * 0.008)
	if blocks_disabled >= 3:
		warning_light.visible = false
		return

	warning_light.visible = true
	warning_light.light_energy = 1.0 + pulse * 1.5


func _connect_signals() -> void:
	player.prompt_changed.connect(hud.set_interaction_prompt)
	player.interact_requested.connect(_on_player_interact)
	hud.restart_requested.connect(func() -> void:
		get_tree().reload_current_scene()
	)


func _setup_hud() -> void:
	hud.set_objective("Отключите все 3 электрощитка перед эвакуацией.")
	hud.set_hint("Найдите на стенах 3 оранжевых панели и отключите их.")
	hud.set_warning_banner("[ПИТАНИЕ] Высокое напряжение в модуле.", "warning")
	hud.show_feedback("Переход заблокирован: необходимо полностью обесточить модуль.", "info")


func _on_player_interact(interactable: Interactable) -> void:
	match interactable.action_id:
		"block_1":
			_disable_block(0, interactable)
		"block_2":
			_disable_block(1, interactable)
		"block_3":
			_disable_block(2, interactable)
		"exit_annex":
			_try_exit()


func _disable_block(index: int, interactable: Interactable) -> void:
	if not interactable.active:
		return

	GameSession.record_action("power_shutdown/disable_block_%d" % (index + 1))
	interactable.active = false
	var mat = block_materials[index]
	mat.albedo_color = Color(0.18, 0.72, 0.28)
	mat.emission = Color(0.18, 0.72, 0.28)

	blocks_disabled += 1

	if blocks_disabled < 3:
		hud.show_feedback("Отключено щитков: %d из 3." % blocks_disabled, "info")
	else:
		_all_blocks_disabled()


func _all_blocks_disabled() -> void:
	for lamp in main_lights:
		lamp.visible = false

	exit_panel_material.albedo_color = Color(0.18, 0.72, 0.28)
	exit_panel_material.emission = Color(0.18, 0.72, 0.28)
	exit_light.light_color = Color(0.2, 0.92, 0.36)
	exit_light.light_energy = 4.6
	hud.set_objective("Все щитки отключены. Пройдите в шлюз эвакуации.")
	hud.set_hint("Питание полностью снято. Двигайтесь к выходу.")
	hud.set_warning_banner("[ПИТАНИЕ] Напряжение снято. Переход к эвакуации разрешён.", "safe")
	hud.show_feedback("Все щитки отключены. Теперь можно безопасно уходить.", "success")


func _try_exit() -> void:
	if blocks_disabled < 3:
		GameSession.record_action("power_shutdown/exit_blocked")
		GameSession.add_error()
		hud.show_feedback("Сначала отключите все 3 электрощитка.", "warning")
		return

	GameSession.record_action("power_shutdown/exit_to_evacuation")

	if GameSession.workshop_summary.is_empty():
		GameSession.set_workshop_summary("Затем были обесточены все 3 щитка.")
	else:
		GameSession.set_workshop_summary("%s Затем были полностью обесточены 3 щитка." % GameSession.workshop_summary)

	get_tree().change_scene_to_file("res://scenes/Evacuation.tscn")


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

	area.add_child(_make_label(label_text, Vector3(0.0, size.y/2 + 0.16, 0.0), Color(1.0, 1.0, 1.0), 30))
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
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
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
