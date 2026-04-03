extends Node3D

const Interactable = preload("res://scripts/interactable.gd")
const FLOOR_TEXTURE: Texture2D = preload("res://assets/textures/variation-c.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/textures/variation-a.png")
const DETAIL_TANK_SCENE: PackedScene = preload("res://assets/models/detail-tank.glb")
const CHIMNEY_SMALL_SCENE: PackedScene = preload("res://assets/models/chimney-small.glb")

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	_configure_player_spawn()
	_configure_environment()
	_build_world()
	_connect_signals()
	_setup_hud()


func _configure_player_spawn() -> void:
	player.global_position = Vector3(5.6, 0.0, 4.2)
	player.rotation_degrees = Vector3(0.0, -140.0, 0.0)


func _configure_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.11, 0.13, 0.16)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.64, 0.69, 0.76)
	environment.ambient_light_energy = 1.25
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment


func _build_world() -> void:
	var root := Node3D.new()
	root.name = "WorldRoot"
	add_child(root)

	var asphalt := _make_textured_material(FLOOR_TEXTURE, Vector3(5.0, 5.0, 1.0), 0.95, Color(0.76, 0.78, 0.81))
	var wall_material := _make_textured_material(WALL_TEXTURE, Vector3(1.6, 1.0, 1.0), 0.88, Color(0.9, 0.92, 0.95))
	var dark_metal := _make_metal_material(Color(0.17, 0.19, 0.24), 0.62, 0.18)
	var fence_material := _make_metal_material(Color(0.24, 0.27, 0.31), 0.48, 0.12)

	root.add_child(_make_box_body(Vector3(16.0, 0.2, 14.0), Vector3(0.0, -0.1, 0.0), asphalt))
	root.add_child(_make_box_body(Vector3(0.3, 2.4, 14.0), Vector3(-7.85, 1.2, 0.0), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 2.4, 14.0), Vector3(7.85, 1.2, 0.0), wall_material))
	root.add_child(_make_box_body(Vector3(16.0, 2.4, 0.3), Vector3(0.0, 1.2, 6.85), wall_material))
	root.add_child(_make_box_body(Vector3(9.2, 2.4, 0.3), Vector3(3.4, 1.2, -6.85), wall_material))
	root.add_child(_make_box_body(Vector3(2.2, 2.4, 0.3), Vector3(-6.7, 1.2, -6.85), wall_material))

	root.add_child(_make_box_body(Vector3(0.18, 2.6, 2.8), Vector3(-5.45, 1.3, -5.45), dark_metal))
	root.add_child(_make_box_body(Vector3(5.0, 0.18, 2.8), Vector3(-2.95, 2.6, -5.45), dark_metal))
	root.add_child(_make_box_body(Vector3(0.18, 2.6, 2.8), Vector3(-0.45, 1.3, -5.45), dark_metal))

	for fence_z in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		root.add_child(_make_box_body(Vector3(0.12, 1.9, 0.12), Vector3(5.9, 0.95, fence_z), fence_material))
		root.add_child(_make_box_body(Vector3(0.12, 1.9, 0.12), Vector3(3.7, 0.95, fence_z), fence_material))
	for rail_z in [-3.0, 1.0]:
		root.add_child(_make_visual_box(Vector3(2.25, 0.08, 0.08), Vector3(4.8, 0.7 + rail_z / 10.0, rail_z), Color(0.24, 0.27, 0.31), false, fence_material))
		root.add_child(_make_visual_box(Vector3(2.25, 0.08, 0.08), Vector3(4.8, 1.35 + rail_z / 10.0, rail_z), Color(0.24, 0.27, 0.31), false, fence_material))

	root.add_child(_make_visual_box(Vector3(1.6, 0.04, 7.6), Vector3(0.0, 0.02, 1.2), Color(0.16, 0.68, 0.28), true))
	root.add_child(_make_visual_box(Vector3(5.4, 0.04, 0.34), Vector3(-2.7, 0.02, -4.2), Color(0.16, 0.68, 0.28), true))
	root.add_child(_make_visual_box(Vector3(2.5, 0.04, 2.5), Vector3(-5.5, 0.02, -5.45), Color(0.16, 0.68, 0.28), true))

	root.add_child(_make_visual_box(Vector3(3.0, 0.16, 1.5), Vector3(5.1, 0.08, 4.5), Color(0.18, 0.2, 0.24), false, dark_metal))
	root.add_child(_make_visual_box(Vector3(2.2, 0.98, 1.3), Vector3(5.1, 0.57, 4.5), Color(0.22, 0.25, 0.3), false, fence_material))
	root.add_child(_make_scene_prop(DETAIL_TANK_SCENE, Vector3(6.15, 0.0, -4.85), Vector3(1.8, 1.8, 1.8), Vector3(0.0, 90.0, 0.0)))
	root.add_child(_make_scene_prop(CHIMNEY_SMALL_SCENE, Vector3(6.2, 0.0, 5.4), Vector3(1.4, 1.4, 1.4), Vector3.ZERO))

	root.add_child(_make_label("Маршрут эвакуации", Vector3(0.0, 2.8, 3.0), Color(0.96, 0.95, 0.86), 34))
	root.add_child(_make_label("Пункт сбора", Vector3(-5.5, 1.1, -5.45), Color(0.78, 1.0, 0.82), 34))
	root.add_child(_make_label("Назад в опасную зону", Vector3(4.8, 2.1, -5.85), Color(1.0, 0.82, 0.82), 28))

	_build_interactions(root)
	_build_lights(root)


