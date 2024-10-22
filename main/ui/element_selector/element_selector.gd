class_name ElementSelector extends ScrollContainer

signal element_selected(element: Element)

@export var sim: Simulation
@export var prompter: Prompter
@export var eraser_button: ElementButton
@export var element_button_scene: PackedScene
@export var scroll_duration: float = 0.4

var selected_button: ElementButton

func _ready() -> void:
	update_element_buttons()
	%ElementButtonContainer.get_child(0).pressed.emit()
	
	sim.elements_updated.connect(_on_elements_updated)
	prompter.element_created.connect(_on_element_created)
	
	eraser_button.pressed.connect(_on_element_selected.bind(eraser_button, eraser_button.assigned_element))
	eraser_button.initialize(eraser_button.assigned_element)
	eraser_button.text = "eraser"

func _on_element_created() -> void:
	scroll_to_bottom()

func _on_elements_updated() -> void:
	update_element_buttons()

func _on_element_selected(button: ElementButton, element: Element) -> void:
	if is_instance_valid(selected_button):
		selected_button.deselect()
	button.select()
	selected_button = button
	element_selected.emit(element)

func update_element_buttons() -> void:
	var to_delete: Array[ElementButton]
	for child in %ElementButtonContainer.get_children():
		%ElementButtonContainer.remove_child(child)
		to_delete.append(child)
	
	for element in sim.elements:
		if element.hidden:
			continue
		var new_button: ElementButton = element_button_scene.instantiate()
		%ElementButtonContainer.add_child(new_button)
		new_button.initialize(element)
		new_button.pressed.connect(_on_element_selected.bind(new_button, element))
		
		if is_instance_valid(selected_button) and element == selected_button.assigned_element:
			new_button.select()
			selected_button = new_button
	
	for child in to_delete:
		child.queue_free()

func scroll_to_bottom() -> void:
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "scroll_vertical", get_v_scroll_bar().max_value, scroll_duration)
	await tween.finished
