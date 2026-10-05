extends Node2D

class_name KitchenItem

# --- Gameplay State Flags (Pure Logic) ---
var item_type := "ingredient" # "ingredient", "plate", "dish"
var item_name := "Pork"

var is_chopped := false
var is_cooked := false
var is_burnt := false
var is_dirty := false

var contents: Array[String] = []

# --- Decoupled Asset Architecture ---
# Replaceable Sprite2D node for final pixel art textures
var sprite_node: Sprite2D = null
var custom_texture: Texture2D = null


func _ready() -> void:
	# Create attached Sprite2D node for asset drop-in replacement
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	update_visual_asset()


func setup(type: String, name_id: String) -> void:
	item_type = type
	item_name = name_id
	add_to_group("kitchen_items")
	update_visual_asset()
	queue_redraw()


func set_custom_texture(texture: Texture2D) -> void:
	custom_texture = texture
	update_visual_asset()


func update_visual_asset() -> void:
	if is_instance_valid(sprite_node):
		if custom_texture != null:
			sprite_node.texture = custom_texture
			sprite_node.visible = true
		else:
			sprite_node.visible = false
	queue_redraw()


func get_display_name() -> String:
	if is_dirty:
		return "Dirty Plate"
	if item_type == "plate":
		return "Clean Plate"
	if item_type == "dish":
		return item_name

	var state_prefix := ""
	if is_burnt:
		state_prefix = "Burnt "
	elif is_cooked:
		state_prefix = "Cooked "
	elif is_chopped:
		state_prefix = "Chopped "

	return "%s%s" % [state_prefix, item_name]


func _draw() -> void:
	# Fallback Vector Drawing (used only when custom_texture is null)
	if custom_texture != null:
		return

	match item_type:
		"plate":
			if is_dirty:
				draw_circle(Vector2.ZERO, 16, Color("#4a4e69"))
				draw_circle(Vector2.ZERO, 12, Color("#6b705c"))
				draw_circle(Vector2(-3, -2), 4, Color("#a5a58d"))
			else:
				draw_circle(Vector2.ZERO, 16, Color("#e9ecef"))
				draw_circle(Vector2.ZERO, 12, Color.WHITE)
				draw_arc(Vector2.ZERO, 12, 0, TAU, 32, Color("#ced4da"), 2.0)

		"dish":
			draw_circle(Vector2.ZERO, 18, Color("#e9ecef"))
			draw_circle(Vector2.ZERO, 14, Color.WHITE)

			match item_name:
				"Adobo":
					draw_circle(Vector2(-4, 0), 7, Color("#f8f9fa"))
					draw_rect(Rect2(0, -6, 10, 12), Color("#4a2810"))
					draw_circle(Vector2(2, 2), 2, Color("#ffb703"))

				"Sinigang":
					draw_circle(Vector2.ZERO, 13, Color("#bc6c25"))
					draw_circle(Vector2(-3, -3), 4, Color("#d90429"))
					draw_circle(Vector2(3, 2), 4, Color("#70e000"))

				"Lumpia":
					draw_circle(Vector2(-4, 0), 5, Color("#f8f9fa"))
					draw_rect(Rect2(0, -8, 12, 5), Color("#d4a373"), true)
					draw_rect(Rect2(2, -1, 12, 5), Color("#bc6c25"), true)

				"Turon":
					draw_rect(Rect2(-8, -6, 16, 6), Color("#e9c46a"), true)
					draw_rect(Rect2(-6, 1, 16, 6), Color("#bc6c25"), true)
					draw_line(Vector2(-7, -4), Vector2(8, 4), Color("#d4a373"), 2)

		"ingredient":
			match item_name:
				"Pork":
					var bg_col := Color("#d90429") if not is_cooked else Color("#6f1d1b")
					if is_burnt:
						bg_col = Color("#1a1a1a")
					draw_rect(Rect2(-10, -8, 20, 16), bg_col)
					if not is_burnt:
						draw_rect(Rect2(-6, -4, 12, 4), Color("#ffccd5"))
					if is_chopped:
						draw_line(Vector2(-10, 0), Vector2(10, 0), Color.WHITE, 2)

				"Garlic/Onion":
					var col := Color("#f8f9fa") if not is_chopped else Color("#e9ecef")
					if is_cooked:
						col = Color("#d4a373")
					if is_burnt:
						col = Color("#212529")
					draw_circle(Vector2.ZERO, 9, col)
					draw_line(Vector2(0, -9), Vector2(0, -13), Color("#6c757d"), 2)

				"Tomato":
					var col := Color("#ef233c") if not is_chopped else Color("#d90429")
					if is_cooked:
						col = Color("#9b2226")
					if is_burnt:
						col = Color("#212529")
					draw_circle(Vector2.ZERO, 10, col)
					draw_circle(Vector2(0, -8), 3, Color("#38b000"))

				"Banana":
					var col := Color("#ffee32") if not is_chopped else Color("#ffd166")
					if is_cooked:
						col = Color("#ca6702")
					if is_burnt:
						col = Color("#1a1a1a")
					draw_rect(Rect2(-11, -5, 22, 10), col)

				"Wrapper":
					draw_rect(Rect2(-12, -12, 24, 24), Color("#faedcd"))
					draw_rect(Rect2(-10, -10, 20, 20), Color("#f4a261"), false, 1.5)

				"Rice":
					draw_circle(Vector2.ZERO, 11, Color("#f8f9fa"))
					draw_circle(Vector2(-3, -2), 3, Color.WHITE)
					draw_circle(Vector2(3, 2), 3, Color.WHITE)
