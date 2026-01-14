extends Node

const PORT = 9000
var is_host := false

# Cria servidor LAN
func host_game():
	is_host = true
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 2)  # máximo 2 jogadores
	multiplayer.multiplayer_peer = peer
	print("Servidor criado. Aguardando jogadores...")

# Conecta a outro jogador na LAN
func join_game(ip: String):
	is_host = false
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Tentando conectar ao host: ", ip)

func _ready():
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnect)

func _on_peer_connected(id):
	print("Jogador conectado: ", id)

func _on_peer_disconnected(id):
	print("Jogador saiu: ", id)

func _on_connection_failed():
	print("Falha ao conectar!")

func _on_server_disconnect():
	print("Desconectado do servidor.")
