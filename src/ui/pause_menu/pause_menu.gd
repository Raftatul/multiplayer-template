extends Control


func _on_button_resume_pressed() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_button_quit_pressed() -> void:
	MultiplayerBackend.quit_game()
