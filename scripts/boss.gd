extends Node2D
class_name KitchenBoss

signal boss_defeated()
signal phase_changed(new_phase: int)
signal spawn_projectile(pos: Vector2, dir: Vector2)

var boss_name: String = ""
var sprite_node: Sprite2D
var max_hp: int = 200
var current_hp: int = 200
var phase: int = 1
var arena_rect: Rect2
var ai_state: String = "idle"
var ai_timer: float = 0.0
var target_pos: Vector2 = Vector2.ZERO
var move_speed: float = 90.0
var is_dead: bool = false

var tex_idle: Texture2D
var tex_attack: Texture2D
var tex_defeated: Texture2D

func _ready() -> void:
	z_index = 8

	sprite_node = Sprite2D.new()
	sprite_node.scale = Vector2(0.75, 0.75)
	add_child(sprite_node)

	# Collision area for contact damage
	var area := Area2D.new()
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 38.0
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func setup_boss(bname: String, arena: Rect2) -> void:
	boss_name = bname
	arena_rect = arena

	if boss_name == "Xiangling":
		tex_idle    = load("res://assets/processed/xiangling_idle.png") as Texture2D
		tex_attack  = load("res://assets/processed/xiangling_angry.png") as Texture2D
		tex_defeated = load("res://assets/processed/xiangling_defeated.png") as Texture2D
		max_hp = 200
		move_speed = 85.0
	elif boss_name == "XianglingRematch":
		tex_idle    = load("res://assets/processed/xiangling_angry.png") as Texture2D
		tex_attack  = load("res://assets/processed/xiangling_angry.png") as Texture2D
		tex_defeated = load("res://assets/processed/xiangling_defeated.png") as Texture2D
		max_hp = 350
		move_speed = 115.0
	elif boss_name == "Rotoven":
		tex_idle    = load("res://assets/processed/rotoven_idle.png") as Texture2D
		tex_attack  = load("res://assets/processed/rotoven_attack.png") as Texture2D
		tex_defeated = load("res://assets/processed/rotoven_defeated.png") as Texture2D
		max_hp = 500
		move_speed = 70.0
		sprite_node.scale = Vector2(0.9, 0.9)

	current_hp = max_hp
	sprite_node.texture = tex_idle
	_pick_new_state()

func _process(delta: float) -> void:
	if is_dead:
		return

	ai_timer -= delta

	match ai_state:
		"idle":
			if ai_timer <= 0.0:
				_pick_new_state()
		"move":
			global_position = global_position.move_toward(target_pos, delta * move_speed)
			if global_position.distance_to(target_pos) < 6.0:
				_pick_new_state()
		"attack":
			if ai_timer <= 0.0:
				_pick_new_state()

func _pick_new_state() -> void:
	var r := randf()
	if r < 0.45:
		ai_state = "move"
		target_pos = Vector2(
			randf_range(arena_rect.position.x + 30, arena_rect.end.x - 30),
			randf_range(arena_rect.position.y + 30, arena_rect.end.y - 30)
		)
		sprite_node.texture = tex_idle
	else:
		ai_state = "attack"
		ai_timer = 2.2 - float(phase) * 0.25
		_perform_attack()
	ai_timer = 1.5

func _perform_attack() -> void:
	sprite_node.texture = tex_attack
	var num_proj: int = 6 + phase * 2
	if boss_name == "Xiangling":
		num_proj = 8
	elif boss_name == "XianglingRematch":
		num_proj = 12
	elif boss_name == "Rotoven":
		num_proj = 5 + phase * 3

	for i in range(num_proj):
		var angle: float = float(i) * (PI * 2.0 / float(num_proj))
		var dir := Vector2(cos(angle), sin(angle))
		spawn_projectile.emit(global_position, dir)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp -= amount

	var ratio: float = float(current_hp) / float(max_hp)
	var new_phase: int = 1
	if ratio <= 0.25:
		new_phase = 4
	elif ratio <= 0.5:
		new_phase = 3
	elif ratio <= 0.75:
		new_phase = 2

	if new_phase != phase:
		phase = new_phase
		move_speed += 20.0
		phase_changed.emit(phase)

	if current_hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	sprite_node.texture = tex_defeated
	set_process(false)
	boss_defeated.emit()

func _on_body_entered(body: Node) -> void:
	if body is ChefPlayer:
		body.take_damage(1)

func _draw() -> void:
	if is_dead:
		return
	# HP bar above boss
	var bar_w := 90
	var ratio: float = float(current_hp) / float(max_hp)
	draw_rect(Rect2(-45, -55, bar_w, 10), Color(0.1, 0.05, 0.1))
	draw_rect(Rect2(-45, -55, int(bar_w * ratio), 10), Color(0.8, 0.2, 1.0))
	draw_rect(Rect2(-45, -55, bar_w, 10), Color.WHITE, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-35, -42), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
