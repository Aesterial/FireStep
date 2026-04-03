extends RefCounted
class_name UISkin

const FONT_DISPLAY: Font = preload("res://assets/ui/fonts/Kenney Future.ttf")
const FONT_BODY: Font = preload("res://assets/ui/fonts/Kenney Future Narrow.ttf")
const BUTTON_GREEN: Texture2D = preload("res://assets/ui/textures/button_green.png")
const BUTTON_RED: Texture2D = preload("res://assets/ui/textures/button_red.png")
const BUTTON_GREY: Texture2D = preload("res://assets/ui/textures/button_grey.png")
const BUTTON_BLUE: Texture2D = preload("res://assets/ui/textures/button_blue.png")
const PANEL_OUTLINE: Texture2D = preload("res://assets/ui/textures/panel_outline.png")
const DIVIDER: Texture2D = preload("res://assets/ui/textures/divider.png")
const CLICK_STREAM: AudioStream = preload("res://assets/ui/sounds/click-a.ogg")

const PATCH_MARGIN: float = 18.0
const PATCH_CONTENT_LEFT: float = 22.0
const PATCH_CONTENT_TOP: float = 14.0
const PATCH_CONTENT_RIGHT: float = 22.0
const PATCH_CONTENT_BOTTOM: float = 18.0


static func apply_button(button: Button, tone: String = "green") -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(tone, 0.0))
	button.add_theme_stylebox_override("hover", _make_button_style("blue" if tone != "red" else "grey", 0.0))
	button.add_theme_stylebox_override("pressed", _make_button_style(tone, 3.0))
	button.add_theme_stylebox_override("focus", _make_button_style("blue", 0.0))
	button.add_theme_stylebox_override("disabled", _make_button_style("grey", 0.0))
	button.add_theme_font_override("font", FONT_DISPLAY)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.96, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.78, 0.84))


static func apply_panel(panel: PanelContainer, tint: Color, padding: Vector4 = Vector4(18.0, 16.0, 18.0, 16.0)) -> void:
	panel.add_theme_stylebox_override("panel", _make_panel_style(tint, padding))


static func apply_title(label: Control, size: int, color: Color) -> void:
	label.add_theme_font_override("font", FONT_DISPLAY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func apply_body(label: Control, size: int, color: Color) -> void:
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func make_divider() -> TextureRect:
	var divider := TextureRect.new()
	divider.texture = DIVIDER
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	divider.custom_minimum_size = Vector2(0.0, 12.0)
	return divider


static func make_click_player(owner: Node) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = CLICK_STREAM
	player.bus = "Master"
	player.volume_db = -8.0
	owner.add_child(player)
	return player


static func _make_button_style(tone: String, pressed_offset: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _resolve_button_texture(tone)
	style.modulate_color = Color.WHITE
	style.texture_margin_left = PATCH_MARGIN
	style.texture_margin_top = PATCH_MARGIN
	style.texture_margin_right = PATCH_MARGIN
	style.texture_margin_bottom = PATCH_MARGIN
	style.content_margin_left = PATCH_CONTENT_LEFT
	style.content_margin_top = PATCH_CONTENT_TOP + pressed_offset
	style.content_margin_right = PATCH_CONTENT_RIGHT
	style.content_margin_bottom = PATCH_CONTENT_BOTTOM - pressed_offset
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.draw_center = true
	return style


static func _make_panel_style(tint: Color, padding: Vector4) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = PANEL_OUTLINE
	style.modulate_color = tint
	style.texture_margin_left = PATCH_MARGIN
	style.texture_margin_top = PATCH_MARGIN
	style.texture_margin_right = PATCH_MARGIN
	style.texture_margin_bottom = PATCH_MARGIN
	style.content_margin_left = padding.x
	style.content_margin_top = padding.y
	style.content_margin_right = padding.z
	style.content_margin_bottom = padding.w
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.draw_center = true
	return style


static func _resolve_button_texture(tone: String) -> Texture2D:
	match tone:
		"red":
			return BUTTON_RED
		"grey":
			return BUTTON_GREY
		"blue":
			return BUTTON_BLUE
		_:
			return BUTTON_GREEN
