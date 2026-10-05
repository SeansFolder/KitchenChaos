extends CharacterBody2D
class_name ChefPlayer

signal health_changed(new_health: int)
signal died()
signal dashed()
signal damaged()
signal knife_thrown()

const MOVE_SPEED_BASE := 165.0
const DASH_SPEED      := 440.0
const DASH_DURATION   := 0.18
const DASH_COOLDOWN   := 0.85
const KNIFE_COOLDOWN  := 0.45
const KNIFE_SPEED     := 440.0

# Play area bounds (matches kitchen layout — avoids counter rows)
const BOUNDS_MIN := Vector2(77,  144)
const BOUNDS_MAX := Vector2(870, 436)
var movement_bounds := Rect2(77, 144, 793, 292)

var health:     int   = 3
var max_health: int   = 3
var extra_lives: int  = 0
var move_speed: float = MOVE_SPEED_BASE

var is_dashing:          bool  = false
var dash_timer:          float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_dir:            Vector2 = Vector2.ZERO
var knife_cooldown_timer: float = 0.0

var is_invulnerable: bool  = false
var invuln_timer:    float = 0.0

var held_item:   String = ""
var sprite_node: Sprite2D

var tex_idle: Texture2D
var tex_walk: Texture2D
var tex_cook: Texture2D

func _ready() -> void:
	name    = "Player"
	z_index = 10

	# Physics layers: layer 1 = player, mask 1+2 = collides with walls+stations
	collision_layer = 1
	collision_mask  = 1 | 2

	var col   := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	col.shape    = shape
	add_child(col)

	tex_idle = load("res://assets/processed/jeff_idle.png") as Texture2D
	tex_walk = load("res://assets/processed/jeff_walk.png") as Texture2D
	tex_cook = load("res://assets/processed/jeff_cook.png") as Texture2D

	sprite_node         = Sprite2D.new()
	sprite_node.texture = tex_idle
	sprite_node.scale   = Vector2(0.30, 0.30)
	sprite_node.z_index = 1
	add_child(sprite_node)

func _process(delta: float) -> void:
	knife_cooldown_timer = maxf(knife_cooldown_timer - delta, 0.0)
	if is_invulnerable:
		invuln_timer -= delta
		if invuln_timer <= 0.0:
			is_invulnerable        = false
			sprite_node.modulate.a = 1.0
		else:
			sprite_node.modulate.a = 0.35 if int(invuln_timer * 14) % 2 == 0 else 1.0
	queue_redraw()

func attack_at(target_position: Vector2) -> void:
	if knife_cooldown_timer > 0.0:
		return
	var direction := global_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		return

	var knife := Projectile.new()
	knife.is_player_projectile = true
	knife.direction = direction
	knife.speed = KNIFE_SPEED
	knife.lifetime = clampf(global_position.distance_to(target_position) / KNIFE_SPEED, 0.12, 1.6)
	knife.global_position = global_position + direction * 19.0
	knife.rotation = direction.angle()
	get_parent().add_child(knife)
	knife_cooldown_timer = KNIFE_COOLDOWN
	knife_thrown.emit()

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		dash_timer -= delta
		velocity    = dash_dir * DASH_SPEED
		if dash_timer <= 0.0:
			is_dashing = false
			velocity   = Vector2.ZERO
	else:
		var dir := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):    dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):   dir.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):   dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):  dir.x += 1.0
		dir = dir.normalized()

		velocity = dir * move_speed

		# Sprite direction / texture
		if dir != Vector2.ZERO:
			if sprite_node.texture != tex_walk:
				sprite_node.texture = tex_walk
			if dir.x < 0.0:   sprite_node.flip_h = true
			elif dir.x > 0.0: sprite_node.flip_h = false
		else:
			if sprite_node.texture != tex_idle:
				sprite_node.texture = tex_idle

		# Dash trigger
		if (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SHIFT)) \
				and dash_cooldown_timer <= 0.0 and dir != Vector2.ZERO:
			is_dashing        = true
			dash_timer        = DASH_DURATION
			dash_cooldown_timer = DASH_COOLDOWN
			dash_dir          = dir
			is_invulnerable   = true
			invuln_timer      = DASH_DURATION
			dashed.emit()

	move_and_slide()

	# Hard clamp to play area (secondary safety net)
	global_position.x = clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x)
	global_position.y = clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)

func take_damage(amount: int) -> void:
	if is_invulnerable or is_dashing: return
	health -= amount
	damaged.emit()
	health_changed.emit(health)
	if health <= 0:
		if extra_lives > 0:
			extra_lives -= 1
			health       = max_health
			health_changed.emit(health)
			make_invulnerable(2.0)
		else:
			died.emit()
			set_physics_process(false)
			set_process(false)
	else:
		make_invulnerable(0.9)

func make_invulnerable(time: float) -> void:
	is_invulnerable = true
	invuln_timer    = time

func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	health_changed.emit(health)

func _draw() -> void:
	# Held item bubble above head
	if held_item != "":
		var item_col := _item_color(held_item)
		# Bubble
		draw_circle(Vector2(0, -30), 12, Color(0,0,0,0.55))
		draw_circle(Vector2(0, -30), 11, item_col)
		draw_circle(Vector2(0, -30), 11, Color(1,1,1,0.4), false, 1.5)
		# Short label
		var short := held_item.left(3).to_upper()
		draw_string(ThemeDB.fallback_font, Vector2(-8, -26), short, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)

	# Procedural fallback if sprite texture missing
	if sprite_node != null and sprite_node.texture != null:
		return
	draw_circle(Vector2.ZERO, 13.0, Color("#f2d6b3"))
	draw_rect(Rect2(-10, 4, 20, 18), Color("#f4f1de"))
	draw_rect(Rect2(-7, 8, 14, 14), Color("#d1495b"))
	draw_rect(Rect2(-10,-16, 20, 10), Color.WHITE)
	draw_circle(Vector2(-4,-2), 2.0, Color.BLACK)
	draw_circle(Vector2(4, -2), 2.0, Color.BLACK)

func _item_color(item: String) -> Color:
	var lower := item.to_lower()
	if "plate" in lower:    return Color(0.9, 0.9, 0.97)
	if "pork" in lower:     return Color(0.9, 0.62, 0.52)
	if "tomato" in lower:   return Color(0.9, 0.15, 0.15)
	if "banana" in lower:   return Color(0.95, 0.88, 0.1)
	if "rice" in lower:     return Color(0.95, 0.95, 0.85)
	if "carrot" in lower:   return Color(0.95, 0.55, 0.1)
	if "chopped" in lower:  return Color(0.65, 0.88, 0.45)
	if "cooked" in lower:   return Color(0.78, 0.48, 0.22)
	if "plated" in lower:   return Color(0.75, 0.85, 0.95)
	return Color(0.7, 0.7, 0.7)
