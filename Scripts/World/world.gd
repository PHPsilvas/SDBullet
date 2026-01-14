extends Node2D

@onready var players_node := $Players
const PLAYER_SCENE := preload("res://Entities/character_body_2d.tscn")

func _ready():
	add_to_group("world")

func spawn_player(peer_id: int):
	if players_node.has_node(str(peer_id)):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	players_node.add_child(player)
	
	player.force_send_state()

func despawn_player(peer_id: int):
	if players_node.has_node(str(peer_id)):
		players_node.get_node(str(peer_id)).queue_free()
