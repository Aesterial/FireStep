extends CanvasLayer

signal decision_selected(choice: String)
signal restart_requested

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

var banner_style: StyleBoxFlat
var feedback_style: StyleBoxFlat
var banner_base_color: Color = Color(0.74, 0.16, 0.11, 0.95)
var feedback_time_left: float = 0.0
var banner_elapsed: float = 0.0


func _ready() -> void:
	_build_ui()
	set_process(true)


func _process(delta: float) -> void:
	banner_elapsed += delta
	if banner_panel.visible:
		var flash: float = 0.12 + (sin(banner_elapsed * 4.5) + 1.0) * 0.08
		banner_style.bg_color = banner_base_color.lightened(flash)

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
			feedback_style.bg_color = Color(0.15, 0.45, 0.22, 0.92)
			feedback_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.92))
		"warning":
			feedback_style.bg_color = Color(0.55, 0.36, 0.1, 0.94)
			feedback_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		"info":
			feedback_style.bg_color = Color(0.16, 0.27, 0.42, 0.94)
			feedback_label.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))
		_:
			feedback_style.bg_color = Color(0.34, 0.18, 0.18, 0.94)
			feedback_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.88))


func set_warning_banner(text: String, tone: String) -> void:
	banner_panel.visible = not text.is_empty()
	banner_label.text = text

	match tone:
		"safe":
			banner_base_color = Color(0.16, 0.42, 0.22, 0.95)
			banner_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.92))
		"warning":
			banner_base_color = Color(0.68, 0.42, 0.08, 0.95)
			banner_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.86))
		"critical":
			banner_base_color = Color(0.65, 0.08, 0.08, 0.97)
			banner_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
		_:
			banner_base_color = Color(0.74, 0.16, 0.11, 0.95)
			banner_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.9))

	banner_style.bg_color = banner_base_color


func show_decision(visible: bool, title: String, body: String) -> void:
	decision_panel.visible = visible
	decision_title_label.text = title
	decision_body_label.text = body


