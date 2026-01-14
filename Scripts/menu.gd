extends Control

func _ready():
	$VBoxContainer/BotaoHost.pressed.connect(_on_host_pressed)
	$VBoxContainer/HBoxContainer/BotaoJoin.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	MultiplayerManager.host_game()  # cria servidor LAN
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_join_pressed():
	var ip = $VBoxContainer/HBoxContainer/CampoIP.text
	if ip == "":
		push_warning("Digite um IP para conectar.")
		return

	MultiplayerManager.join_game(ip)  # conecta ao host
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
