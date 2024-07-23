class_name ClearButton extends Button

func _ready() -> void:
	button_down.connect(_on_pressed)

func _on_pressed() -> void:
	%ClickPlayer.play()