func show_result(success: bool, title: String, body: String) -> void:
	result_overlay.visible = true
	result_title_label.text = title
	result_body_label.text = body

	if success:
		result_title_label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.9))
	else:
		result_title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.86))

	decision_panel.visible = false
	interaction_panel.visible = false


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var info_panel := _make_panel(Vector2(480, 150), Color(0.07, 0.09, 0.13, 0.86), Color(0.22, 0.48, 0.88))
	info_panel.offset_left = 20.0
	info_panel.offset_top = 20.0
	root.add_child(info_panel)

	var info_box := VBoxContainer.new()
	info_panel.add_child(info_box)

	var title := Label.new()
	title.text = "FireStep | Обучение"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	info_box.add_child(title)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 19)
	objective_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	info_box.add_child(objective_label)

	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", Color(0.73, 0.82, 0.94))
	info_box.add_child(hint_label)

	banner_panel = _make_panel(Vector2(560, 44), banner_base_color, Color(1.0, 0.72, 0.68))
	banner_panel.anchor_left = 0.5
	banner_panel.anchor_right = 0.5
	banner_panel.offset_left = -280.0
	banner_panel.offset_top = 18.0
	banner_panel.offset_right = 280.0
	banner_panel.offset_bottom = 62.0
	root.add_child(banner_panel)
	banner_style = banner_panel.get_theme_stylebox("panel") as StyleBoxFlat

	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 18)
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
	crosshair.add_theme_font_size_override("font_size", 26)
	crosshair.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	root.add_child(crosshair)

	interaction_panel = _make_panel(Vector2(320, 44), Color(0.08, 0.09, 0.12, 0.9), Color(0.92, 0.75, 0.18))
	interaction_panel.anchor_left = 0.5
	interaction_panel.anchor_right = 0.5
	interaction_panel.anchor_top = 1.0
	interaction_panel.anchor_bottom = 1.0
	interaction_panel.offset_left = -160.0
	interaction_panel.offset_top = -76.0
	interaction_panel.offset_right = 160.0
	interaction_panel.offset_bottom = -28.0
	interaction_panel.visible = false
	root.add_child(interaction_panel)

	interaction_label = Label.new()
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 18)
	interaction_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	interaction_panel.add_child(interaction_label)

	feedback_panel = _make_panel(Vector2(660, 60), Color(0.16, 0.27, 0.42, 0.94), Color(0.75, 0.82, 0.96))
	feedback_panel.anchor_left = 0.5
	feedback_panel.anchor_right = 0.5
	feedback_panel.anchor_top = 1.0
	feedback_panel.anchor_bottom = 1.0
	feedback_panel.offset_left = -330.0
	feedback_panel.offset_top = -150.0
	feedback_panel.offset_right = 330.0
	feedback_panel.offset_bottom = -84.0
	feedback_panel.visible = false
	root.add_child(feedback_panel)
	feedback_style = feedback_panel.get_theme_stylebox("panel") as StyleBoxFlat

	feedback_label = Label.new()
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 18)
	feedback_panel.add_child(feedback_label)

	decision_panel = _make_panel(Vector2(520, 260), Color(0.06, 0.07, 0.1, 0.96), Color(0.94, 0.74, 0.16))
	decision_panel.anchor_left = 0.5
	decision_panel.anchor_right = 0.5
	decision_panel.anchor_top = 0.5
	decision_panel.anchor_bottom = 0.5
	decision_panel.offset_left = -260.0
	decision_panel.offset_top = -150.0
	decision_panel.offset_right = 260.0
	decision_panel.offset_bottom = 150.0
	decision_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	decision_panel.visible = false
	root.add_child(decision_panel)

	var decision_box := VBoxContainer.new()
	decision_box.add_theme_constant_override("separation", 12)
	decision_panel.add_child(decision_box)

	decision_title_label = Label.new()
	decision_title_label.add_theme_font_size_override("font_size", 26)
	decision_title_label.add_theme_color_override("font_color", Color(0.98, 0.97, 0.92))
	decision_box.add_child(decision_title_label)

	decision_body_label = Label.new()
	decision_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	decision_body_label.add_theme_font_size_override("font_size", 17)
	decision_body_label.add_theme_color_override("font_color", Color(0.84, 0.89, 0.97))
	decision_box.add_child(decision_body_label)

	decision_box.add_child(_make_action_button("Подать сигнал / вызвать помощь", "alarm"))
	decision_box.add_child(_make_action_button("Сразу эвакуироваться", "evacuate"))
	decision_box.add_child(_make_action_button("Пытаться спасать оборудование", "save"))

	result_overlay = ColorRect.new()
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.03, 0.03, 0.04, 0.76)
	result_overlay.visible = false
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(result_overlay)

	var result_panel := _make_panel(Vector2(640, 270), Color(0.08, 0.09, 0.12, 0.97), Color(0.88, 0.88, 0.9))
	result_panel.anchor_left = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -320.0
	result_panel.offset_top = -145.0
	result_panel.offset_right = 320.0
	result_panel.offset_bottom = 145.0
	result_overlay.add_child(result_panel)

	var result_box := VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	result_panel.add_child(result_box)

	result_title_label = Label.new()
	result_title_label.add_theme_font_size_override("font_size", 30)
	result_box.add_child(result_title_label)

	result_body_label = Label.new()
	result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body_label.add_theme_font_size_override("font_size", 18)
	result_body_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	result_box.add_child(result_body_label)

	var restart_button := Button.new()
	restart_button.text = "Перезапустить тренировку"
	restart_button.custom_minimum_size = Vector2(0, 44)
	restart_button.pressed.connect(func() -> void:
		restart_requested.emit()
	)
	result_box.add_child(restart_button)

	var restart_hint := Label.new()
	restart_hint.text = "Горячая клавиша: R"
	restart_hint.add_theme_font_size_override("font_size", 15)
	restart_hint.add_theme_color_override("font_color", Color(0.74, 0.81, 0.91))
	result_box.add_child(restart_hint)


func _make_panel(minimum_size: Vector2, background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size

	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)

	return panel


func _make_action_button(text: String, choice: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(func() -> void:
		decision_selected.emit(choice)
	)
	return button
