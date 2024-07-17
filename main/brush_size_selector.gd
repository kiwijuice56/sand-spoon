class_name BrushSizeSelector extends HBoxContainer

@export var sizes: Array[int]
@export var brush_size_button_scene: PackedScene

var selected_button: Button

signal size_selected(brush_size)

func _ready() -> void:
	initialize_buttons()

func _on_size_selected(button: BrushSizeButton, brush_size: int) -> void:
	if is_instance_valid(selected_button):
		selected_button.deselect()
	button.select()
	selected_button = button
	size_selected.emit(brush_size)

func initialize_buttons() -> void:
	for brush_size in sizes:
		var new_button: BrushSizeButton = brush_size_button_scene.instantiate()
		add_child(new_button)
		new_button.initialize(brush_size)
		new_button.pressed.connect(_on_size_selected.bind(new_button, brush_size))
