extends Node3D
class_name ForestMerchantEncounter

signal leave_requested

@onready var camera: Camera3D = $Camera3D

var camera_home_position: Vector3
var shake_time := 0.0

@export var shake_strength := 0.015
@export var shake_speed := 1.5


func _ready():
	if camera != null:
		camera.current = true
		camera_home_position = camera.position


func _process(delta):
	if camera == null:
		return

	shake_time += delta * shake_speed

	var offset := Vector3(
		sin(shake_time * 1.7),
		cos(shake_time * 1.3),
		0.0
	) * shake_strength

	camera.position = camera_home_position + offset


func request_leave():
	leave_requested.emit()
