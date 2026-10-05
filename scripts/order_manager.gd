extends Node
class_name OrderManager

signal order_completed(coins_earned: int)
signal order_expired()

var active_orders: Array[Dictionary] = []
var max_orders: int = 3
var difficulty: String = "simple"

var recipes: Dictionary = {
	"simple": ["Pork Adobo", "Sinigang", "Sinangag"],
	"medium": ["Lumpia", "Turon", "Pancit", "Kare-Kare"],
	"hard":   ["Lechon", "Bistek", "Bulalo", "Crispy Pata"]
}

func _process(delta: float) -> void:
	for i in range(active_orders.size() - 1, -1, -1):
		var ord: Dictionary = active_orders[i]
		ord["time_left"] = ord["time_left"] - delta
		if ord["time_left"] <= 0.0:
			active_orders.remove_at(i)
			order_expired.emit()

func set_difficulty(round_num: int) -> void:
	if round_num <= 4:
		difficulty = "simple"
	elif round_num <= 9:
		difficulty = "medium"
	else:
		difficulty = "hard"

func spawn_order() -> void:
	if active_orders.size() >= max_orders:
		return
	var pool: Array = recipes.get(difficulty, recipes["simple"])
	var recipe: String = pool[randi() % pool.size()]
	var time_limit: float = 50.0
	var coin_reward: int = 15
	if difficulty == "medium":
		time_limit = 65.0
		coin_reward = 30
	elif difficulty == "hard":
		time_limit = 80.0
		coin_reward = 55
	active_orders.append({
		"recipe": recipe,
		"time_left": time_limit,
		"max_time": time_limit,
		"reward": coin_reward
	})

func try_complete_order(recipe: String) -> bool:
	# "any" = serve any active order (simplified gameplay)
	if active_orders.is_empty():
		return false
	var idx: int = 0
	if recipe != "any":
		var found: bool = false
		for i in range(active_orders.size()):
			if active_orders[i].get("recipe", "") == recipe:
				idx = i
				found = true
				break
		if not found:
			return false
	var reward: int = active_orders[idx].get("reward", 15)
	active_orders.remove_at(idx)
	order_completed.emit(reward)
	return true

func clear_orders() -> void:
	active_orders.clear()
