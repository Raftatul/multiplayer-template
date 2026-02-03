class_name PlayerInput 
extends BaseNetInput

@export var _camera_pivot: Node3D
@export var _rollback_synchronizer: RollbackSynchronizer

var confidence: float = 1.0

var input_direction: Vector2 = Vector2.ZERO
var movement: Vector3 = Vector3.ZERO
var input_jump: int = 0


func _ready():
	super()
	
	NetworkRollback.after_prepare_tick.connect(_predict)


func _process(_delta):
	@warning_ignore("narrowing_conversion")
	input_jump = Input.get_action_strength("jump")


func _gather():
	if not is_multiplayer_authority():
		return
		
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()
	movement = _camera_pivot.global_basis * Vector3(input_direction.x, 0.0, input_direction.y)


func _predict(_tick: int) -> void:
	if not _rollback_synchronizer.is_predicting():
		# Not predicting, nothing to do
		confidence = 1.0
		return

	if not _rollback_synchronizer.has_input():
		# Can't predict without input
		confidence = 0.0
		return

	# Decay input over a short time
	var decay_time := NetworkTime.seconds_to_ticks(.15)
	var input_age := _rollback_synchronizer.get_input_age()

	# **ALWAYS** cast either side to float, otherwise the integer-integer 
	# division yields either 1 or 0 confidence
	confidence = input_age / float(decay_time)
	confidence = clampf(1.0 - confidence, 0.0, 1.0)

	# Modulate input based on confidence
	movement *= confidence
