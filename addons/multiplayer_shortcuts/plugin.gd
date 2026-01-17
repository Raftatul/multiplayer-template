@tool
class_name MultiplayerShortcuts
extends EditorPlugin

enum NET_MODES {STANDALONE, LISTEN_SERVER, CLIENT}

#region Scenes
const BUTTON_SHORTCUTS = preload("uid://bkp6som2rqyuo")

#endregion

#region Settings

const INSTANCES_COUNT_PATH: String = "Network/general/instances_count"
const NET_MODE_PATH: String = "Network/general/net_mode"

#endregion

var control: Control


func _enable_plugin() -> void:
	ProjectSettings.set_setting(INSTANCES_COUNT_PATH, 1)
	ProjectSettings.set_setting(NET_MODE_PATH, 0)


func _disable_plugin() -> void:
	ProjectSettings.set_setting(INSTANCES_COUNT_PATH, null)
	ProjectSettings.set_setting(NET_MODE_PATH, null)


func _enter_tree() -> void:
	control = BUTTON_SHORTCUTS.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, control)
	control.get_parent().move_child(control, -3)


func _exit_tree() -> void:
	if control:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, control)
