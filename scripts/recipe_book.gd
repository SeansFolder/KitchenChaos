extends Node

class_name RecipeBook

const RECIPE_PAGES := [
	{
		"title": "PAGE 1/5: PORK ADOBO (NATIONAL CLASSIC)",
		"payout": "20 Coins + Speed Tip",
		"desc": "Savory marinated pork braised to perfection. The ultimate comfort dish!",
		"ingredients": [
			"• Raw Pork (from Pork Crate)",
			"• Rice (from Rice Crate)",
			"• Clean Plate (from Plates Stack Counter)"
		],
		"steps": [
			"1. FETCH: Walk to Pork Crate (top left) and press [SPACE] or [F] to pick up Pork.",
			"2. CHOP: Place Pork on Cutting Board ([SPACE]/[F]), then HOLD [E] to chop.",
			"3. COOK: Place chopped Pork onto the Stove ([SPACE]/[F]). Wait for it to cook!",
			"   ⚠️ CAUTION: Remove before the burn bar fills or it turns to burnt charcoal!",
			"4. PLATE: Grab a Clean Plate, walk to cooked Pork on Stove, press [SPACE]/[F].",
			"5. SERVE: Carry plated Pork Adobo to the Serving Pass Counter ([SPACE]/[F]).",
			"6. CLEAN: Pick up returned dirty plate at Return Counter, wash at Sink (Hold [E])."
		]
	},
	{
		"title": "PAGE 2/5: SINIGANG SOUP (SOUR TAMARIND BROTH)",
		"payout": "25 Coins + Speed Tip",
		"desc": "Hearty sour tamarind stew loaded with tender pork and juicy fresh tomatoes.",
		"ingredients": [
			"• Raw Pork (from Pork Crate)",
			"• Fresh Tomato (from Tomato Crate)",
			"• Clean Plate / Soup Bowl (from Plates Stack Counter)"
		],
		"steps": [
			"1. FETCH: Grab Pork and Tomato from their respective crates with [SPACE]/[F].",
			"2. CHOP: Place on Cutting Board and HOLD [E] until each ingredient is chopped.",
			"3. SIMMER: Place on Stove pot ([SPACE]/[F]) and let it simmer to perfection.",
			"4. PLATE: Combine cooked soup ingredients with a Clean Plate ([SPACE]/[F]).",
			"5. SERVE: Deliver hot Sinigang Soup to the Pass Counter for +25 Coins!",
			"6. RECOVER: Delivering this dish reduces Kitchen Chaos by -15%!"
		]
	},
	{
		"title": "PAGE 3/5: CRISPY LUMPIA (GOLDEN SPRING ROLLS)",
		"payout": "18 Coins + Speed Tip",
		"desc": "Crispy fried spring rolls stuffed with savory minced seasoned pork.",
		"ingredients": [
			"• Raw Pork (from Pork Crate)",
			"• Lumpia Wrapper (from Wrapper Crate)",
			"• Clean Plate (from Plates Stack Counter)"
		],
		"steps": [
			"1. FETCH & CHOP: Grab Pork from Crate, chop fine at Cutting Board (Hold [E]).",
			"2. WRAP: Grab a Wrapper from Wrapper Crate and assemble with chopped pork.",
			"3. DEEP FRY: Place rolled lumpia on Stove Kawali to fry until golden crispy.",
			"4. PLATE: Pick up with a Clean Plate from the stack to finish the dish.",
			"5. SERVE: Deliver to the Serving Pass Counter for hungry customers!",
			"6. WASH: Don't forget to wash returned dirty plates at the Sink!"
		]
	},
	{
		"title": "PAGE 4/5: SWEET TURON (CARAMELIZED BANANA ROLLS)",
		"payout": "22 Coins + Speed Tip",
		"desc": "Sweet saba banana wrapped in a crispy pastry sheet glazed with caramelized sugar.",
		"ingredients": [
			"• Sweet Saba Banana (from Banana Crate)",
			"• Lumpia Wrapper (from Wrapper Crate)",
			"• Clean Plate (from Plates Stack Counter)"
		],
		"steps": [
			"1. SLICE: Grab Banana from Banana Crate, slice at Cutting Board (Hold [E]).",
			"2. ROLL: Combine sliced banana with Wrapper from Wrapper Crate.",
			"3. CARAMELIZE: Fry on Stove Kawali until crispy golden with brown sugar glaze.",
			"4. PLATE: Combine with Clean Plate from the clean plates stack counter.",
			"5. SERVE: Deliver Sweet Turon to the Pass Counter for quick tips!",
			"6. PREVENT BURNS: High heat! Watch the stove so sugar doesn't scorch into chaos."
		]
	},
	{
		"title": "PAGE 5/5: KITCHEN HYGIENE & CHAOS EXPLOSION PREVENTION",
		"payout": "Essential Survival Rules",
		"desc": "How to keep Chef Jeff alive and prevent the kitchen from exploding!",
		"ingredients": [
			"• Clean Plate Stack: Spawns clean plates (Max 5 at start)",
			"• Return Counter: Customers return dirty plates 2.0s after eating",
			"• Washing Sink: Cleans dirty plates (Hold [E]) & cools Kitchen Chaos"
		],
		"steps": [
			"1. THE DISHWASHING LOOP: Orders served -> Customers eat -> Dirty plate appears.",
			"2. RESTOCK PLATES: Take dirty plates to Sink, Hold [E]. Clean plates restock!",
			"3. CHAOS METER (0%-100%): Burnt food (+7%/s) & dirty plates (+3.5%/s) build chaos.",
			"4. DANGER: If Chaos reaches 100%, THE ENTIRE KITCHEN EXPLODES and you lose!",
			"5. COOL DOWN CHAOS: Wash plates (-8% Chaos) and serve dishes (-15% Chaos).",
			"6. 3 HEARTS: Avoid flying knives and flames! Lose all 3 hearts = Game Over."
		]
	}
]


static func get_page_count() -> int:
	return RECIPE_PAGES.size()


static func get_recipe_page_text(page_idx: int) -> String:
	var idx := clampi(page_idx, 0, RECIPE_PAGES.size() - 1)
	var p: Dictionary = RECIPE_PAGES[idx]

	var txt: String = "📖 " + str(p.get("title", "")) + "\n"
	txt += "Payout: " + str(p.get("payout", "")) + "\n"
	txt += str(p.get("desc", "")) + "\n\n"

	txt += "INGREDIENTS NEEDED:\n"
	var ingredients: Array = p.get("ingredients", [])
	for ing in ingredients:
		txt += "  " + str(ing) + "\n"

	txt += "\nHOW TO MAKE & SERVE:\n"
	var steps: Array = p.get("steps", [])
	for st in steps:
		txt += "  " + str(st) + "\n"

	txt += "\n[←/A/1] PREV PAGE   |   [→/D/2] NEXT PAGE   |   [B/ESC] BACK TO MENU"
	return txt


static func get_recipe_book_text() -> String:
	return get_recipe_page_text(0)
