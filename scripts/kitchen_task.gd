extends Node2D

signal completed

var duration := 2.5
var progress := 0.0
var task_name := "Chop the possessed onions"
var finished := false


func setup(task_position: Vector2, required_time: float, title: String) -> void:
	global_position = task_position
	duration = maxf(0.5, required_time)
	task_name = title
	add_to_group("tasks")
	queue_redraw()


func tick(delta: float, player: Node2D) -> void:
	if finished:
		return

	var close_enough := global_position.distance_to(player.global_position) < 58.0
	var interacting := Input.is_physical_key_pressed(KEY_E)

	if close_enough and interacting:
		progress += delta
	else:
		progress = maxf(0.0, progress - delta * 0.35)

	if progress >= duration:
		finished = true
		completed.emit()
		queue_free()

	queue_redraw()


func get_status(player: Node2D) -> String:
	if global_position.distance_to(player.global_position) < 58.0:
		return "Hold E: %s" % task_name
	return "Task: %s" % task_name


func _draw() -> void:
	draw_rect(Rect2(-25, -20, 50, 40), Color("#5c3d2e"))
	draw_rect(Rect2(-21, -16, 42, 32), Color("#c08552"))

	var ratio := clampf(progress / duration, 0.0, 1.0)
	draw_rect(Rect2(-27, 25, 54, 8), Color("#22223b"))
	draw_rect(Rect2(-25, 27, 50 * ratio, 4), Color("#80ed99"))

	# Cutting board and angry ingredient
	draw_rect(Rect2(-15, -6, 30, 13), Color("#e9c46a"))
	draw_circle(Vector2.ZERO, 8, Color("#bc6c25"))
	draw_circle(Vector2(-3, -2), 1.2, Color.BLACK)
	draw_circle(Vector2(3, -2), 1.2, Color.BLACK)
