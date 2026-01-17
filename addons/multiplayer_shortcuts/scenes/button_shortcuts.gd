@tool
extends Button

const PANEL_SHORTCUTS = preload("uid://c1mvlmqh655rm")


func _on_pressed() -> void:
	var menu: PopupPanel = PANEL_SHORTCUTS.instantiate()
	var offset: Vector2 = Vector2(0.0, size.y)
	get_tree().root.add_child(menu)
	menu.position = get_screen_position() + offset
