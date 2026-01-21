extends Control

@export var main: Main

@onready var edit_ip: LineEdit = %Edit_IP
@onready var edit_lobby_name: LineEdit = %Edit_LobbyName
@onready var option_lobby_type: OptionButton = %Option_LobbyType
@onready var container_levels_buttons: VBoxContainer = %Container_LevelsButtons
@onready var container_lobbies: VBoxContainer = %Container_Lobbies


func _ready() -> void:
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	
	if visible:
		_populate_level_selection()


func _populate_level_selection() -> void:
	var button_group: ButtonGroup = ButtonGroup.new()
	
	for child in container_levels_buttons.get_children():
		child.queue_free()
	
	for i in range(main.start_levels.size()):
		var level: PackedScene = main.start_levels[i]
		var button: Button = Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.button_group = button_group
		button.toggle_mode = true
		button.text = level.resource_path.get_file().get_basename()
		container_levels_buttons.add_child(button)
		button.pressed.connect(main.set_selected_level.bind(button.get_index()))
		
		if i == main.selected_level:
			button.set_pressed_no_signal(true)


func _on_button_create_pressed() -> void:
	MultiplayerBackend.create_enet_host()


func _on_button_join_pressed() -> void:
	MultiplayerBackend.create_enet_client(edit_ip.text)


func _on_button_create_lobby_pressed() -> void:
	var lobby_name: String = "%s: %s" % [Steam.getPersonaName(), edit_lobby_name.text]
	var data: Dictionary = {
		"game": "multiplayer-template",
		"name": lobby_name
	}
	MultiplayerBackend.create_lobby(option_lobby_type.selected, data)


func _on_button_refresh_pressed() -> void:
	for child in container_lobbies.get_children():
		child.queue_free()
	
	#Lobby filters
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("game", "multiplayer-template", Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()


func _on_lobby_match_list(lobbies: Array) -> void:
	for this_lobby in lobbies:
		# Pull lobby data from Steam, these are specific to our example
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")

		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("%s - %s Player(s)" % [lobby_name, lobby_num_members])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", MultiplayerBackend.join_lobby.bind(this_lobby))

		# Add the new lobby to the list
		container_lobbies.add_child(lobby_button)


func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		_populate_level_selection()
