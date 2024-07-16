class_name RainbowButton extends Button

func _ready() -> void:
	button_up.connect(_on_released)
	mouse_entered.connect(_on_hovered)
	mouse_exited.connect(_on_unhovered)
	button_down.connect(_on_pressed)

func _on_hovered() -> void:
	material.set_shader_parameter("hover", true)

func _on_unhovered() -> void:
	material.set_shader_parameter("hover", false)

func _on_pressed() -> void:
	%ClickPlayer.play()
	material.set_shader_parameter("pressed", true)

func _on_released() -> void:
	material.set_shader_parameter("pressed", false)
