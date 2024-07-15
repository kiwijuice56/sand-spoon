class_name ElementSelector extends ScrollContainer

signal element_selected(element: Element)

@export var sim: Simulation
@export var element_button_scene: PackedScene

func _ready() -> void:
	update_element_buttons()
	sim.element_added.connect(_on_element_added)

func _on_element_added(update_ui: bool) -> void:
	if update_ui:
		update_element_buttons()

func _on_element_selected(element: Element) -> void:
	element_selected.emit(element)

func update_element_buttons() -> void:
	for child in %ElementButtonContainer.get_children():
		child.queue_free()
	for element in sim.elements:
		if element.hidden:
			continue
		var new_button: ElementButton = element_button_scene.instantiate()
		%ElementButtonContainer.add_child(new_button)
		new_button.initialize(element)
		new_button.pressed.connect(_on_element_selected.bind(element))
