# chaos-sands
A modular falling sand simulation created in Godot.

## Elements
Each type of particle is represented by a Godot `Resource` that
extends from `Element` (or various subclasses with built-in functionality, such as `Fluid` or `Powder`).
However, in the simulation itself, particles are represented with only two numbers:
- `id` a byte representing this particle's element.
- `data` a 32 bit integer for extra state information. First 16 bits are reserved for storing temperature.

The simulation assigns a unique `id` to each of the `Element` resource when the game starts.
As the simulation iterates though each cell, it will find the `Element` resource corresponding
to that particle's `id` and call its `process` and `get_color` functions (which are essentially static).
By extending the `Element` class, you can also extend the `process` function to interact with the simulation and
create custom functionality.

### Element functions
- `func process(sim: Simulation, row: int, col: int, data: int) -> bool:` Advances the particle of this `Element` type (located at `row`, `col` and with state `data`) by one frame.
When extending this function, it is important to call the parent class's `process` function to preserve its functionality.
If `process` quits early, it should return `false` if inheriting classes should also quit early.

### Sample code
```python
class_name MyElement extends Element

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
    # Always keep this line. If `Element` transforms into
    # another element and quits early, this element
    # should not continue processing.
	if not super.process(sim, row, col, data):
		return false

    # Temperature is stored in the first 16 bits of `data`
    # as a 16-bit integer.
    var current_temperature: int = get_temperature(data)

    # However, temperature is simulated in different units
    # internally. Use the `convert_temperature` function
    # to compare internal temperature data with Kelvin degrees.
    if current_temperature > convert_temperature(293.0):
        # Set the 3rd byte with new state information,
        # then pass into the simulation.
        data = set_byte(data, 2, get_byte(data, 2) + 1)
        sim.set_data(row, col, data)
    else:
        sim.set_element(row, col, "sand")
        return false

    return true
```

