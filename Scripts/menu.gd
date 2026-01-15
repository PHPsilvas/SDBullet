extends Control

func _ready():
	$VBoxContainer/BotaoHost.pressed.connect(_on_host_pressed)
	$VBoxContainer/HBoxContainer/BotaoJoin.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_join_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
