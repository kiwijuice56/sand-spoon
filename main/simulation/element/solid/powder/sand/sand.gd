class_name Sand extends Powder

@export var glass_temperature: int = 180

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if get_byte(data, 0) >= glass_temperature:
		sim.set_element(row, col, "glass")
	return true
