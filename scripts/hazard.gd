extends Node2D
class_name KitchenHazard

var hazard_type: String = "fire"
var damage: int = 1
var cycle_timer: float = 0.0
var is_active: bool = false
var warn_time: float = 1.2
var active_time: float = 2.0
var cooldown_time: float = 3.0
var phase: String = "warning"

func _ready() -> void:
	z_index = 4

func setup(htype: String, pos: Vector2) -> void:
	hazard_type = htype
	global_position = pos
	phase = "warning"
	cycle_timer = warn_time
	is_active = false

func _process(delta: float) -> void:
	cycle_timer -= delta
	match phase:
		"warning":
			if cycle_timer <= 0.0:
				phase = "active"
				is_active = true
				cycle_timer = active_time
		"active":
			if cycle_timer <= 0.0:
				phase = "cooldown"
				is_active = false
				cycle_timer = cooldown_time
		"cooldown":
			if cycle_timer <= 0.0:
				phase = "warning"
				cycle_timer = warn_time
	queue_redraw()

func check_player(player: ChefPlayer) -> void:
	if not is_active or player == null:
		return
	if global_position.distance_to(player.global_position) < 28.0:
		player.take_damage(damage)

func _draw() -> void:
	match phase:
		"warning":
			var alpha := 0.5 + sin(cycle_timer * 8.0) * 0.4
			draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.8, 0.0, alpha))
			draw_string(ThemeDB.fallback_font, Vector2(-10, 5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.2, 0, alpha))
		"active":
			draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.25, 0.0, 0.85))
			for i in range(6):
				var angle: float = float(i) * (PI * 2.0 / 6.0) + cycle_timer * 4.0
				draw_circle(Vector2(cos(angle) * 16, sin(angle) * 16), 5.0, Color(1.0, 0.7, 0.1))
		"cooldown":
			draw_circle(Vector2.ZERO, 22.0, Color(0.3, 0.3, 0.3, 0.35))