func _build_interactions(parent: Node3D) -> void:
	var assembly_material := _make_panel_material(Color(0.18, 0.72, 0.28))
	parent.add_child(_make_interactable_panel(
		"AssemblyTerminal",
		"assembly",
		"[E] Подтвердить эвакуацию",
		Vector3(-5.5, 1.05, -5.45),
		Vector3(0.56, 0.76, 0.32),
		assembly_material,
		"СБОР"
	))

	var danger_material := _make_panel_material(Color(0.82, 0.18, 0.12))
	parent.add_child(_make_interactable_panel(
		"DangerDoor",
		"danger",
		"[E] Вернуться к оборудованию",
		Vector3(3.75, 1.2, -5.45),
		Vector3(0.3, 0.86, 1.1),
		danger_material,
		"ОПАСНО"
	))
	parent.add_child(_make_box_body(Vector3(0.16, 2.5, 1.9), Vector3(4.08, 1.25, -5.45), _make_metal_material(Color(0.18, 0.19, 0.22), 0.62, 0.08)))


func _build_lights(parent: Node3D) -> void:
	for light_pos in [Vector3(-4.2, 3.0, 2.8), Vector3(0.0, 3.0, 0.0), Vector3(-5.5, 2.6, -5.45)]:
		parent.add_child(_make_visual_box(Vector3(1.8, 0.08, 0.38), light_pos, Color(0.88, 0.92, 0.96), true))
		var lamp := OmniLight3D.new()
		lamp.position = light_pos + Vector3(0.0, -0.2, 0.0)
		lamp.light_color = Color(0.9, 0.95, 1.0)
		lamp.light_energy = 1.5
		lamp.omni_range = 5.6
		parent.add_child(lamp)


func _connect_signals() -> void:
	player.prompt_changed.connect(hud.set_interaction_prompt)
	player.interact_requested.connect(_on_player_interact)


func _setup_hud() -> void:
	hud.set_objective("6. Дойдите до пункта сбора и подтвердите завершение эвакуации.")
	hud.set_hint("Следуйте по зелёной разметке. Не возвращайтесь к опасному производственному модулю.")
	hud.set_warning_banner("[ЭВАКУАЦИЯ] Двигайтесь к безопасной точке сбора.", "warning")
	hud.show_feedback("Финальный этап: уйдите в пункт сбора и отметьтесь о завершении эвакуации.", "info")


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
		"Вы остановили основной модуль, создали дистанцию, вызвали помощь, отключили резервный генератор и завершили эвакуацию в пункте сбора.",
		[
			"Аварийная остановка основного оборудования выполнена",
			"Безопасная дистанция соблюдена",
			"Помощь вызвана до выхода из зоны риска",
			"Резервный генератор GEN-02 отключён",
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

	area.add_child(_make_label(label_text, Vector3(0.0, 0.74, 0.0), Color(1.0, 1.0, 1.0), 30))
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
