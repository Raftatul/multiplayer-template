@tool
class_name Main
extends Node

const DEFAULT_ADDRESS: String = "127.0.0.1"
const PLAYER = preload("uid://701k78kygyiu")

@export var start_levels: Array[PackedScene] = [] :
	set(value):
		start_levels = value
		if has_node("%LevelSpawner"):
			%LevelSpawner.clear_spawnable_scenes()
			if value:
				for v in value:
					if v:
						%LevelSpawner.add_spawnable_scene(v.resource_path)

var selected_level: int = 0

@onready var level_spawner: MultiplayerSpawner = %LevelSpawner
@onready var player_spawner: MultiplayerSpawner = %PlayerSpawner
@onready var menu: Control = $Menu


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	MultiplayerBackend.server_created.connect(_on_server_created)
	MultiplayerBackend.server_joined.connect(_on_server_joined)
	MultiplayerBackend.server_leaved.connect(_on_server_leaved)
	
	if OS.get_cmdline_args().has("--server") or OS.get_cmdline_args().has("--dedicated_server"):
		MultiplayerBackend.create_enet_host()
	elif OS.get_cmdline_args().has("--client"):
		MultiplayerBackend.create_enet_client(DEFAULT_ADDRESS)


func set_selected_level(index: int) -> void:
	selected_level = index


func _get_spawn_point() -> Vector3:
	var spawn_point: Array[Node] = get_tree().get_nodes_in_group("spawn_point")
	var random_idx: int = randi_range(0, spawn_point.size() - 1)
	for i in range(spawn_point.size()):
		var idx: int = wrap(random_idx + i, 0, spawn_point.size())
		var point: SpawnPoint = spawn_point[idx]
		if point.can_spawn():
			return point.global_position
	return Vector3(0.0, 2.0, 0.0)


func _add_player(id: int) -> void:
	var player: Node3D = PLAYER.instantiate()
	var spawn_pos: Vector3 = _get_spawn_point()
	player.name = str(id)
	player_spawner.add_child(player)
	_rpc_set_player_position.rpc(player.get_path(), spawn_pos)


func _remove_player(id: int) -> void:
	if player_spawner.has_node(str(id)):
		player_spawner.get_node(str(id)).queue_free()


@rpc("any_peer", "call_local")
func _rpc_set_player_position(path: NodePath, pos: Vector3) -> void:
	var node: Node3D = get_tree().root.get_node(path)
	if node:
		node.global_position = pos


#region Server

func _on_peer_connected(id: int) -> void:
	_add_player(id)
	print("[SERVER]: client %s connected" % id)


func _on_peer_disconnected(id: int) -> void:
	_remove_player(id)
	print("[SERVER]: client %s disconnected" % id)

#endregion


#region Client

func _on_client_connected() -> void:
	print("[CLIENT]: client %s connected to server" % multiplayer.get_unique_id())


func _on_client_disconnected() -> void:
	print("[CLIENT]: client %s disconnected from server" % multiplayer.multiplayer_peer)
	_on_server_leaved()

#endregion


func _on_server_created(is_dedicated_server: bool) -> void:
	menu.visible = false

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var level: Node = start_levels[selected_level].instantiate()
	level_spawner.add_child(level)
	
	if not is_dedicated_server:
		_add_player(1)


func _on_server_joined() -> void:
	menu.visible = false
	
	multiplayer.connected_to_server.connect(_on_client_connected)
	multiplayer.server_disconnected.connect(_on_client_disconnected)


func _on_server_leaved() -> void:
	for child in level_spawner.get_children():
		child.queue_free()
	
	for child in player_spawner.get_children():
		child.queue_free()
	
	menu.visible = true
	
	#Disconnect server signals
	if multiplayer.peer_connected.has_connections():
		multiplayer.peer_connected.disconnect(_on_peer_connected)
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	
	#Disconnect client signals
	if multiplayer.connected_to_server.has_connections():
		multiplayer.connected_to_server.disconnect(_on_client_connected)
		multiplayer.server_disconnected.disconnect(_on_client_disconnected)
