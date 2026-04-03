extends Control

const UISkin = preload("res://scripts/ui_skin.gd")

var click_player: AudioStreamPlayer


func _ready() -> void:
	click_player = UISkin.make_click_player(self)
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.06, 0.08)
	add_child(background)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 44)
	shell.add_theme_constant_override("margin_top", 36)
	shell.add_theme_constant_override("margin_right", 44)
	shell.add_theme_constant_override("margin_bottom", 36)
	add_child(shell)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 22)
	shell.add_child(outer_vbox)

	var status_tint := Color(0.3, 0.86, 0.44, 0.88) if GameSession.final_success else Color(0.92, 0.34, 0.26, 0.9)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UISkin.apply_panel(card, status_tint, Vector4(24.0, 20.0, 24.0, 20.0))
	outer_vbox.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "Итоги тренировки"
	UISkin.apply_title(eyebrow, 16, Color(1.0, 0.98, 0.9))
	box.add_child(eyebrow)

	var title := Label.new()
	title.text = GameSession.final_title
	UISkin.apply_title(
		title,
		30,
		Color(0.9, 1.0, 0.92) if GameSession.final_success else Color(1.0, 0.9, 0.9)
	)
	box.add_child(title)

	var body := Label.new()
	body.text = GameSession.final_body
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(body, 19, Color(0.96, 0.98, 1.0))
	box.add_child(body)

	if not GameSession.workshop_summary.is_empty() and GameSession.final_success:
		box.add_child(UISkin.make_divider())
		var stage_note := Label.new()
		stage_note.text = "Промежуточный итог: %s" % GameSession.workshop_summary
		stage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UISkin.apply_body(stage_note, 15, Color(0.94, 0.97, 1.0))
		box.add_child(stage_note)

	box.add_child(UISkin.make_divider())

	var stats_title := Label.new()
	stats_title.text = "Статистика сессии: Время - %s | Ошибок - %d" % [GameSession.get_elapsed_time_string(), GameSession.total_errors]
	stats_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_title(stats_title, 18, Color(0.9, 0.95, 1.0))
	box.add_child(stats_title)

	var highlights_title := Label.new()
	highlights_title.text = "Ключевые выводы"
	UISkin.apply_title(highlights_title, 22, Color(1.0, 0.98, 0.92))
	box.add_child(highlights_title)

	for item in GameSession.final_highlights:
		var bullet := Label.new()
		bullet.text = "• %s" % item
		bullet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UISkin.apply_body(bullet, 17, Color(0.96, 0.98, 1.0))
		box.add_child(bullet)

	var hint := Label.new()
	hint.text = "Проверка маршрута и список использованных ассетов описаны в docs/TEST_PLAN.md и docs/ASSETS.md."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.apply_body(hint, 15, Color(0.94, 0.97, 1.0))
	box.add_child(hint)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	outer_vbox.add_child(buttons)

	var restart := Button.new()
	restart.text = "Повторить тренировку [R]"
	restart.custom_minimum_size = Vector2(280, 50)
	UISkin.apply_button(restart, "green")
	_wire_click(restart)

	var restart_shortcut := Shortcut.new()
	var r_key := InputEventKey.new()
	r_key.keycode = KEY_R
	restart_shortcut.events.append(r_key)
	var restart_joy := InputEventJoypadButton.new()
	restart_joy.button_index = JOY_BUTTON_Y
	restart_shortcut.events.append(restart_joy)
	restart.shortcut = restart_shortcut

	restart.pressed.connect(_on_restart_pressed)
	buttons.add_child(restart)

	var briefing := Button.new()
	briefing.text = "Вернуться на титульный [Enter / Accept]"
	briefing.custom_minimum_size = Vector2(320, 50)
	UISkin.apply_button(briefing, "blue")
	_wire_click(briefing)

	var briefing_shortcut := Shortcut.new()
	var enter_key := InputEventKey.new()
	enter_key.keycode = KEY_ENTER
	briefing_shortcut.events.append(enter_key)
	var space_key := InputEventKey.new()
	space_key.keycode = KEY_SPACE
	briefing_shortcut.events.append(space_key)
	var accept_joy := InputEventJoypadButton.new()
	accept_joy.button_index = JOY_BUTTON_A
	briefing_shortcut.events.append(accept_joy)
	briefing.shortcut = briefing_shortcut

	briefing.pressed.connect(_on_back_pressed)
	buttons.add_child(briefing)


func _on_restart_pressed() -> void:
	GameSession.reset_session()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_back_pressed() -> void:
	GameSession.reset_session(true)
	get_tree().change_scene_to_file("res://scenes/Briefing.tscn")


func _wire_click(button: BaseButton) -> void:
	button.pressed.connect(func() -> void:
		if click_player != null:
			click_player.play()
	)
