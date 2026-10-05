extends CharacterBody2D
class_name KitchenEnemy

signal enemy_died(etype: String)

var type: String = "angry_pan"
var ai_state: String = "idle"
var hp: int = 3
var max_hp: int = 3
var move_speed: float = 80.0
var attack_range: float = 38.0
var attack_cooldown: float = 0.0
var target: Node2D = null
var is_dead: bool = false

func _ready() -> void:
	z_index = 7
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	if is_dead:
		return
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if not is_instance_valid(target):
		ai_state = "idle"
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist: float = global_position.distance_to(target.global_position)
	if dist > attack_range:
		ai_state = "chase"
		var dir: Vector2 = (target.global_position - global_position).normalized()
		velocity = dir * move_speed
	else:
		ai_state = "attack"
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			_do_attack()

	move_and_slide()
	queue_redraw()

func _do_attack() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(1)
	attack_cooldown = 1.2

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	enemy_died.emit(type)
	queue_free()

func _draw() -> void:
	match type:
		"flying_knife":
			draw_rect(Rect2(-4, -14, 8, 28), Color(0.8, 0.8, 0.9))
			draw_rect(Rect2(-4, -14, 8, 8), Color(0.6, 0.55, 0.3))
		"angry_pan":
			draw_circle(Vector2.ZERO, 15.0, Color(0.25, 0.25, 0.28))
			draw_rect(Rect2(15, -4, 18, 8), Color(0.18, 0.18, 0.2))
			draw_circle(Vector2.ZERO, 8.0, Color(0.35, 0.35, 0.38))
			# Angry eyes
			draw_circle(Vector2(-5, -5), 3, Color(1, 0.1, 0.1))
			draw_circle(Vector2(5, -5), 3, Color(1, 0.1, 0.1))
		_:  # living_ingredient (tomato/carrot/etc)
			draw_circle(Vector2.ZERO, 13.0, Color(0.9, 0.2, 0.2))
			draw_circle(Vector2(-4, -4), 2.5, Color.WHITE)
			draw_circle(Vector2(5, -4), 2.5, Color.WHITE)
			draw_circle(Vector2(0, 4), 2, Color(0.6, 0.1, 0.1))
