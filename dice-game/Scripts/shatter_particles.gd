extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready():
	particles.emitting = true

	await get_tree().create_timer(particles.lifetime + 0.25).timeout
	queue_free()
