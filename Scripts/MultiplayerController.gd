extends Control

@export var Adress = "127.0.0.1"
@export var port = 9000

var peer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(PlayerConnected)
	multiplayer.peer_disconnected.connect(PlayerDisconnected)
	multiplayer.connected_to_server.connect(Connected_to_Server)
	multiplayer.connection_failed.connect(connection_Failed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Call on server and client
func PlayerConnected(id):
	print("Player Connected "+ str(id))

#Call on server and client
func PlayerDisconnected(id):
	print("Player Disconnected "+ str(id))

#from client
func Connected_to_Server():
	print("Connected To Server")
	sendPlayerInformation.rpc_id(1, $NomeEdit.text, multiplayer.get_unique_id() )

#From Client
func connection_Failed():
	print("Connection Failed")

func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	var erro = peer.create_server(9000, 6)
	if erro != OK:
		print("Erro:" + erro)
	
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	sendPlayerInformation($NomeEdit.text, multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = peer
	print("Waiting for players")
	


func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Adress, port)
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer




func _on_start_game_button_down() -> void:
	startGame.rpc()
	
@rpc("any_peer")
func sendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name , 
			"id" : id
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			sendPlayerInformation.rpc(GameManager.Players[i], i)
	
@rpc("any_peer","call_local","reliable")
func startGame():
	var scene = load("res://Scenes/world.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
