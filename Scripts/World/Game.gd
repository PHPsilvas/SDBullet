extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/IpAddress
@onready var map = $TileMapLayer

const Player = preload("res://Entities/character_body_2d.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()


func _on_host_button_pressed():
	main_menu.hide()
	map.show()

	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(remove_player)

	spawn_player(multiplayer.get_unique_id())
	upnp_setup()
	
	
@rpc("authority", "call_local")
func spawn_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id) # servidor
	add_child(player)
	
func _on_peer_connected(peer_id):
	spawn_player.rpc(peer_id)

func _on_join_button_pressed():
	main_menu.hide()
	map.show()

	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_setup():
	var upnp := UPNP.new()

	var discover_result := upnp.discover(2000, 2)

	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP: Nenhum dispositivo encontrado (", discover_result, ")")
		print("UPNP desativado ou não suportado. Host manual necessário.")
		return false

	var gateway := upnp.get_gateway()
	if not gateway or not gateway.is_valid_gateway():
		print("UPNP: Gateway inválido")
		return false

	var map_result := upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP: Falha ao mapear porta:", map_result)
		return false

	print("UPNP OK! Endereço externo:", upnp.query_external_address())
	return true
