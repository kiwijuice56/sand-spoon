class_name ElementButton extends Button

var assigned_element: Element

func _ready() -> void:
	material = material.duplicate()

func initialize(element: Element) -> void:
	assigned_element = element
	text = element.unique_name
	
	var base_style: StyleBoxFlat = get_theme_stylebox("normal").duplicate()
	base_style.bg_color = element.ui_color
	
	var hover_style: StyleBoxFlat = base_style.duplicate()
	hover_style.bg_color = element.ui_color.lightened(0.25)
	
	var press_style: StyleBoxFlat = base_style.duplicate()
	press_style.bg_color = element.ui_color.darkened(0.25)
	
	add_theme_stylebox_override("normal", base_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", press_style)
	
	if element.ui_color.get_luminance() > 0.75:
		add_theme_color_override("font_color", "#000000")
		add_theme_color_override("font_hover_color", "#000000")
		add_theme_color_override("font_pressed_color", "#000000")
		add_theme_color_override("font_focus_color", "#000000")

func select() -> void:
	material.set_shader_parameter("visibility", 1.0)

func deselect() -> void:
	material.set_shader_parameter("visibility", 0.0)
