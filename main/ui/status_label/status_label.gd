class_name StatusLabel extends Label

@export var transition_time: float = 0.2

@export var error_color: Color
@export var success_color: Color
@export var working_color: Color

enum TextType { SUCCESS, ERROR, WORKING }

var tween: Tween

func _ready() -> void:
	text = ""
	modulate.a = 0

func show_text(input_text, state: TextType) -> void:
	modulate.a = 1.0
	%DecayTimer.stop()
	if is_instance_valid(tween):
		tween.stop()
	match state:
		TextType.SUCCESS:
			add_theme_color_override("font_color", success_color)
		TextType.ERROR:
			add_theme_color_override("font_color", error_color)
		TextType.WORKING:
			add_theme_color_override("font_color", working_color)
	text = input_text
	if not state == TextType.WORKING:
		%DecayTimer.start()
		await %DecayTimer.timeout
		tween = get_tree().create_tween()
		tween.tween_property(self, "modulate:a", 0.0, transition_time)
