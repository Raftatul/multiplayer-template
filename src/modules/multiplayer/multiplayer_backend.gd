extends Node

const DEFAULT_ADDRESS: String = "127.0.0.1"
const DEFAULT_PORT: int = 7777

signal server_created(is_dedicated_server: bool)
signal server_joined
signal server_leaved

var _peer: MultiplayerPeer = SteamMultiplayerPeer.new()
var _current_lobby_id: int = 0
var _steam_id: int = 0

var lobby_members: Array

var lobby_data: Dictionary


func _ready() -> void:
	_connect_steam_signals()

	_steam_id = Steam.getSteamID()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func quit_game() -> void:
	if _current_lobby_id != 0:
		leave_lobby()
	else:
		_leave_game()


func create_lobby(type: Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC, data: Dictionary = {}) -> void:
	if _current_lobby_id != 0:
		return

	lobby_data = data

	Steam.createLobby(type)
	print("Creating lobby")


func join_lobby(lobby_id: int) -> void:
	Steam.joinLobby(lobby_id)
	print("Joining lobby")


func leave_lobby() -> void:
	# If in a lobby, leave it
	if _current_lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(_current_lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		_current_lobby_id = 0

		# Close session with all users
		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != _steam_id:
				# Close the P2P session using the Networking class
				Steam.closeP2PSessionWithUser(this_member['steam_id'])

		# Clear the local lobby list
		lobby_members.clear()
		
		multiplayer.multiplayer_peer.close()
		server_leaved.emit()


func _leave_game() -> void:
	multiplayer.multiplayer_peer.close()
	server_leaved.emit()


func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()

	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(_current_lobby_id)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(_current_lobby_id, this_member)

		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		lobby_members.append({ "steam_id": member_steam_id, "steam_name": member_steam_name })

#region Steam Peer Management

func create_steam_socket():
	_peer = SteamMultiplayerPeer.new()
	_peer.create_host(0)
	multiplayer.set_multiplayer_peer(_peer)

	server_created.emit(OS.get_cmdline_args().has("--dedicated_server"))


func connect_steam_socket(steam_id: int):
	_peer = SteamMultiplayerPeer.new()
	_peer.create_client(steam_id, 0)
	multiplayer.set_multiplayer_peer(_peer)

	server_joined.emit()


func _connect_steam_signals() -> void:
	#Host
	Steam.lobby_created.connect(_on_lobby_created)

	#Client
	Steam.lobby_joined.connect(_on_lobby_joined)


#endregion

#region ENet Peer Management

func create_enet_host():
	_peer = ENetMultiplayerPeer.new()
	var error: Error = (_peer as ENetMultiplayerPeer).create_server(DEFAULT_PORT)
	if error != OK:
		printerr(error_string(error))
		return
	
	multiplayer.set_multiplayer_peer(_peer)
	server_created.emit(OS.get_cmdline_args().has("--dedicated_server"))


func create_enet_client(address: String):
	if address == "":
		address = DEFAULT_ADDRESS
	_peer = ENetMultiplayerPeer.new()
	var error: Error = (_peer as ENetMultiplayerPeer).create_client(address, DEFAULT_PORT)
	if error != OK:
		printerr(error_string(error))
		return
	
	multiplayer.set_multiplayer_peer(_peer)
	server_joined.emit()

#endregion

func _on_lobby_created(status: int, lobby_id: int) -> void:
	if status == 1:
		_current_lobby_id = lobby_id
		print("Lobby created !")
		Steam.setLobbyJoinable(lobby_id, true)

		# Set some lobby data
		for key in lobby_data:
			Steam.setLobbyData(lobby_id, key, lobby_data[key])

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)

		create_steam_socket()


func _on_lobby_joined(lobby: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("Lobby joined !")
		_current_lobby_id = lobby

		var id := Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			connect_steam_socket(id)

		# Get the lobby members
		get_lobby_members()
	else:
		var fail_reason: String
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
				fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
				fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL:
				fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR:
				fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED:
				fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED:
				fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED:
				fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN:
				fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU:
				fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER:
				fail_reason = "A user you have blocked is in the lobby."

		print("Failed to join this chat room: %s" % fail_reason)

		##Reopen the lobby list
		#_on_open_lobby_list_pressed()
