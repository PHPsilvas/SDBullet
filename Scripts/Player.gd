extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

const JETPACK_FORCE = 25.0
const JETPACK_FUEL_MAX = 100
const JETPACK_FUEL_COST = 1.0
const JETPACK_MAXHEIGHT = 250

var jetpackFuel = JETPACK_FUEL_MAX
var jetpack_active = false

@onready var jet_pack_bar = %JetPackBar
@onready var jet_pack_particle = %JetPackParticle

@onready var mira = $Gunrotation
@onready var anim = $AnimatedSprite2D
@export var bullet :PackedScene

var input_direction  
var miradirection = 1
var sincPos = Vector2(0,0)

@export var facing_right = true
func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	jetpackFuel = JETPACK_FUEL_MAX

func _physics_process(delta: float) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Handle jump. 
		if Input.is_action_pressed("ui_accept"):
			activate_jetpack.rpc()
		if Input.is_action_just_pressed("Fire"):
			var id = multiplayer.get_unique_id()
			fire.rpc($Gunrotation/BulletSpawn.global_position, mira.rotation, id)
			
		sincPos = global_position
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		input_direction = Input.get_axis("ui_left","ui_right")
		
			# Movimento horizontal
		if input_direction != 0:
			velocity.x = input_direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# =========================
		# DIREÇÃO DO SPRITE
		# =========================
		if input_direction > 0:
			facing_right = true
		elif input_direction < 0:
			facing_right = false

		anim.flip_h = not facing_right
		
		mira.rotation = PI*int(!facing_right)
		# =========================
		# ANIMAÇÃO
		# =========================
		if is_on_floor():
			if input_direction != 0:
				anim.play("walk")
			else:
				anim.play("idle")
		else:
			anim.play("jump")

		move_and_slide()
	else:
		global_position = global_position.lerp(sincPos, .5)
		
@rpc("any_peer","call_local")
func fire(position, rotation, shooter_id):
	var b = bullet.instantiate()
	b.global_position = $Gunrotation/BulletSpawn.global_position
	b.rotation = mira.rotation
	b.shooter_id = shooter_id
	get_tree().root.add_child(b)

@rpc("any_peer", "call_local")
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
	
