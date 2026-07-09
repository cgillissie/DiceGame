extends Camera3D

@export var shake_strength := 0.008
@export var shake_speed := 0.8

var default_position: Vector3
var shake_time := 0.0

func _ready():
	default_position = position

func _process(delta):
	shake_time += delta * shake_speed

	var offset := Vector3(
		sin(shake_time * 0.63),
		cos(shake_time * 0.91),
		sin(shake_time * 0.47)
	) * shake_strength

	position = default_position + offset
