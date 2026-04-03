extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.06, 0.07, 0.09)
	add_child(background)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 56)
	shell.add_theme_constant_override("margin_top", 42)
	shell.add_theme_constant_override("margin_right", 56)
	shell.add_theme_constant_override("margin_bottom", 42)
	add_child(shell)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 24)
	shell.add_child(outer_vbox)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vbox.add_child(scroll)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	scroll.add_child(columns)

	var left := _make_card(Color(0.08, 0.1, 0.14, 0.94), Color(0.92, 0.3, 0.18))
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)

	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 14)
	left.add_child(left_box)

	var title := Label.new()
	title.text = "VR в производстве"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	left_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Учебный 3D-тренажёр по действиям при признаках возгорания оборудования"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color(0.83, 0.89, 0.98))
	left_box.add_child(subtitle)

	left_box.add_child(_make_section(
		"Задача",
		[
			"Вы оператор компрессора в производственном помещении.",
			"Нужно показать правильную последовательность действий при дыме и тревожной индикации.",
			"Приоритет: безопасность людей и эвакуация, а не спасение оборудования."
		]
	))

	left_box.add_child(_make_section(
		"Маршрут тренировки",
		[
			"1. Остановить оборудование аварийной кнопкой.",
			"2. Отойти на безопасную дистанцию.",
			"3. Выбрать вызов помощи.",
			"4. Эвакуироваться в коридор.",
			"5. Дойти до пункта сбора и подтвердить эвакуацию."
		]
	))

	var controls := _make_card(Color(0.1, 0.12, 0.16, 0.94), Color(0.18, 0.72, 0.34))
	controls.custom_minimum_size = Vector2(360, 0)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(controls)

	var controls_box := VBoxContainer.new()
	controls_box.add_theme_constant_override("separation", 14)
	controls.add_child(controls_box)

	var controls_title := Label.new()
	controls_title.text = "Управление"
	controls_title.add_theme_font_size_override("font_size", 28)
	controls_title.add_theme_color_override("font_color", Color(0.9, 1.0, 0.92))
	controls_box.add_child(controls_title)

	controls_box.add_child(_make_key_row("WASD", "Движение"))
	controls_box.add_child(_make_key_row("Мышь", "Осмотр"))
	controls_box.add_child(_make_key_row("E", "Взаимодействие"))
	controls_box.add_child(_make_key_row("Shift", "Быстрее идти"))
	controls_box.add_child(_make_key_row("Esc", "Освободить / вернуть мышь"))
	controls_box.add_child(_make_key_row("R", "Перезапуск после завершения"))

	var note := Label.new()
	note.text = "Для замены примитивов на модели см. docs/ASSET_PIPELINE.md и export-поля сцен."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", Color(0.79, 0.84, 0.91))
	controls_box.add_child(note)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_child(button_row)

	var start_button := Button.new()
	start_button.text = "Начать тренировку [Enter / Space]"
	start_button.custom_minimum_size = Vector2(250, 54)

	var start_shortcut := Shortcut.new()
	var enter_key := InputEventKey.new()
	enter_key.keycode = KEY_ENTER
	start_shortcut.events.append(enter_key)
	var space_key := InputEventKey.new()
	space_key.keycode = KEY_SPACE
	start_shortcut.events.append(space_key)
	start_button.shortcut = start_shortcut

	start_button.pressed.connect(_on_start_pressed)
	button_row.add_child(start_button)


func _on_start_pressed() -> void:
	GameSession.reset_session()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _make_card(background: Color, border: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", style)
	return card


func _make_section(title_text: String, lines: Array[String]) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.68))
	box.add_child(title)

	for line in lines:
		var bullet := Label.new()
		bullet.text = "• %s" % line
		bullet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bullet.add_theme_font_size_override("font_size", 18)
		bullet.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		box.add_child(bullet)

	return box


func _make_key_row(key_text: String, action_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var key := Label.new()
	key.text = key_text
	key.custom_minimum_size = Vector2(90, 0)
	key.add_theme_font_size_override("font_size", 19)
	key.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	row.add_child(key)

	var action := Label.new()
	action.text = action_text
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action.add_theme_font_size_override("font_size", 18)
	action.add_theme_color_override("font_color", Color(0.86, 0.92, 0.99))
	row.add_child(action)

	return row
