extends Control

func _ready():
	$VBoxContainer/BotaoHost.pressed.connect(_on_host_pressed)
	$VBoxContainer/HBoxContainer/BotaoJoin.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	MultiplayerManager.start_server()  # cria servidor LAN
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_join_pressed():
	var ip = $VBoxContainer/HBoxContainer/CampoIP.text
	if ip == "":
		push_warning("Digite um IP para conectar.")
		return

	MultiplayerManager.start_client(ip)  # conecta ao host
	get_tree().change_scene_to_file("res://Scenes/world.tscn")
