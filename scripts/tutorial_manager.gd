extends Node

class_name TutorialManager

signal tutorial_completed

var current_step := 1

const STEP_DESCRIPTIONS := {
	1: "STEP 1: Move with [WASD] and Dash with [SHIFT]!",
	2: "STEP 2: Walk to the Pork Crate (top left) and press [SPACE] or [F] to pick up Pork!",
	3: "STEP 3: Place Pork on Cutting Board and hold [E] until it's chopped!",
	4: "STEP 4: Place chopped Pork on the Stove with [SPACE] or [F] and wait for it to cook!",
	5: "STEP 5: Pick up a Clean Plate and combine with cooked Pork to make Adobo!",
	6: "STEP 6: Walk to the Serving Pass (bottom middle) and press [SPACE] or [F] to serve!"
}


func reset_tutorial() -> void:
	current_step = 1


func get_current_instruction() -> String:
	if current_step > 6:
		return "TUTORIAL COMPLETED! Press [ENTER] to start Round 1!"
	return STEP_DESCRIPTIONS.get(current_step, "")


func notify_action(action_type: String, item: Node2D = null) -> void:
	match current_step:
		1:
			if action_type == "move_or_dash":
				current_step = 2
		2:
			if action_type == "pick_pork":
				current_step = 3
		3:
			if action_type == "chop_complete":
				current_step = 4
		4:
			if action_type == "cook_complete":
				current_step = 5
		5:
			if action_type == "plate_adobo":
				current_step = 6
		6:
			if action_type == "serve_complete":
				current_step = 7
				tutorial_completed.emit()
