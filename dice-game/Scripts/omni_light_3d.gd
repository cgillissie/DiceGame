extends OmniLight3D
class_name FlickerLight

@export var base_energy := 1.5
@export var flicker_amount := 0.45
@export var flicker_speed := 8.0

@export var base_range := 5.0
@export var range_flicker := 0.5

var time := 0.0

func _process(delta):
	time += delta * flicker_speed

	var noise := sin(time) * 0.5 + sin(time * 2.37) * 0.3 + randf_range(-0.15, 0.15)

	light_energy = base_energy + noise * flicker_amount
	omni_range = base_range + noise * range_flicker
