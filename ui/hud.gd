extends CanvasLayer

signal decision_selected(choice: String)
signal restart_requested

const UISkin = preload("res://scripts/ui_skin.gd")

var objective_label: Label
var hint_label: Label
var interaction_panel: PanelContainer
var interaction_label: Label
var feedback_panel: PanelContainer
var feedback_label: Label
var banner_panel: PanelContainer
var banner_label: Label
var decision_panel: PanelContainer
var decision_title_label: Label
var decision_body_label: Label
var result_overlay: ColorRect
var result_title_label: Label
var result_body_label: Label

var banner_style: StyleBoxTexture
var feedback_style: StyleBoxTexture
var banner_base_color: Color = Color(0.92, 0.36, 0.18, 0.92)
var feedback_time_left: float = 0.0
var banner_elapsed: float = 0.0
var click_player: AudioStreamPlayer


func _ready() -> void:
	click_player = UISkin.make_click_player(self)
	_build_ui()
	set_process(true)


func _process(delta: float) -> void:
	banner_elapsed += delta
	if banner_panel.visible:
		var flash: float = 0.06 + (sin(banner_elapsed * 4.5) + 1.0) * 0.06
		banner_style.modulate_color = banner_base_color.lightened(flash)

	if feedback_time_left > 0.0:
		feedback_time_left -= delta
		if feedback_time_left <= 0.0:
			feedback_panel.visible = false


func set_objective(text: String) -> void:
	objective_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func set_interaction_prompt(text: String) -> void:
	interaction_panel.visible = not text.is_empty()
	interaction_label.text = text


func show_feedback(text: String, tone: String) -> void:
	feedback_panel.visible = true
	feedback_label.text = text
	feedback_time_left = 4.2

	match tone:
		"success":
			feedback_style.modulate_color = Color(0.3, 0.86, 0.44, 0.88)
			feedback_label.add_theme_color_override("font_color", Color(0.95, 1.0, 0.96))
		"warning":
			feedback_style.modulate_color = Color(0.98, 0.66, 0.16, 0.9)
			feedback_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.88))
		"info":
			feedback_style.modulate_color = Color(0.34, 0.74, 1.0, 0.88)
			feedback_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
		_:
			feedback_style.modulate_color = Color(0.92, 0.34, 0.28, 0.92)
			feedback_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))


func set_warning_banner(text: String, tone: String) -> void:
	banner_panel.visible = not text.is_empty()
	banner_label.text = text

	match tone:
		"safe":
			banner_base_color = Color(0.32, 0.84, 0.42, 0.9)
			banner_label.add_theme_color_override("font_color", Color(0.95, 1.0, 0.96))
		"warning":
			banner_base_color = Color(0.98, 0.62, 0.18, 0.92)
			banner_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.88))
		"critical":
			banner_base_color = Color(0.92, 0.26, 0.2, 0.96)
			banner_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
		_:
			banner_base_color = Color(0.92, 0.36, 0.18, 0.92)
			banner_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))

	banner_style.modulate_color = banner_base_color


func show_decision(visible: bool, title: String, body: String) -> void:
	decision_panel.visible = visible
	decision_title_label.text = title
	decision_body_label.text = body


