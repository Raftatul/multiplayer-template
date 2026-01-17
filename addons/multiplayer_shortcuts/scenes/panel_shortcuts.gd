@tool
extends PopupPanel


func _ready() -> void:
	_init_instances_count()
	_init_net_modes()
	
	reset_size()


func _init_instances_count() -> void:
	%InstancesCount.value = ProjectSettings.get_setting(MultiplayerShortcuts.INSTANCES_COUNT_PATH, 1)


func _init_net_modes() -> void:
	%NetModeOptions.selected = ProjectSettings.get_setting(MultiplayerShortcuts.NET_MODE_PATH, 0)
	%NetModeOptions.set_item_tooltip(0, "No network behavior")
	%NetModeOptions.set_item_tooltip(1, "Instance(s) will act as a server and a client")
	%NetModeOptions.set_item_tooltip(2, "Instance(s) will act as client (Fist instance will serve as dedicated server)")


func _get_args(index: int, net_mode: MultiplayerShortcuts.NET_MODES) -> String:
	match net_mode:
		MultiplayerShortcuts.NET_MODES.STANDALONE:
			return "--standalone"
		MultiplayerShortcuts.NET_MODES.LISTEN_SERVER:
			if index == 0:
				return "--server"
			return "--client"
		MultiplayerShortcuts.NET_MODES.CLIENT:
			if index == 0:
				return "--dedicated_server --headless"
			return "--client"
	return ""


func _generate_args(instance_count: int, net_mode: int) -> void:
	var data: Array[Dictionary] = []
	for i in range(instance_count):
		var dict: Dictionary = {}
		dict["override_args"] = false
		dict["arguments"] = _get_args(i, net_mode)
		dict["override_features"] = false
		dict["features"] = ""
		data.append(dict)
	
	#RunInstancesDialog.get_singleton().set_stored_data(data)


func _on_close_requested() -> void:
	queue_free()


func _on_spin_box_value_changed(value: float) -> void:
	var net_mode: int = ProjectSettings.get_setting(MultiplayerShortcuts.NET_MODE_PATH)
	#RunInstancesDialog.get_singleton().set_instance_count(value)
	_generate_args(value, net_mode)
	ProjectSettings.set_setting(MultiplayerShortcuts.INSTANCES_COUNT_PATH, value)
	ProjectSettings.save()


func _on_net_mode_options_item_selected(index: int) -> void:
	var instance_count: int = EditorInterface.get_editor_settings().get_project_metadata("debug_options", "run_instance_count", 1)
	_generate_args(instance_count, index)
	ProjectSettings.set_setting(MultiplayerShortcuts.NET_MODE_PATH, index)
	ProjectSettings.save()
