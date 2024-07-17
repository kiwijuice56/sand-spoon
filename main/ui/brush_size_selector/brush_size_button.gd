class_name BrushSizeButton extends Button

var assigned_brush_size: int

func _ready() -> void:
	material = material.duplicate()
	button_down.connect(_on_pressed)

func _on_pressed() -> void:
	%ClickPlayer.play()

func initialize(brush_size: int) -> void:
	assigned_brush_size = brush_size
	
	material = material.duplicate()
	material.set_shader_parameter("radius", brush_size / 16.0)

func select() -> void:
	material.set_shader_parameter("visibility", 1.0)

func deselect() -> void:
	material.set_shader_parameter("visibility", 0.0)
