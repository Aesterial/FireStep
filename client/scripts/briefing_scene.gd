extends Control

const UISkin = preload("res://scripts/ui_skin.gd")

var click_player: AudioStreamPlayer


func _ready() -> void:
	if not GameSession.ensure_authenticated(get_tree()):
		return
	click_player = UISkin.make_click_player(self)
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.06, 0.07, 0.09)
	add_child(background)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 24)
	center_container.add_child(outer_vbox)

	var logo_rect := TextureRect.new()
	logo_rect.texture = preload("res://aesterial_logo.png")
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.custom_minimum_size = Vector2(256, 128)
	outer_vbox.add_child(logo_rect)
	
	var title := Label.new()
	title.text = "VR in Production / FireStep"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.apply_title(title, 36, Color(1.0, 0.98, 0.9))
	outer_vbox.add_child(title)

	var start_button := Button.new()
	start_button.text = "Начать [Enter / Accept]"
	start_button.custom_minimum_size = Vector2(240, 56)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UISkin.apply_button(start_button, "green")
	_wire_click(start_button)

	var start_shortcut := Shortcut.new()
	var enter_key := InputEventKey.new()
	enter_key.keycode = KEY_ENTER
	start_shortcut.events.append(enter_key)
	var space_key := InputEventKey.new()
	space_key.keycode = KEY_SPACE
	start_shortcut.events.append(space_key)
	var accept_joy := InputEventJoypadButton.new()
	accept_joy.button_index = JOY_BUTTON_A
	start_shortcut.events.append(accept_joy)
	start_button.shortcut = start_shortcut

	start_button.pressed.connect(_on_start_pressed)
	outer_vbox.add_child(start_button)


func _on_start_pressed() -> void:
	GameSession.reset_session(true)
	GameSession.record_action("briefing/start_training")
	get_tree().change_scene_to_file("res://scenes/ControlsLab.tscn")


func _wire_click(button: BaseButton) -> void:
	button.pressed.connect(func() -> void:
		if click_player != null:
			click_player.play()
	)
