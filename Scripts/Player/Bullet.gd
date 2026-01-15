extends CharacterBody2D

@export var speed := 2000.0
@export var damage := 10

var direction := 0.0
var shooter_id := -1


func _ready() -> void:
	# Apenas o servidor simula a física da bala
	if not multiplayer.is_server():
		set_physics_process(false)

	# Auto-destruição (server controla)
	if multiplayer.is_server():
		await get_tree().create_timer(5.0).timeout
		queue_free()


func _physics_process(delta):
	if multiplayer.is_server():
		velocity = Vector2.RIGHT.rotated(direction) * speed
		move_and_slide()

	if get_slide_collision_count() > 0:
		var collision := get_slide_collision(0)
		_handle_collision(collision)
		queue_free()


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()

	if collider == null:
		return

	# Player
	if collider.is_in_group("player"):
		# Não acertar quem disparou
		if collider.get_multiplayer_authority() == shooter_id:
			return

		if collider.has_method("take_damage"):
			collider.take_damage(damage, shooter_id)


# =========================
# INICIALIZAÇÃO (SERVER)
# =========================
func initialize(
	spawn_pos: Vector2,
	spawn_rotation: float,
	spawn_direction: float,
	owner_id: int
) -> void:
	global_position = spawn_pos
	global_rotation = spawn_rotation
	direction = spawn_direction
	shooter_id = owner_id
