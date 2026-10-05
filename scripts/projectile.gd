extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 280.0
var damage: int = 1
var lifetime: float = 3.5
var is_player_projectile: bool = false

const BOSS_DAMAGE_MULTIPLIER := 3

func _ready() -> void:
	z_index = 11 if is_player_projectile else 6
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	# Out of screen bounds
	if global_position.x < -20 or global_position.x > 980 or global_position.y < -20 or global_position.y > 560:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if is_player_projectile:
		if body is KitchenEnemy:
			body.take_damage(damage)
		elif body is ChefPlayer:
			return
		queue_free()
		return
	if body is ChefPlayer:
		body.take_damage(damage)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not is_player_projectile:
		return
	var target := area.get_parent()
	if target is KitchenBoss:
		target.take_damage(damage * BOSS_DAMAGE_MULTIPLIER)
		queue_free()

func _draw() -> void:
	if is_player_projectile:
		var blade := PackedVector2Array([
			Vector2(-7, -3), Vector2(8, -3), Vector2(14, 0),
			Vector2(8, 3), Vector2(-7, 3)
		])
		draw_colored_polygon(blade, Color(0.82, 0.9, 0.96))
		draw_line(Vector2(-7, 0), Vector2(10, 0), Color.WHITE, 1.0)
		draw_rect(Rect2(-13, -3, 6, 6), Color(0.48, 0.24, 0.12))
		return
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.6, 0.1))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.95, 0.3))