func show_result(success: bool, title: String, body: String) -> void:
	result_overlay.visible = true
	result_title_label.text = title
	result_body_label.text = body

	if success:
		result_title_label.add_theme_color_override("font_color", Color(0.88, 1.0, 0.9))
	else:
		result_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.88))

	decision_panel.visible = false
	interaction_panel.visible = false


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var info_panel := _make_panel(Vector2(520, 164), Color(0.34, 0.74, 1.0, 0.86), Vector4(18.0, 18.0, 18.0, 16.0))
	info_panel.offset_left = 18.0
	info_panel.offset_top = 18.0
	root.add_child(info_panel)

	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 10)
	info_panel.add_child(info_box)

	var title := Label.new()
	title.text = "FIRESTEP // TRAINING"
	UISkin.apply_title(title, 23, Color(0.98, 0.99, 1.0))
	info_box.add_child(title)
	info_box.add_child(UISkin.make_divider())

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(objective_label, 18, Color(0.98, 0.99, 1.0))
	info_box.add_child(objective_label)

	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(hint_label, 16, Color(0.9, 0.95, 1.0))
	info_box.add_child(hint_label)

	banner_panel = _make_panel(Vector2(580, 54), banner_base_color, Vector4(20.0, 14.0, 20.0, 14.0))
	banner_panel.anchor_left = 0.5
	banner_panel.anchor_right = 0.5
	banner_panel.offset_left = -290.0
	banner_panel.offset_top = 18.0
	banner_panel.offset_right = 290.0
	banner_panel.offset_bottom = 72.0
	root.add_child(banner_panel)
	banner_style = banner_panel.get_theme_stylebox("panel") as StyleBoxTexture

	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UISkin.apply_title(banner_label, 16, Color(1.0, 0.95, 0.9))
	banner_panel.add_child(banner_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -10.0
	crosshair.offset_top = -16.0
	crosshair.offset_right = 10.0
	crosshair.offset_bottom = 16.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UISkin.apply_title(crosshair, 24, Color(1.0, 1.0, 1.0))
	root.add_child(crosshair)

	interaction_panel = _make_panel(Vector2(360, 54), Color(0.98, 0.66, 0.16, 0.88), Vector4(18.0, 14.0, 18.0, 14.0))
	interaction_panel.anchor_left = 0.5
	interaction_panel.anchor_right = 0.5
	interaction_panel.anchor_top = 1.0
	interaction_panel.anchor_bottom = 1.0
	interaction_panel.offset_left = -180.0
	interaction_panel.offset_top = -84.0
	interaction_panel.offset_right = 180.0
	interaction_panel.offset_bottom = -30.0
	interaction_panel.visible = false
	root.add_child(interaction_panel)

	interaction_label = Label.new()
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UISkin.apply_title(interaction_label, 17, Color(1.0, 0.98, 0.88))
	interaction_panel.add_child(interaction_label)

	feedback_panel = _make_panel(Vector2(700, 70), Color(0.34, 0.74, 1.0, 0.88), Vector4(18.0, 16.0, 18.0, 16.0))
	feedback_panel.anchor_left = 0.5
	feedback_panel.anchor_right = 0.5
	feedback_panel.anchor_top = 1.0
	feedback_panel.anchor_bottom = 1.0
	feedback_panel.offset_left = -350.0
	feedback_panel.offset_top = -164.0
	feedback_panel.offset_right = 350.0
	feedback_panel.offset_bottom = -90.0
	feedback_panel.visible = false
	root.add_child(feedback_panel)
	feedback_style = feedback_panel.get_theme_stylebox("panel") as StyleBoxTexture

	feedback_label = Label.new()
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UISkin.apply_body(feedback_label, 17, Color(0.95, 0.98, 1.0))
	feedback_panel.add_child(feedback_label)

	decision_panel = _make_panel(Vector2(560, 316), Color(0.92, 0.58, 0.16, 0.92), Vector4(20.0, 18.0, 20.0, 18.0))
	decision_panel.anchor_left = 0.5
	decision_panel.anchor_right = 0.5
	decision_panel.anchor_top = 0.5
	decision_panel.anchor_bottom = 0.5
	decision_panel.offset_left = -280.0
	decision_panel.offset_top = -170.0
	decision_panel.offset_right = 280.0
	decision_panel.offset_bottom = 170.0
	decision_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	decision_panel.visible = false
	root.add_child(decision_panel)

	var decision_box := VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 12)
	decision_panel.add_child(decision_box)

	decision_title_label = Label.new()
	UISkin.apply_title(decision_title_label, 24, Color(1.0, 0.98, 0.92))
	decision_box.add_child(decision_title_label)

	decision_body_label = Label.new()
	decision_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(decision_body_label, 17, Color(0.95, 0.98, 1.0))
	decision_box.add_child(decision_body_label)
	decision_box.add_child(UISkin.make_divider())

	var buttons = [
		_make_action_button("Подать сигнал / вызвать помощь", "alarm", "green"),
		_make_action_button("Сразу эвакуироваться", "evacuate", "blue"),
		_make_action_button("Пытаться спасать оборудование", "save", "red")
	]
	buttons.shuffle()
	for btn in buttons:
		decision_box.add_child(btn)

	result_overlay = ColorRect.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.02, 0.03, 0.05, 0.76)
	result_overlay.visible = false
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(result_overlay)

	var result_panel := _make_panel(Vector2(660, 294), Color(0.34, 0.74, 1.0, 0.9), Vector4(22.0, 18.0, 22.0, 18.0))
	result_panel.anchor_left = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -330.0
	result_panel.offset_top = -152.0
	result_panel.offset_right = 330.0
	result_panel.offset_bottom = 152.0
	result_overlay.add_child(result_panel)

	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	result_panel.add_child(result_box)

	result_title_label = Label.new()
	UISkin.apply_title(result_title_label, 28, Color(0.95, 1.0, 0.98))
	result_box.add_child(result_title_label)

	result_body_label = Label.new()
	result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(result_body_label, 18, Color(0.95, 0.98, 1.0))
	result_box.add_child(result_body_label)
	result_box.add_child(UISkin.make_divider())

	var restart_button := Button.new()
	restart_button.text = "Перезапустить тренировку"
	restart_button.custom_minimum_size = Vector2(0, 48)
	UISkin.apply_button(restart_button, "green")
	_wire_button_sound(restart_button)
	restart_button.pressed.connect(func() -> void:
		restart_requested.emit()
	)
	result_box.add_child(restart_button)

	var restart_hint := Label.new()
	restart_hint.text = "Горячая клавиша: R"
	UISkin.apply_body(restart_hint, 14, Color(0.92, 0.96, 1.0))
	result_box.add_child(restart_hint)


func _make_panel(minimum_size: Vector2, tint: Color, padding: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	UISkin.apply_panel(panel, tint, padding)
	return panel


func _make_action_button(text: String, choice: String, tone: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	UISkin.apply_button(button, tone)
	_wire_button_sound(button)
	button.pressed.connect(func() -> void:
		decision_selected.emit(choice)
	)
	return button


func _wire_button_sound(button: BaseButton) -> void:
	button.pressed.connect(func() -> void:
		if click_player != null:
			click_player.play()
	)
