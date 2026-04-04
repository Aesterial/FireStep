extends Control

const UISkin = preload("res://scripts/ui_skin.gd")

var click_player: AudioStreamPlayer
var status_label: Label
var login_box: VBoxContainer
var register_box: VBoxContainer
var login_fields: Dictionary = {}
var register_fields: Dictionary = {}


func _ready() -> void:
	click_player = UISkin.make_click_player(self)
	_build_ui()
	_try_restore_session()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.06, 0.08)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var shell := PanelContainer.new()
	UISkin.apply_panel(shell, Color(0.15, 0.21, 0.29, 0.92), Vector4(26.0, 22.0, 26.0, 22.0))
	shell.custom_minimum_size = Vector2(620.0, 560.0)
	center.add_child(shell)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	shell.add_child(root)

	var title := Label.new()
	title.text = "Авторизация FireStep"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.apply_title(title, 34, Color(1.0, 0.98, 0.9))
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Сначала вход или регистрация, затем проверка сессии и только потом запуск сценария."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.apply_body(subtitle, 17, Color(0.9, 0.95, 1.0))
	root.add_child(subtitle)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.apply_body(status_label, 15, Color(0.94, 0.97, 1.0))
	status_label.text = "Проверяем сохранённую сессию..."
	root.add_child(status_label)

	root.add_child(UISkin.make_divider())

	var switcher := HBoxContainer.new()
	switcher.alignment = BoxContainer.ALIGNMENT_CENTER
	switcher.add_theme_constant_override("separation", 12)
	root.add_child(switcher)

	var login_button := _make_mode_button("Вход")
	login_button.pressed.connect(func() -> void:
		_set_mode(true)
	)
	switcher.add_child(login_button)

	var register_button := _make_mode_button("Регистрация")
	register_button.pressed.connect(func() -> void:
		_set_mode(false)
	)
	switcher.add_child(register_button)

	login_box = VBoxContainer.new()
	login_box.add_theme_constant_override("separation", 12)
	root.add_child(login_box)

	login_fields.username = _make_labeled_input(login_box, "Логин", false)
	login_fields.password = _make_labeled_input(login_box, "Пароль", true)

	var login_submit := Button.new()
	login_submit.text = "Войти"
	login_submit.custom_minimum_size = Vector2(0.0, 46.0)
	UISkin.apply_button(login_submit, "green")
	_wire_click(login_submit)
	login_submit.pressed.connect(_submit_login)
	login_box.add_child(login_submit)

	register_box = VBoxContainer.new()
	register_box.add_theme_constant_override("separation", 12)
	root.add_child(register_box)

	register_fields.username = _make_labeled_input(register_box, "Логин", false)
	register_fields.email = _make_labeled_input(register_box, "Email", false)
	register_fields.initials = _make_labeled_input(register_box, "Инициалы", false)
	register_fields.org = _make_labeled_input(register_box, "Организация", false)
	register_fields.password = _make_labeled_input(register_box, "Пароль", true)

	var register_submit := Button.new()
	register_submit.text = "Зарегистрироваться"
	register_submit.custom_minimum_size = Vector2(0.0, 46.0)
	UISkin.apply_button(register_submit, "blue")
	_wire_click(register_submit)
	register_submit.pressed.connect(_submit_register)
	register_box.add_child(register_submit)

	root.add_child(UISkin.make_divider())

	var links := VBoxContainer.new()
	links.add_theme_constant_override("separation", 8)
	root.add_child(links)

	var backend_label := Label.new()
	backend_label.text = "Backend: %s" % ApiClient.BACKEND_URL
	UISkin.apply_body(backend_label, 14, Color(0.88, 0.93, 1.0))
	links.add_child(backend_label)

	var redirect_label := Label.new()
	redirect_label.text = "Redirect URL: %s" % ApiClient.AUTH_REDIRECT_URL
	UISkin.apply_body(redirect_label, 14, Color(0.88, 0.93, 1.0))
	links.add_child(redirect_label)

	var redirect_button := Button.new()
	redirect_button.text = "Открыть redirect URL"
	redirect_button.custom_minimum_size = Vector2(0.0, 40.0)
	UISkin.apply_button(redirect_button, "grey")
	_wire_click(redirect_button)
	redirect_button.pressed.connect(func() -> void:
		ApiClient.open_auth_redirect()
	)
	links.add_child(redirect_button)

	_set_mode(true)


func _make_mode_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180.0, 42.0)
	UISkin.apply_button(button, "grey")
	_wire_click(button)
	return button


func _make_labeled_input(parent: VBoxContainer, caption: String, secret: bool) -> LineEdit:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 6)
	parent.add_child(wrapper)

	var label := Label.new()
	label.text = caption
	UISkin.apply_body(label, 15, Color(0.94, 0.97, 1.0))
	wrapper.add_child(label)

	var input := LineEdit.new()
	input.secret = secret
	input.custom_minimum_size = Vector2(0.0, 42.0)
	wrapper.add_child(input)
	return input


func _set_mode(login_mode: bool) -> void:
	login_box.visible = login_mode
	register_box.visible = not login_mode


func _submit_login() -> void:
	status_label.text = "Выполняем вход..."
	var response = ApiClient.login(
		str((login_fields.username as LineEdit).text),
		str((login_fields.password as LineEdit).text)
	)
	_handle_auth_response(response)


func _submit_register() -> void:
	status_label.text = "Создаём учётную запись..."
	var response = ApiClient.register_user(
		str((register_fields.username as LineEdit).text),
		str((register_fields.email as LineEdit).text),
		str((register_fields.password as LineEdit).text),
		str((register_fields.initials as LineEdit).text),
		str((register_fields.org as LineEdit).text)
	)
	_handle_auth_response(response)


func _try_restore_session() -> void:
	GameSession.load_auth_state()
	if GameSession.session_token.is_empty():
		status_label.text = "Сохранённая сессия не найдена. Выполните вход или регистрацию."
		return

	status_label.text = "Проверяем сохранённую сессию..."
	var response = ApiClient.validate_session(GameSession.session_token)
	if not response.get("success", false):
		GameSession.clear_authenticated_session()
		status_label.text = "Старая сессия недействительна. Авторизуйтесь заново."
		return

	GameSession.apply_authenticated_session(GameSession.session_token, response.get("user", {}))
	GameSession.flush_pending_seance()
	status_label.text = "Сессия подтверждена. Переходим к сценарию..."
	get_tree().change_scene_to_file("res://scenes/Briefing.tscn")


func _handle_auth_response(response: Dictionary) -> void:
	if not response.get("success", false):
		status_label.text = "Ошибка авторизации: %s" % str(response.get("error", "unknown error"))
		return

	GameSession.apply_authenticated_session(
		str(response.get("sessionToken", "")),
		response.get("user", {})
	)
	GameSession.flush_pending_seance()
	status_label.text = "Авторизация завершена. Сессия сохранена."
	get_tree().change_scene_to_file("res://scenes/Briefing.tscn")


func _wire_click(button: BaseButton) -> void:
	button.pressed.connect(func() -> void:
		if click_player != null:
			click_player.play()
	)
