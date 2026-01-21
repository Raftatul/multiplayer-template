extends CharacterBody3D

signal jumped

@export var sensitivity: float = 0.5
@export var rotation_speed: float = 1.0
@export var acceleration: float = 5.0
@export var speed: float = 10.0
@export var jump_force: float = 10.0

@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm: SpringArm3D = %SpringArm3D
@onready var camera: Camera3D = %Camera3D
@onready var visual: Node3D = %Visual

@onready var pause_menu: Control = %PauseMenu


func _enter_tree() -> void:
	set_multiplayer_authority(int(name))


func _ready() -> void:
	if get_multiplayer_authority() != 0 and not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		camera.current = false
	else:
		camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MouseMode.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton:
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
				Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
		pause_menu.visible = true
	
	if event is InputEventMouseMotion:
		var motion: Vector2 = -event.relative * sensitivity
		camera_pivot.rotate_y(deg_to_rad(motion.x))
		spring_arm.rotate_x(deg_to_rad(motion.y))
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -70.0, 70.0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if Input.is_action_just_pressed("ui_accept"):
			jumped.emit()
			velocity.y = jump_force
	
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input:
		var target_vel: Vector3 = camera_pivot.global_basis * Vector3(input.x, 0.0, input.y) * speed
		velocity = velocity.move_toward(Vector3(target_vel.x, velocity.y, target_vel.z), acceleration)
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-target_vel.x, -target_vel.z), delta * rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), acceleration)
	
	move_and_slide()
