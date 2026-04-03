extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.06, 0.08)
	add_child(background)

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("margin_left", 60)
	shell.add_theme_constant_override("margin_top", 48)
	shell.add_theme_constant_override("margin_right", 60)
	shell.add_theme_constant_override("margin_bottom", 48)
	add_child(shell)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 24)
	shell.add_child(outer_vbox)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vbox.add_child(scroll)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.1, 0.14, 0.96)
	style.border_color = Color(0.2, 0.72, 0.34) if GameSession.final_success else Color(0.84, 0.22, 0.16)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 22
	style.content_margin_top = 22
	style.content_margin_right = 22
	style.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", style)
	scroll.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "Итоги тренировки"
	eyebrow.add_theme_font_size_override("font_size", 18)
	eyebrow.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	box.add_child(eyebrow)

	var title := Label.new()
	title.text = GameSession.final_title
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override(
		"font_color",
		Color(0.88, 1.0, 0.9) if GameSession.final_success else Color(1.0, 0.88, 0.88)
	)
	box.add_child(title)

	var body := Label.new()
	body.text = GameSession.final_body
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	box.add_child(body)

	if not GameSession.workshop_summary.is_empty() and GameSession.final_success:
		var stage_note := Label.new()
		stage_note.text = "Промежуточный итог: %s" % GameSession.workshop_summary
		stage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stage_note.add_theme_font_size_override("font_size", 16)
		stage_note.add_theme_color_override("font_color", Color(0.76, 0.84, 0.93))
		box.add_child(stage_note)

	var highlights_title := Label.new()
	highlights_title.text = "Ключевые выводы"
	highlights_title.add_theme_font_size_override("font_size", 24)
	highlights_title.add_theme_color_override("font_color", Color(0.97, 0.84, 0.68))
	box.add_child(highlights_title)

	for item in GameSession.final_highlights:
		var bullet := Label.new()
		bullet.text = "• %s" % item
		bullet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bullet.add_theme_font_size_override("font_size", 18)
		bullet.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		box.add_child(bullet)

	var hint := Label.new()
	hint.text = "Импорт и замена визуальных ассетов описаны в docs/ASSET_PIPELINE.md."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.77, 0.83, 0.91))
	box.add_child(hint)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	outer_vbox.add_child(buttons)

	var restart := Button.new()
	restart.text = "Повторить тренировку [R]"
	restart.custom_minimum_size = Vector2(250, 48)

	var restart_shortcut := Shortcut.new()
	var r_key := InputEventKey.new()
	r_key.keycode = KEY_R
	restart_shortcut.events.append(r_key)
	restart.shortcut = restart_shortcut

	restart.pressed.connect(_on_restart_pressed)
	buttons.add_child(restart)

	var briefing := Button.new()
	briefing.text = "Вернуться к брифингу [Enter / Space]"
	briefing.custom_minimum_size = Vector2(250, 48)

	var briefing_shortcut := Shortcut.new()
	var enter_key := InputEventKey.new()
	enter_key.keycode = KEY_ENTER
	briefing_shortcut.events.append(enter_key)
	var space_key := InputEventKey.new()
	space_key.keycode = KEY_SPACE
	briefing_shortcut.events.append(space_key)
	briefing.shortcut = briefing_shortcut

	briefing.pressed.connect(_on_back_pressed)
	buttons.add_child(briefing)


func _on_restart_pressed() -> void:
	GameSession.reset_session()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_back_pressed() -> void:
	GameSession.reset_session()
	get_tree().change_scene_to_file("res://scenes/Briefing.tscn")
