extends Node3D

const Interactable = preload("res://scripts/interactable.gd")
const FLOOR_TEXTURE: Texture2D = preload("res://assets/textures/prototype/dark_04.png")
const WALL_TEXTURE: Texture2D = preload("res://assets/textures/prototype/light_04.png")
const CEILING_TEXTURE: Texture2D = preload("res://assets/textures/prototype/dark_02.png")

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD


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
	var dark_metal := _make_metal_material(Color(0.17, 0.19, 0.23), 0.62, 0.18)

	root.add_child(_make_box_body(Vector3(12.0, 0.2, 12.0), Vector3(0.0, -0.1, 0.0), floor_material))
	root.add_child(_make_box_body(Vector3(12.0, 0.2, 12.0), Vector3(0.0, 4.0, 0.0), floor_material))
	root.add_child(_make_box_body(Vector3(12.0, 4.0, 0.3), Vector3(0.0, 2.0, -5.85), wall_material))
	root.add_child(_make_box_body(Vector3(12.0, 4.0, 0.3), Vector3(0.0, 2.0, 5.85), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 4.0, 12.0), Vector3(5.85, 2.0, 0.0), wall_material))
	root.add_child(_make_box_body(Vector3(0.3, 4.0, 12.0), Vector3(-5.85, 2.0, 0.0), wall_material))

	_build_equipment(root)
	_build_lights(root)


var config_label: Label3D

func _build_equipment(parent: Node3D) -> void:
	var panel_mat := _make_panel_material(Color(0.2, 0.6, 0.8))
	parent.add_child(_make_interactable_panel(
		"TestTerminal",
		"test_interaction",
		"Проверить терминал",
		Vector3(0.0, 1.0, -5.5),
		Vector3(1.2, 0.8, 0.4),
		panel_mat,
		"TEST"
	))

	var exit_mat := _make_panel_material(Color(0.8, 0.2, 0.1))
	parent.add_child(_make_interactable_panel(
		"ExitDoor",
		"start_main",
		"Запустить сценарий",
		Vector3(5.5, 1.2, 0.0),
		Vector3(0.4, 2.4, 1.6),
		exit_mat,
		"СТАРТ"
	))

	parent.add_child(_make_label("Тренировочный терминал", Vector3(0.0, 2.0, -5.5), Color(1.0, 1.0, 1.0), 40))
	
	config_label = _make_label("", Vector3(-5.5, 2.0, 0.0), Color(0.8, 1.0, 0.8), 32)
	config_label.rotation_degrees = Vector3(0, 90, 0)
	parent.add_child(config_label)
	_update_config_label(GameSession.input_mode)

func _build_lights(parent: Node3D) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 3.5, 0.0)
	lamp.light_color = Color(0.9, 0.95, 1.0)
	lamp.light_energy = 2.0
	lamp.omni_range = 10.0
	parent.add_child(lamp)

func _update_config_label(mode: String) -> void:
	if config_label == null:
		return
	if mode == "keyboard":
		config_label.text = "Клавиатура/Мышь\nДвижение: WASD\nОсмотр: Мышь\nБег: Shift\nВзаимодействие: E"
	else:
		config_label.text = "Геймпад\nДвижение: Лев. стик\nОсмотр: Прав. стик\nЧувствительность: " + str(GameSession.gamepad_look_sensitivity) + "\nМертвая зона: " + str(GameSession.gamepad_deadzone)

func _connect_signals() -> void:
	player.prompt_changed.connect(hud.set_interaction_prompt)
	player.interact_requested.connect(_on_player_interact)
	GameSession.input_mode_changed.connect(_update_config_label)
	hud.restart_requested.connect(func() -> void:
		get_tree().reload_current_scene()
	)


func _setup_hud() -> void:
	hud.set_objective("Ознакомьтесь с управлением.")
	hud.set_hint("Используйте движение и осмотр. Нажмите кнопку взаимодействия на терминале.")
	hud.set_warning_banner("[ЛАБОРАТОРИЯ] Обучение", "info")
	hud.show_feedback("Добро пожаловать в учебный модуль. Освойте базовые механики и переходите к сценарию.", "info")


func _on_player_interact(interactable: Interactable) -> void:
	match interactable.action_id:
		"test_interaction":
			GameSession.record_action("controls_lab/test_terminal")
			hud.show_feedback("Взаимодействие работает успешно!", "success")
		"start_main":
			GameSession.record_action("controls_lab/start_scenario")
			get_tree().change_scene_to_file("res://scenes/Main.tscn")


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
