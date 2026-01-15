extends CharacterBody2D

@export var SPEED := 200.0
@export var JUMP_VELOCITY := -350.0
const GRAVITY = 9.8 * 60 # Ajuste conforme sua função get_gravity()

var input_direction := 0.0
var input_jump := false
var input_fire := false # Vira true apenas no frame que o botão é apertado

var mira = 1

var target_position := Vector2.ZERO
var target_velocity := Vector2.ZERO

@onready var anim := $AnimatedSprite2D
@onready var jet_pack_particle: GPUParticles2D = %JetPackParticle
@onready var jet_pack_bar: ProgressBar = %JetPackBar
@onready var health_bar: ProgressBar = %Healthbar
@onready var shootcooldown: Timer = $ShootCooldown
@onready var municao: Label = $CanvasLayer/Control/Municao
@onready var recarga: Timer = $Recarga
var bullet_path = preload("res://Entities/Bullet.tscn")

const JETPACK_FORCE = 20.0
const JETPACK_FUEL_MAX = 100
const JETPACK_FUEL_COST = 1.0
const JETPACK_MAXHEIGHT = 250


const HEALTH_MAX = 100
var health = HEALTH_MAX

var jetpackFuel = JETPACK_FUEL_MAX
var jetpack_active = false

var firePermission = true
var bullet = 30






func _ready():
	# Adiciona ao grupo para detecção de colisão
	add_to_group("player")
	
	# Apenas a autoridade processa física
	if not is_multiplayer_authority():
		set_physics_process(false)
	
	jet_pack_bar.value = jetpackFuel
	health_bar.value = health
	


func _physics_process(delta):
	if is_multiplayer_authority():
		_read_input()

		# Cliente envia input ao servidor
		if not multiplayer.is_server():
			_send_input_to_server.rpc_id(1, input_direction, input_fire, input_jump)

		# Aplica movimento localmente (predição no cliente)
		_apply_movement(delta)

		# Servidor envia estado autoritativo
		if multiplayer.is_server():
			_send_state()
	else:
		# Outros clientes apenas interpolam
		_apply_remote_state(delta)

func _send_input_to_server():
	rpc_id(1, "server_receive_input", input_direction, input_fire, input_jump)


@rpc("any_peer", "unreliable")
func server_receive_input(dir: float, fire: bool, jump: bool):
	# Só aceita se quem chamou é o dono deste player
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return

	input_direction = dir
	input_fire = fire
	input_jump = jump

func _send_state():
	rpc("receive_state", global_position, velocity)
	
	
@rpc("any_peer", "unreliable")
func receive_state(pos, vel):
	if not multiplayer.is_server():
		target_position = pos
		velocity = vel

# O Dono é o único que precisa da entrada
func _read_input():
	input_direction = Input.get_axis("ui_left", "ui_right")
	input_jump = Input.is_action_pressed("ui_accept")
	input_fire = Input.is_action_pressed("Left_mouse")

# O Dono é o único que aplica o movimento
func _apply_movement(delta):
	# Seu código de movimento...
	if not is_on_floor():
		velocity += get_gravity() * delta
	

		
	if input_fire and firePermission and bullet>0:
		fire()
		shootcooldown.start()
		firePermission = false
		bullet -= 1
		municao.text = str(bullet)+"/30"
		if bullet == 0:
			recarga.start()
		
		
	if input_jump:
		activate_jetpack()

	if input_direction != 0:
		velocity.x = input_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Animações locais
	if is_on_floor():
		if input_direction > 0:
			#anim.flip_h = false
			if mira < 0:
				self.scale.x = -1
				mira = 1
			anim.play("walk")
		elif input_direction < 0:
			#anim.flip_h = true
			if mira > 0:
				self.scale.x = -1
				
				mira = -1
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		anim.play("jump")
		if input_direction > 0:
			#anim.flip_h = false
			if mira < 0:
				self.scale.x = -1
				
				mira = 1
		elif input_direction < 0:
			#anim.flip_h = true
			if mira > 0:
				self.scale.x = -1
				
				mira = -1
	
	move_and_slide()



func _apply_remote_state(delta):
	# Interpolação para suavizar o movimento recebido
	global_position = global_position.lerp(target_position, 0.25)
	velocity = velocity.lerp(target_velocity, 0.25)

	# Animações remotas simples
	if abs(velocity.x) > 10:
		anim.play("walk")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")

func activate_jetpack():
	if jetpackFuel > 0:
		jetpack_active = true
		velocity.y -= JETPACK_FORCE
		jetpackFuel -= JETPACK_FUEL_COST
		jet_pack_bar.value -= JETPACK_FUEL_COST
		jet_pack_particle.emitting = true

func _on_jet_pack_cooldown_timeout() -> void:
	if jetpackFuel < 100 and is_on_floor():
		jetpackFuel += JETPACK_FUEL_COST
		jet_pack_bar.value += JETPACK_FUEL_COST
		jetpack_active = false
		jet_pack_particle.emitting = false

func fire():
	# Apenas o dono pode disparar
	if not is_multiplayer_authority():
		return
	
	# Calcula posição e direção do tiro
	var bullet_spawn_pos = $AnimatedSprite2D/Node2D.global_position
	var bullet_rotation = global_rotation
	var bullet_direction = rotation
	
	# Se for servidor, cria diretamente
	if multiplayer.is_server():
		_spawn_bullet(bullet_spawn_pos, bullet_rotation, bullet_direction, get_multiplayer_authority())
	else:
		# Se for cliente, pede ao servidor
		_request_spawn_bullet.rpc_id(1, bullet_spawn_pos, bullet_rotation, bullet_direction)


@rpc("any_peer", "call_local", "reliable")
func _request_spawn_bullet(pos: Vector2, rot: float, dir: float):
	# Valida que quem enviou é o dono deste player
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return
	
	# Servidor cria a bala
	if multiplayer.is_server():
		_spawn_bullet(pos, rot, dir, get_multiplayer_authority())


func _spawn_bullet(pos: Vector2, rot: float, dir: float, owner_id: int):
	var bullet = bullet_path.instantiate()
	
	# Inicializa a bala com os dados
	bullet.initialize(pos, rot, dir, owner_id)
	
	# Adiciona à cena (true = replica para todos os clientes)
	get_parent().add_child(bullet, true)


# OPCIONAL: Função para receber dano
func take_damage(amount: int, attacker_id: int, damage: int):
	if multiplayer.is_server():
		print("Player ", get_multiplayer_authority(), " levou ", amount, " de dano de ", attacker_id)
		# Aqui você pode adicionar lógica de vida, morte, etc.
		health -= damage
		health_bar.value = health

func force_send_state():
	if multiplayer.is_server():
		_send_state()


func _on_shoot_cooldown_timeout() -> void:
	firePermission = true


func _on_recarga_timeout() -> void:
	bullet = 30
	municao.text = str(bullet)+"/30"
