extends Control

const UISkin = preload("res://scripts/ui_skin.gd")

var click_player: AudioStreamPlayer
var status_label: Label

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
	subtitle.text = "Сначала авторизация, затем проверка сессии и только потом запуск сценария."
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

	var auth_button := Button.new()
	auth_button.text = "Авторизоваться"
	auth_button.custom_minimum_size = Vector2(0.0, 56.0)
	UISkin.apply_button(auth_button, "green")
	_wire_click(auth_button)
	auth_button.pressed.connect(func() -> void:
		status_label.text = "Ожидание авторизации в браузере..."
		var url = ApiClient.AUTH_REDIRECT_URL
		if not url.ends_with("/"):
			url += "/"
		url += "client-auth"
		OS.shell_open(url)
	)
	root.add_child(auth_button)

	root.add_child(UISkin.make_divider())

	var links := VBoxContainer.new()
	links.add_theme_constant_override("separation", 8)
	root.add_child(links)

	var backend_label := Label.new()
	backend_label.text = "Backend: %s" % ApiClient.BACKEND_URL
	UISkin.apply_body(backend_label, 14, Color(0.88, 0.93, 1.0))
	links.add_child(backend_label)

	var redirect_label := Label.new()
	var frontend_url = ApiClient.AUTH_REDIRECT_URL
	if not frontend_url.ends_with("/"):
		frontend_url += "/"
	frontend_url += "client-auth"
	redirect_label.text = "Frontend Auth URL: %s" % frontend_url
	UISkin.apply_body(redirect_label, 14, Color(0.88, 0.93, 1.0))
	links.add_child(redirect_label)


func _try_restore_session() -> void:
	# Проверяем аргументы командной строки на наличие токена (от кастомного URL scheme или аргумента --token)
	var args := OS.get_cmdline_args()
	var token_from_args := ""
	for arg in args:
		if arg.begins_with("firestep://"):
			var query = arg.split("?")
			if query.size() > 1:
				var params = query[1].split("&")
				for param in params:
					if param.begins_with("token="):
						token_from_args = param.substr(6)
						break
		elif arg.begins_with("--token="):
			token_from_args = arg.substr(8)
			
	if not token_from_args.is_empty():
		_validate_and_apply_token(token_from_args)
		return

	GameSession.load_auth_state()
	if GameSession.session_token.is_empty():
		status_label.text = "Сохранённая сессия не найдена. Нажмите 'Авторизоваться'."
		return

	_validate_and_apply_token(GameSession.session_token)


func _validate_and_apply_token(token: String) -> void:
	status_label.text = "Проверяем сессию..."
	var response = ApiClient.validate_session(token)
	if not response.get("success", false):
		GameSession.clear_authenticated_session()
		status_label.text = "Сессия недействительна. Нажмите 'Авторизоваться'."
		return

	GameSession.apply_authenticated_session(token, response.get("user", {}))
	GameSession.flush_pending_seance()
	status_label.text = "Сессия подтверждена. Переходим к сценарию..."
	get_tree().change_scene_to_file("res://scenes/Briefing.tscn")


func _wire_click(button: BaseButton) -> void:
	button.pressed.connect(func() -> void:
		if click_player != null:
			click_player.play()
	)
