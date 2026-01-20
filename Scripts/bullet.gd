extends CharacterBody2D


const SPEED = 500.0
const JUMP_VELOCITY = -400.0
@onready var collision = $CollisionShape2D
var direction: Vector2
var shooter_id = -1
var damage = 10

func _ready() -> void:
	direction = Vector2(1,0).rotated(rotation)

func _physics_process(delta: float) -> void:
	
	velocity = SPEED * direction
	move_and_slide()
	# SOMENTE o servidor processa o que acontece no impacto
	if multiplayer.is_server() or multiplayer.get_unique_id() == 1:
		var quantityCollision = get_slide_collision_count()
		if quantityCollision > 0:
			var collision := get_slide_collision(0)
			_handle_collision(collision)
		


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()

	if collider == null:
		return

	# Verifica se acertou um Player
	if collider.is_in_group("Player"):
		# IMPORTANTE: Use get_multiplayer_authority a() para saber quem é o dono do player atingido
		var victim_id = collider.name
		
		# Não acertar quem disparou
		if GameManager.Players[int(victim_id)].equipe == GameManager.Players[int(shooter_id)].equipe:
			return

		
		if collider.has_method("take_damage"):
			collider.take_damage.rpc(damage, shooter_id)
	limpar_colisao.rpc()
	# Como o servidor deleta a bala e você está usando MultiplayerSpawner,
	# ela desaparecerá AUTOMATICAMENTE em todos os clientes.
	

@rpc("authority", "call_local")
func limpar_colisao():
	queue_free()
