extends Node

const PORT = 9000
const MAX_PLAYERS := 2
var is_host := false

func start_server():
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	
	# Conecta apenas sinal de desconexão (spawn é feito pelo network_spawner)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	is_host = true
	print("Servidor iniciado na porta ", PORT)

func start_client(ip: String):
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	
	# Conecta sinais do cliente
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("Conectando ao servidor: ", ip)

# === CALLBACK DO SERVIDOR ===
func _on_peer_disconnected(id: int):
	print("Peer desconectado: ", id)
	# Remove o player do peer desconectado
	if multiplayer.is_server():
		var players_node = get_tree().get_first_node_in_group("players_container")
		if players_node and players_node.has_node(str(id)):
			players_node.get_node(str(id)).queue_free()
			print("Player ", id, " removido da cena")

# === CALLBACKS DO CLIENTE ===
func _on_connected_to_server():
	print("✓ Conectado ao servidor com sucesso!")

func _on_connection_failed():
	print("✗ Falha ao conectar ao servidor")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	print("✗ Desconectado do servidor")
	multiplayer.multiplayer_peer = null
