extends StaticBody2D
class_name KitchenStation

signal task_completed(stype: String)
signal plate_washed()
signal order_served(recipe: String)

var station_type:      String = "cutting_board"
var crate_item:        String = ""
var progress:          float  = 0.0
var max_progress:      float  = 100.0
var task_speed_multiplier: float = 1.0
var is_occupied:       bool   = false
var item_held:         String = ""
var clean_plate_count: int    = 5
var player_nearby:     bool   = false

# Size of the station tile
const SZ := 44.0
const HSZ := SZ / 2.0

func _ready() -> void:
	z_index = 5
	# StaticBody2D collision — blocks CharacterBody2D movement
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SZ, SZ)
	col.shape  = shape
	add_child(col)

func interaction_hint(player: ChefPlayer) -> String:
	match station_type:
		"crate":
			return "TAKE " + crate_item.to_upper() if player.held_item == "" else "HANDS FULL"
		"plate_crate":
			return "TAKE PLATE" if player.held_item == "" and clean_plate_count > 0 else "PLATES EMPTY"
		"cutting_board", "stove":
			var process_name := "CHOP" if station_type == "cutting_board" else "COOK"
			if is_occupied:
				if progress >= max_progress and player.held_item == "":
					return "COLLECT " + ("CHOPPED" if station_type == "cutting_board" else "COOKED")
				return "STATION BUSY"
			return "NEED INGREDIENT" if player.held_item == "" else process_name + " INGREDIENT"
		"assembly":
			return "PLATE MEAL" if player.held_item != "" and player.held_item != "plate" and player.held_item != "plated_meal" else "MEAL READY"
		"pass":
			return "SERVE MEAL" if player.held_item == "plated_meal" else "NEED PLATED MEAL"
		"plate_return":
			return "RETURN PLATE" if player.held_item == "dirty_plate" else "DIRTY PLATES"
		"sink":
			if player.held_item == "dirty_plate":
				return "WASH PLATE"
			if is_occupied and progress >= max_progress:
				return "TAKE CLEAN PLATE"
			return "WASHING" if is_occupied else "SINK"
	return "USE STATION"

func interact(player: ChefPlayer) -> void:
	match station_type:
		"crate":
			if player.held_item == "" and crate_item != "":
				player.held_item = crate_item

		"plate_crate":
			if player.held_item == "" and clean_plate_count > 0:
				player.held_item = "plate"
				clean_plate_count -= 1

		"cutting_board":
			if player.held_item != "" and player.held_item != "plate" and not is_occupied:
				item_held    = player.held_item
				player.held_item = ""
				is_occupied  = true
				progress     = 0.0
			elif is_occupied and progress >= max_progress and player.held_item == "":
				player.held_item = "chopped_" + item_held
				is_occupied  = false
				item_held    = ""
				progress     = 0.0

		"stove":
			if player.held_item != "" and player.held_item != "plate" and not is_occupied:
				item_held    = player.held_item
				player.held_item = ""
				is_occupied  = true
				progress     = 0.0
			elif is_occupied and progress >= max_progress and player.held_item == "":
				player.held_item = "cooked_" + item_held
				is_occupied  = false
				item_held    = ""
				progress     = 0.0

		"assembly":
			if player.held_item != "" and player.held_item != "plate" and player.held_item != "plated_meal":
				item_held        = player.held_item
				player.held_item = "plated_meal"
			elif player.held_item == "plated_meal":
				pass # ready to serve

		"pass":
			if player.held_item == "plated_meal":
				player.held_item = ""
				order_served.emit("any")

		"plate_return":
			if player.held_item == "dirty_plate":
				player.held_item = ""
				item_held    = "dirty_plate"
				is_occupied  = true
				progress     = 0.0

		"sink":
			if player.held_item == "dirty_plate":
				player.held_item = ""
				is_occupied  = true
				item_held    = "dirty_plate"
				progress     = 0.0
			elif is_occupied and progress >= max_progress:
				is_occupied  = false
				item_held    = ""
				progress     = 0.0
				clean_plate_count += 1
				plate_washed.emit()

	queue_redraw()

