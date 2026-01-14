extends CharacterBody2D

var speed = 2000
var direction := 0.0
var shooter_id := 1  # ID de quem disparou

func _ready() -> void:
	# Apenas o servidor simula a física da bala
	if not multiplayer.is_server():
		set_physics_process(false)
	
	# Auto-destruir após 5 segundos (evita balas perdidas)
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Apenas o servidor move a bala
	velocity = Vector2(speed, 0).rotated(direction)
	move_and_slide()
	
	# Detecta colisão
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		_handle_collision(collision)
		queue_free()

func _handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	
	# Se colidiu com um player
	if collider.is_in_group("player"):
		# Não atira em si mesmo
		if collider.get_multiplayer_authority() != shooter_id:
			# Aplica dano ou lógica de hit
			if collider.has_method("take_damage"):
				collider.take_damage(10, shooter_id)

# Função para inicializar a bala (chamada pelo servidor)
func initialize(spawn_pos: Vector2, spawn_rotation: float, spawn_direction: float, owner_id: int):
	global_position = spawn_pos
	global_rotation = spawn_rotation
	direction = spawn_direction
	shooter_id = owner_id
