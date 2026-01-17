class_name SpawnPoint
extends Node3D

@onready var area: Area3D = $Area3D


func _ready() -> void:
	visible = false


func can_spawn() -> bool:
	return not area.has_overlapping_bodies()
