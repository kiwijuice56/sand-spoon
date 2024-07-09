class_name ElementButton extends Button

func initialize(element: Element) -> void:
	text = element.unique_name
	
	var base_style: StyleBoxFlat = get_theme_stylebox("normal").duplicate()
	base_style.bg_color = element.color
	
	var hover_style: StyleBoxFlat = base_style.duplicate()
	hover_style.bg_color = element.color.lightened(0.25)
	
	var press_style: StyleBoxFlat = base_style.duplicate()
	hover_style.bg_color = element.color.darkened(0.25)
	
	add_theme_stylebox_override("normal", base_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", press_style)
