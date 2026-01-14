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
var bullet_path = preload("res://Bullet.tscn")

const JETPACK_FORCE = 20.0
const JETPACK_FUEL_MAX = 100
const JETPACK_FUEL_COST = 1.0
const JETPACK_MAXHEIGHT = 250

var jetpackFuel = JETPACK_FUEL_MAX
var jetpack_active = false



func _ready():
	target_position = global_position
	
	jet_pack_bar.value = jetpackFuel





func _physics_process(delta):
	var is_authority = multiplayer.get_unique_id() == get_multiplayer_authority()
	var is_local_player = get_multiplayer_authority() == multiplayer.get_unique_id()

	# --- LÓGICA DE ENTRADA ---
	# Somente o jogador que controla este personagem deve ler a entrada
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		_read_input()
		# Se for o host/dono, ele tem a entrada localmente.
		# Se fosse um cliente, ele enviaria a entrada. Mas como o dono do
		# objeto é o único que pode ter a autoridade, focamos em quem é local.
		# AQUI, estamos presumindo que:
		# - O HOST é local para SEU personagem.
		# - O CLIENTE A é local para SEU personagem (que tem o CLIENTE A como autoridade).

		# --- LÓGICA DE MOVIMENTO E SINCRONIZAÇÃO (SOMENTE A AUTORIDADE) ---
		_apply_movement(delta) # A autoridade aplica o movimento
		_send_state() # A autoridade envia o estado para todos
	else:
		# Se NÃO for a autoridade: Apenas interpola o estado recebido
		_apply_remote_state(delta)


# RPC para o Dono enviar o estado para todos os outros
func _send_state():
	rpc("receive_state", global_position, velocity)


@rpc("any_peer", "unreliable")
func receive_state(pos: Vector2, vel: Vector2):
	# Quem está recebendo (todos, exceto o sender)
	if multiplayer.get_unique_id() == get_multiplayer_authority():
		return

	target_position = pos
	target_velocity = vel


# O Dono é o único que precisa da entrada
func _read_input():
	input_direction = Input.get_axis("ui_left", "ui_right")
	input_jump = Input.is_action_pressed("ui_accept")
	input_fire = Input.is_action_just_pressed("Left_mouse")

# O Dono é o único que aplica o movimento
func _apply_movement(delta):
	# Seu código de movimento...
	if not is_on_floor():
		velocity += get_gravity() * delta
	

		
	if input_fire:
		fire()
		
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
		jet_pack_bar.visible = true
		jet_pack_bar.value -= JETPACK_FUEL_COST
		jet_pack_particle.emitting = true

func _on_jet_pack_cooldown_timeout() -> void:
	if jetpackFuel < 100 and is_on_floor():
		jetpackFuel += JETPACK_FUEL_COST
		jet_pack_bar.value += JETPACK_FUEL_COST
		jetpack_active = false
		jet_pack_particle.emitting = false
	if jetpackFuel >= 100:
		jet_pack_bar.visible = false

func fire():
	var bullet = bullet_path.instantiate()
	bullet.dir = rotation
	bullet.pos = $AnimatedSprite2D/Node2D.global_position
	bullet.rota = global_rotation
	get_parent().add_child(bullet)
