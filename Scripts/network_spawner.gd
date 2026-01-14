extends Node2D

@export var player_scene : PackedScene

var next_spawn := 0

var spawn_positions = [
	Vector2(100, 100),
	Vector2(400, 300)
]

func _ready():
	# Se for servidor, spawna imediatamente o player 1
	if MultiplayerManager.is_host:
		_spawn_player.rpc(1)

	# Quando qualquer peer conectar, o servidor spawna para ele
	multiplayer.peer_connected.connect(func(id):
		if multiplayer.is_server():
			_spawn_player.rpc(id)
	)


@rpc("any_peer", "call_local")
func _spawn_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)

	# Define a autoridade corretamente
	player.set_multiplayer_authority(id)

	# Posiciona corretamente
	player.global_position = spawn_positions[next_spawn]
	next_spawn += 1

	add_child(player)
