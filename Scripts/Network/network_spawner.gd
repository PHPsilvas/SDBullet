extends Node2D

@export var player_scene : PackedScene

@onready var players_node := $Players

var next_spawn := 0

var spawn_positions = [
	Vector2(100, 100),
	Vector2(500, 200)
]

func _ready():
	# Adiciona ao grupo para que o MultiplayerManager possa encontrar
	players_node.add_to_group("players_container")
	
	# SOMENTE o servidor cria players
	if multiplayer.is_server():
		# IMPORTANTE: Conecta ANTES de spawnar o servidor
		multiplayer.peer_connected.connect(_on_peer_connected)
		
		# Spawna o player do próprio servidor (ID 1) apenas UMA vez
		call_deferred("_spawn_player", 1)
		call_deferred("_spawn_player", 2)

func _on_peer_connected(id: int):
	print("NetworkSpawner: Peer conectado, spawnando player para ID ", id)
	_spawn_player(id)

func _spawn_player(id: int):
	# CRÍTICO: Evita spawnar duplicado
	if players_node.has_node(str(id)):
		print("AVISO: Player ", id, " já existe! Ignorando spawn duplicado.")
		return

	var player := player_scene.instantiate()
	player.name = str(id)

	# Define autoridade correta (quem controla este player)
	player.set_multiplayer_authority(id)

	# Posição inicial
	player.global_position = spawn_positions[next_spawn]
	next_spawn = (next_spawn + 1) % spawn_positions.size()

	# Adiciona à cena (true = sincroniza automaticamente)
	players_node.add_child(player, true)
	print("✓ Player ", id, " spawnado na posição ", player.global_position)
