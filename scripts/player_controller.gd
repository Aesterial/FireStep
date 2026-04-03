extends CharacterBody3D

signal prompt_changed(text: String)
signal interact_requested(interactable: Interactable)

const WALK_SPEED: float = 4.6
const SPRINT_SPEED: float = 6.2
const MOUSE_SENSITIVITY: float = 0.0026
const LOOK_LIMIT: float = deg_to_rad(80.0)
const FOOTSTEP_INTERVAL_WALK: float = 0.48
const FOOTSTEP_INTERVAL_SPRINT: float = 0.31
const FOOTSTEP_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/footstep_concrete_000.ogg"),
	preload("res://assets/audio/footsteps/footstep_concrete_001.ogg"),
	preload("res://assets/audio/footsteps/footstep_concrete_002.ogg"),
	preload("res://assets/audio/footsteps/footstep_concrete_003.ogg"),
	preload("res://assets/audio/footsteps/footstep_concrete_004.ogg"),
]

@onready var head: Node3D = $Head
@onready var ray_cast: RayCast3D = $Head/Camera3D/RayCast3D

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var gameplay_enabled: bool = true
var current_interactable: Interactable
var footstep_player: AudioStreamPlayer
var footstep_time_left: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	footstep_player = AudioStreamPlayer.new()
	footstep_player.bus = "Master"
	footstep_player.volume_db = -9.5
	add_child(footstep_player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and gameplay_enabled and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, -LOOK_LIMIT, LOOK_LIMIT)
		return

	if event is InputEventMouseButton and gameplay_enabled and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if gameplay_enabled and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			elif gameplay_enabled:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return

		if gameplay_enabled and event.physical_keycode == KEY_E and current_interactable != null:
			interact_requested.emit(current_interactable)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var move_vector: Vector2 = Vector2.ZERO
	if gameplay_enabled:
		if Input.is_physical_key_pressed(KEY_A):
			move_vector.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			move_vector.x += 1.0
		if Input.is_physical_key_pressed(KEY_W):
			move_vector.y += 1.0
		if Input.is_physical_key_pressed(KEY_S):
			move_vector.y -= 1.0

	var speed: float = WALK_SPEED
	var sprinting: bool = gameplay_enabled and Input.is_physical_key_pressed(KEY_SHIFT)
	if sprinting:
		speed = SPRINT_SPEED

	var target_velocity: Vector3 = Vector3.ZERO
	if move_vector.length() > 0.0:
		move_vector = move_vector.normalized()
		var basis: Basis = global_transform.basis
		var forward: Vector3 = -basis.z
		var right: Vector3 = basis.x
		target_velocity = (right * move_vector.x + forward * move_vector.y).normalized() * speed

	velocity.x = move_toward(velocity.x, target_velocity.x, speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, speed * 8.0 * delta)
	move_and_slide()

	_update_footsteps(delta, sprinting)
	_update_focus()


func set_gameplay_enabled(value: bool) -> void:
	gameplay_enabled = value
	if value:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		footstep_time_left = 0.0
		_set_current_interactable(null)


func _update_focus() -> void:
	if not gameplay_enabled:
		if current_interactable != null:
			_set_current_interactable(null)
		return

	ray_cast.force_raycast_update()
	var candidate: Interactable
	if ray_cast.is_colliding():
		var collider := ray_cast.get_collider()
		if collider is Interactable and collider.active:
			candidate = collider

	_set_current_interactable(candidate)


func _set_current_interactable(next_interactable: Interactable) -> void:
	if current_interactable == next_interactable:
		return

	current_interactable = next_interactable
	if current_interactable == null:
		prompt_changed.emit("")
	else:
		prompt_changed.emit(current_interactable.get_prompt())


func _update_footsteps(delta: float, sprinting: bool) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var should_play := gameplay_enabled and is_on_floor() and horizontal_speed > 1.1
	if not should_play:
		footstep_time_left = 0.0
		return

	footstep_time_left -= delta * clampf(horizontal_speed / WALK_SPEED, 0.75, 1.45)
	if footstep_time_left > 0.0:
		return

	footstep_time_left = FOOTSTEP_INTERVAL_SPRINT if sprinting else FOOTSTEP_INTERVAL_WALK
	footstep_player.stream = FOOTSTEP_STREAMS[randi() % FOOTSTEP_STREAMS.size()]
	footstep_player.pitch_scale = randf_range(0.96, 1.05)
	footstep_player.play()
