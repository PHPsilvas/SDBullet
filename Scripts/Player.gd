extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

const JETPACK_FORCE = 25.0
const JETPACK_FUEL_MAX = 100
const JETPACK_FUEL_COST = 1.0
const JETPACK_MAXHEIGHT = 250

const HEALTH_MAX = 150

var jetpackFuel = JETPACK_FUEL_MAX
var jetpack_active = false

var health
var nome:String
var fire_cooldown = true

@onready var jet_pack_bar = %JetPackBar
@onready var jet_pack_particle = %JetPackParticle

@onready var HealthBar = %HealthBar

@onready var mira = $Gunrotation
@onready var anim = $AnimatedSprite2D
@export var bullet :PackedScene


var input_direction  
var miradirection = 1
var sincPos = Vector2(0,0)

@export var facing_right = true
func _ready() -> void:
	set_multiplayer_authority(str(name).to_int())
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	if not is_multiplayer_authority():
		jet_pack_bar.visible = false
	jetpackFuel = JETPACK_FUEL_MAX
	health = HEALTH_MAX
	nome = str(GameManager.Players[str(self.name).to_int()].name)
	$NickName.text = nome 
	

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
			if fire_cooldown == true:
				fire_cooldown = false
				$FireCooldown.start()
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
	b.collision_layer = 0
	b.collision_mask = 0
	b.set_collision_mask_value(5, true)
	if int(GameManager.Players[shooter_id].equipe) == 0:
		b.set_collision_mask_value(2, true)
		b.set_collision_layer_value(3, true)
	else:
		b.set_collision_mask_value(1, true)
		b.set_collision_layer_value(4, true)
	
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
	
@rpc("any_peer","call_local")
func take_damage(damage, shooter_id):
	health -= damage
	HealthBar.value -= damage
	if health <= 0:
		queue_free()
	


func _on_fire_cooldown_timeout() -> void:
	fire_cooldown = true
	pass # Replace with function body.