func _process(delta: float) -> void:
	if is_occupied and progress < max_progress:
		var spd: float = 20.0
		if station_type == "stove":        spd = 14.0
		elif station_type == "sink":       spd = 30.0
		elif station_type == "cutting_board": spd = 22.0
		progress += delta * spd * task_speed_multiplier
		if progress >= max_progress:
			progress = max_progress
			task_completed.emit(station_type)
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font

	# ── Base tile ──────────────────────────────────────────────────────────
	var base  := _base_color()
	var top   := _top_color()
	# Shadow
	draw_rect(Rect2(-HSZ+2, -HSZ+2, SZ, SZ), Color(0,0,0,0.4))
	# Main body (counter top)
	draw_rect(Rect2(-HSZ, -HSZ, SZ, SZ), base)
	# Inset top surface
	draw_rect(Rect2(-HSZ+4, -HSZ+4, SZ-8, SZ-8), top)
	# Border
	draw_rect(Rect2(-HSZ, -HSZ, SZ, SZ), Color(0,0,0,0.6), false, 1.5)

	# ── Type-specific visuals ──────────────────────────────────────────────
	match station_type:
		"cutting_board":
			# Wooden board
			draw_rect(Rect2(-12,-12,24,24), Color(0.82,0.68,0.44))
			draw_rect(Rect2(-12,-12,24,24), Color(0.55,0.4,0.2), false, 1.0)
			# Knife marks
			for i in range(3):
				var lx := -8.0 + i * 8.0
				draw_line(Vector2(lx,-10), Vector2(lx,10), Color(0.6,0.5,0.3,0.5), 1.0)
			if item_held != "":
				_draw_item_on_surface(item_held)

		"stove":
			# Grate lines
			for i in range(4):
				draw_line(Vector2(-HSZ+6, -HSZ+8+i*8), Vector2(HSZ-6, -HSZ+8+i*8), Color(0.15,0.15,0.15), 1.5)
			# Burners
			for bx in [-10.0, 10.0]:
				for by in [-9.0, 9.0]:
					var bc := Color(0.9,0.3,0.0,0.9) if is_occupied else Color(0.2,0.2,0.22)
					draw_circle(Vector2(bx,by), 6, bc)
					if is_occupied:
						draw_circle(Vector2(bx,by), 3, Color(1.0,0.8,0.1,0.9))
			if item_held != "":
				_draw_item_on_surface(item_held)

		"sink":
			draw_rect(Rect2(-12,-12,24,24), Color(0.6,0.82,0.95))
			draw_rect(Rect2(-12,-12,24,24), Color(0.3,0.55,0.7), false, 1.5)
			# Drain
			draw_circle(Vector2(0,4), 4, Color(0.35,0.55,0.68))
			draw_circle(Vector2(0,4), 2, Color(0.2,0.35,0.5))
			# Faucet
			draw_rect(Rect2(-2,-14,4,10), Color(0.7,0.7,0.75))
			draw_rect(Rect2(-6,-14,12,3), Color(0.7,0.7,0.75))

		"crate":
			# Wooden crate look
			draw_rect(Rect2(-HSZ+4,-HSZ+4,SZ-8,SZ-8), Color(0.72,0.52,0.28))
			draw_line(Vector2(-HSZ+4,0), Vector2(HSZ-4,0), Color(0.5,0.36,0.18), 2.0)
			draw_line(Vector2(0,-HSZ+4), Vector2(0,HSZ-4), Color(0.5,0.36,0.18), 2.0)
			# Corner bolts
			for cx2 in [-HSZ+8, HSZ-8]:
				for cy2 in [-HSZ+8, HSZ-8]:
					draw_circle(Vector2(cx2,cy2), 3, Color(0.4,0.3,0.15))
			# Label
			var short := crate_item.left(5) if crate_item.length() > 5 else crate_item
			draw_string(font, Vector2(-16, 5), short, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
			# Item icon
			_draw_ingredient_icon(crate_item, Vector2(0,-8), 7)

		"plate_crate":
			# Stack of plates visual
			for i in range(3):
				var py2 := -6 + i * 5
				draw_ellipse_approx(Vector2(0, py2), 10, 4, Color(0.9,0.9,0.97,0.85))
			draw_string(font, Vector2(-8, 14), "x"+str(clean_plate_count), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3,0.3,0.5))

		"assembly":
			# Plating counter with plate circle
			draw_circle(Vector2(0,0), 13, Color(0.88,0.88,0.95))
			draw_circle(Vector2(0,0), 13, Color(0.6,0.6,0.75), false, 1.5)
			draw_circle(Vector2(0,0), 8, Color(0.95,0.95,1.0))
			draw_string(font, Vector2(-15,16), "PLATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5,0.5,0.65))
			if item_held != "":
				_draw_item_on_surface(item_held)

		"pass":
			# Service window / bell
			draw_rect(Rect2(-16,-8,32,16), Color(0.3,0.65,0.3))
			draw_rect(Rect2(-16,-8,32,16), Color(0.2,0.45,0.2), false, 1.5)
			# Bell shape
			draw_circle(Vector2(0,-4), 6, Color(0.9,0.8,0.2))
			draw_rect(Rect2(-8,2,16,4), Color(0.75,0.65,0.15))
			draw_string(font, Vector2(-14,16), "SERVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3,0.65,0.3))

		"plate_return":
			draw_rect(Rect2(-12,-12,24,24), Color(0.55,0.38,0.28))
			draw_string(font, Vector2(-16,5), "RETURN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8,0.7,0.6))

	# ── Progress bar ────────────────────────────────────────────────────────
	if is_occupied:
		if progress < max_progress:
			draw_rect(Rect2(-HSZ, -HSZ-10, SZ, 7), Color(0.1,0.1,0.1))
			var fill_col := Color(0.2,0.9,0.2) if progress < 70 else Color(0.9,0.85,0.1)
			draw_rect(Rect2(-HSZ, -HSZ-10, SZ*(progress/max_progress), 7), fill_col)
			draw_rect(Rect2(-HSZ, -HSZ-10, SZ, 7), Color(0.5,0.5,0.5), false, 1.0)
		else:
			# Ready pulse
			draw_circle(Vector2(HSZ-6, -HSZ+6), 7, Color(0.2,0.9,0.2))
			draw_string(font, Vector2(HSZ-12, -HSZ+10), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

	# ── Proximity highlight ─────────────────────────────────────────────────
	if player_nearby:
		draw_rect(Rect2(-HSZ,-HSZ,SZ,SZ), Color(1,0.95,0.3,0.28), false, 2.5)

# ── Drawing helpers ──────────────────────────────────────────────────────────
func _base_color() -> Color:
	match station_type:
		"stove":        return Color(0.18,0.18,0.20)
		"sink":         return Color(0.42,0.58,0.68)
		"crate":        return Color(0.55,0.40,0.20)
		"plate_crate":  return Color(0.30,0.30,0.46)
		"pass":         return Color(0.18,0.42,0.18)
		"assembly":     return Color(0.28,0.28,0.42)
		"plate_return": return Color(0.35,0.24,0.16)
		_:              return Color(0.58,0.46,0.28)  # cutting_board default

func _top_color() -> Color:
	match station_type:
		"stove":        return Color(0.22,0.22,0.25)
		"sink":         return Color(0.50,0.72,0.82)
		"crate":        return Color(0.66,0.50,0.28)
		"plate_crate":  return Color(0.36,0.36,0.54)
		"pass":         return Color(0.22,0.52,0.22)
		"assembly":     return Color(0.34,0.34,0.52)
		"plate_return": return Color(0.44,0.30,0.22)
		_:              return Color(0.72,0.58,0.38)

func _draw_item_on_surface(item: String) -> void:
	var short := item.split("_")[0] if "_" in item else item
	_draw_ingredient_icon(short, Vector2(0,0), 8)

func _draw_ingredient_icon(item_name: String, pos: Vector2, radius: float) -> void:
	var col := Color(0.85, 0.2, 0.15)  # default red
	match item_name.to_lower():
		"pork":    col = Color(0.9, 0.65, 0.55)
		"tomato":  col = Color(0.9, 0.15, 0.15)
		"banana":  col = Color(0.95, 0.88, 0.1)
		"rice":    col = Color(0.95, 0.95, 0.85)
		"carrot":  col = Color(0.95, 0.55, 0.1)
		"plate":   col = Color(0.9, 0.9, 0.97)
		"chopped": col = Color(0.7, 0.85, 0.5)
		"cooked":  col = Color(0.75, 0.45, 0.2)
		"plated":  col = Color(0.9, 0.9, 0.97)
	draw_circle(pos, radius, col)
	draw_circle(pos, radius, Color(0,0,0,0.35), false, 1.0)

func draw_ellipse_approx(center: Vector2, rx: float, ry: float, col: Color) -> void:
	# Approximate ellipse with a stretched circle using polygon
	var pts: PackedVector2Array = []
	for i in range(20):
		var a := float(i) / 20.0 * PI * 2.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, col)
