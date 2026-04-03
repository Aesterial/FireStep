extends Control

const UISkin = preload("res://scripts/ui_skin.gd")

var click_player: AudioStreamPlayer


func _ready() -> void:
	click_player = UISkin.make_click_player(self)
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.06, 0.07, 0.09)
	add_child(background)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 40)
	shell.add_theme_constant_override("margin_top", 32)
	shell.add_theme_constant_override("margin_right", 40)
	shell.add_theme_constant_override("margin_bottom", 32)
	add_child(shell)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 22)
	shell.add_child(outer_vbox)

	var hero := _make_card(Color(0.34, 0.74, 1.0, 0.88), Vector4(22.0, 20.0, 22.0, 18.0))
	outer_vbox.add_child(hero)

	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 10)
	hero.add_child(hero_box)

	var eyebrow := Label.new()
	eyebrow.text = "VR in Production / FireStep"
	UISkin.apply_title(eyebrow, 16, Color(1.0, 0.98, 0.9))
	hero_box.add_child(eyebrow)

	var title := Label.new()
	title.text = "Учебный маршрут по пожару на промышленном объекте"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_title(title, 28, Color(0.98, 0.99, 1.0))
	hero_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Оператор должен остановить основной модуль, отойти на безопасную дистанцию, вызвать помощь, отключить резервный генератор и завершить эвакуацию на пункте сбора."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(subtitle, 18, Color(0.95, 0.98, 1.0))
	hero_box.add_child(subtitle)
	hero_box.add_child(UISkin.make_divider())

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	outer_vbox.add_child(columns)

	var left := _make_card(Color(0.98, 0.64, 0.16, 0.88), Vector4(20.0, 18.0, 20.0, 18.0))
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)

	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 14)
	left.add_child(left_box)

	left_box.add_child(_make_section(
		"Задача",
		[
			"Вы находитесь в производственном блоке компрессорной установки.",
			"Приоритет сценария: защита людей и снижение риска, а не спасение оборудования любой ценой.",
			"Ошибки на любом этапе переводят на итоговый разбор с фиксацией причины провала."
		]
	))

	left_box.add_child(UISkin.make_divider())

	left_box.add_child(_make_section(
		"Маршрут тренировки",
		[
			"1. Остановить основной модуль аварийной кнопкой.",
			"2. Отойти в безопасную зону.",
			"3. Зафиксировать вызов помощи.",
			"4. Выйти из цеха в соседний модуль.",
			"5. Отключить резервный генератор GEN-02.",
			"6. Дойти до пункта сбора и подтвердить эвакуацию."
		]
	))

	var right := _make_card(Color(0.3, 0.86, 0.44, 0.88), Vector4(20.0, 18.0, 20.0, 18.0))
	right.custom_minimum_size = Vector2(370, 0)
	columns.add_child(right)

	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 14)
	right.add_child(right_box)

	var controls_title := Label.new()
	controls_title.text = "Управление"
	UISkin.apply_title(controls_title, 24, Color(0.98, 0.99, 1.0))
	right_box.add_child(controls_title)
	right_box.add_child(UISkin.make_divider())

	right_box.add_child(_make_key_row("WASD", "Движение"))
	right_box.add_child(_make_key_row("Мышь", "Осмотр"))
	right_box.add_child(_make_key_row("E", "Взаимодействие"))
	right_box.add_child(_make_key_row("Shift", "Быстрый шаг"))
	right_box.add_child(_make_key_row("Esc", "Освободить / вернуть мышь"))
	right_box.add_child(_make_key_row("R", "Перезапуск активной сцены"))

	var note := Label.new()
	note.text = "Визуалы и звуки взяты из пакетов Kenney; детали по ассетам и проверке лежат в docs/ASSETS.md и docs/TEST_PLAN.md."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(note, 15, Color(0.95, 0.98, 1.0))
	right_box.add_child(note)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_vbox.add_child(button_row)

	var start_button := Button.new()
	start_button.text = "Начать тренировку [Enter / Space]"
	start_button.custom_minimum_size = Vector2(320, 56)
	UISkin.apply_button(start_button, "green")
	_wire_click(start_button)

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


func _make_card(tint: Color, padding: Vector4) -> PanelContainer:
	var card := PanelContainer.new()
	UISkin.apply_panel(card, tint, padding)
	return card


func _make_section(title_text: String, lines: Array[String]) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	UISkin.apply_title(title, 22, Color(1.0, 0.98, 0.92))
	box.add_child(title)

	for line in lines:
		var bullet := Label.new()
		bullet.text = "• %s" % line
		bullet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UISkin.apply_body(bullet, 17, Color(0.95, 0.98, 1.0))
		box.add_child(bullet)

	return box


func _make_key_row(key_text: String, action_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var key := Label.new()
	key.text = key_text
	key.custom_minimum_size = Vector2(96, 0)
	UISkin.apply_title(key, 18, Color(1.0, 0.98, 0.9))
	row.add_child(key)

	var action := Label.new()
	action.text = action_text
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(action, 17, Color(0.95, 0.98, 1.0))
	row.add_child(action)

	return row


func _wire_click(button: BaseButton) -> void:
	button.pressed.connect(func() -> void:
		if click_player != null:
			click_player.play()
	)
