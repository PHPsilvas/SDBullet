extends Node2D

@export var playerScene :PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = playerScene.instantiate()
		currentPlayer.collision_layer = 0
		currentPlayer.collision_mask = 0
		currentPlayer.name = str(GameManager.Players[i].id)
		currentPlayer.nome = str(GameManager.Players[i].name)
		currentPlayer.set_collision_layer_value(GameManager.Players[i].equipe+1, true)
		currentPlayer.set_collision_mask_value(5, true)
		add_child(currentPlayer)
		currentPlayer.add_to_group("Player")
		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
			if spawn.name == str(index):
				currentPlayer.global_position = spawn.global_position
		index+=1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
