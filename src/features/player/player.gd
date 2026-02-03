extends CharacterBody3D

signal jumped

@export var input: PlayerInput
@export var sensitivity: float = 0.5
@export var rotation_speed: float = 1.0
@export var acceleration: float = 5.0
@export var speed: float = 10.0
@export var jump_force: float = 10.0

var peer_id: int = 1:
	set(value):
		peer_id = value
		input.set_multiplayer_authority(value)

@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm: SpringArm3D = %SpringArm3D
@onready var camera: Camera3D = %Camera3D
@onready var visual: Node3D = %Visual

@onready var pause_menu: Control = %PauseMenu
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer


#func _enter_tree() -> void:
	#set_multiplayer_authority(int(name))


func _ready() -> void:
	rollback_synchronizer.process_settings()
	
	if multiplayer.get_unique_id() != peer_id:
		#set_process(false)
		#set_physics_process(false)
		#set_process_input(false)
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


func _force_update_physics_transform():
	PhysicsServer3D.body_set_mode(get_rid(), PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, global_transform)
	PhysicsServer3D.body_set_mode(get_rid(), PhysicsServer3D.BODY_MODE_KINEMATIC)


func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity


func _rollback_tick(delta: float, _tick: int, _is_fresh: bool) -> void:
	_force_update_physics_transform()
	_force_update_is_on_floor()
	
	# Skip predictions
	if rollback_synchronizer.is_predicting():
		rollback_synchronizer.ignore_prediction(self)
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if input.input_jump > 0:
			jumped.emit()
			velocity.y = jump_force
	
	var movement: Vector3 = input.movement
	if movement:
		var target_vel: Vector3 = movement * speed
		velocity = velocity.move_toward(Vector3(target_vel.x, velocity.y, target_vel.z), acceleration)
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-target_vel.x, -target_vel.z), delta * rotation_speed)
	else:
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), acceleration)

	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
