extends Control

@export var Adress = "127.0.0.1"
@export var port = 9000

@onready var container_Equipe1 = $"VBoxContainer/HBoxContainer/Equipe1/1"
@onready var container_Equipe2 = $"VBoxContainer/HBoxContainer/Equip22/2"
@onready var startButton = $StartGame

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
	startButton.text = "Esperando pelo dono da Partida..."
	




func _on_start_game_button_down() -> void:
	if is_multiplayer_authority():
		startGame.rpc()
	
@rpc("any_peer")
func sendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name , 
			"id" : id,
			"equipe": GameManager.Players.size()%2
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			sendPlayerInformation.rpc(GameManager.Players[i].name, i)
	
	atualizar_interface_lista.rpc(container_Equipe1, 0)
	atualizar_interface_lista.rpc(container_Equipe2,1)
	
@rpc("any_peer","call_local","reliable") 
func startGame():
	var scene = load("res://Scenes/world.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

@rpc("any_peer","call_local")
func atualizar_interface_lista(container:VBoxContainer, equipe):
# 1. Limpa a lista atual para não duplicar
	for child in container.get_children():
		child.queue_free()

	# 2. Percorre o dicionário do GameManager (Autoload)
	for id in GameManager.Players:
		if GameManager.Players[id].equipe == equipe:
			var info_jogador = GameManager.Players[id]
			
		
			# 3. Cria uma Label para cada jogador
			var label_nome = Label.new()
			label_nome.text = str(info_jogador["name"])
		
			# Opcional: Destacar se for o próprio jogador
			if id == multiplayer.get_unique_id():
				label_nome.text += " (Você)"
				label_nome.modulate = Color.GREEN
					
			container.add_child(label_nome)
