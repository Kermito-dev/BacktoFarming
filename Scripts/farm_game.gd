extends Node2D

const PLAYER_SCENE = preload("res://Scenes/characters/playerA/player.tscn")
const TILE := 32
const FARM_COLS := 4
const FARM_ROWS := 3

var player: CharacterBody2D
var camera: Camera2D
var crops := {}
var tilled := {}
var day := 1
var time_minutes := 8 * 60
var day_seconds := 0.0
var clock_accumulator := 0.0
var selected_tool := "Hoe"
var inventory := {"Seeds": 8, "Lemons": 0, "Coins": 25}
var intro_step := 0
var intro_active := true
var message := ""
var message_timer := 0.0
var crop_timer := 0.0
var canvas: CanvasLayer
var panel: Panel
var title_label: Label
var story_label: Label
var continue_label: Label
var hud_label: Label
var hint_label: Label
var hotbar_buttons: Array[Button] = []
var money_label: Label
var seeds_label: Label
var lemons_label: Label

const STORY := [
	"Your grandfather's farm has been quiet for years. The weeds have swallowed the rows, and the old windmill barely turns.",
	"His last letter was simple: 'The land remembers you. Come home, plant something, and let the seasons begin again.'",
	"You arrive with a handful of seeds, a little money, and a promise to make this place bloom. Welcome back, farmer."
]

func _ready() -> void:
	_build_world()
	_build_ui()
	_show_intro()

func _build_world() -> void:
	player = PLAYER_SCENE.instantiate()
	player.set_script(load("res://Scripts/player_controller.gd"))
	player.position = Vector2(315, 300)
	add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(320, 180)
	camera.zoom = Vector2(2, 2)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 640
	camera.limit_bottom = 480
	player.add_child(camera)
	camera.position = Vector2.ZERO
	camera.enabled = true

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-210, -112)
	panel.size = Vector2(420, 224)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_theme_constant_override("margin_left", 22)
	vbox.add_theme_constant_override("margin_right", 22)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(vbox)
	title_label = Label.new()
	title_label.text = "BACK TO THE FARM"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)
	story_label = Label.new()
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(story_label)
	continue_label = Label.new()
	continue_label.text = "SPACE / ENTER  •  Continue"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(continue_label)
	hud_label = Label.new()
	hud_label.position = Vector2(12, 10)
	hud_label.add_theme_font_size_override("font_size", 15)
	root.add_child(hud_label)
	_build_hotbar(root)
	_build_inventory_corner(root)
	hint_label = Label.new()
	hint_label.position = Vector2(12, 300)
	hint_label.add_theme_font_size_override("font_size", 13)
	root.add_child(hint_label)
	_update_ui()

func _show_intro() -> void:
	panel.visible = true
	_update_story()

func _update_story() -> void:
	story_label.text = STORY[intro_step]

func _input(event: InputEvent) -> void:
	if intro_active:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
			intro_step += 1
			if intro_step >= STORY.size():
				intro_active = false
				panel.visible = false
				message = "Welcome home! Start by tilling a plot."
				message_timer = 4.0
			else:
				_update_story()
		return
	if event.is_action_pressed("tool_hoe"):
		selected_tool = "Hoe"
	elif event.is_action_pressed("tool_seed"):
		selected_tool = "Seeds"
	elif event.is_action_pressed("tool_water"):
		selected_tool = "Water"
	elif event.is_action_pressed("tool_harvest"):
		selected_tool = "Harvest"
	elif event.is_action_pressed("interact"):
		_use_tool()
	elif event.is_action_pressed("sleep"):
		_sleep()
	_update_ui()

func _process(delta: float) -> void:
	if intro_active:
		return
	day_seconds += delta
	time_minutes += int(delta * 2.0)
	if time_minutes >= 24 * 60:
		_sleep()
	crop_timer += delta
	if crop_timer >= 1.0:
		crop_timer = 0
		for key in crops.keys():
			if crops[key]["watered"] and crops[key]["stage"] < 3:
				crops[key]["stage"] += 1
				crops[key]["watered"] = false
		_update_ui()
	if message_timer > 0:
		message_timer -= delta
	_update_ui()

func _use_tool() -> void:
	if _near_market():
		_handle_market()
		_update_ui()
		return
	var key := _nearest_plot()
	if key == "":
		_show_message("Stand close to a garden plot.")
		return
	match selected_tool:
		"Hoe":
			if crops.has(key):
				_show_message("A crop is growing here!")
			else:
				tilled[key] = true
				_show_message("Soil tilled. Switch to Seeds to plant.")
		"Seeds":
			if not tilled.has(key):
				_show_message("Till the soil first with 1 / Hoe.")
			elif crops.has(key):
				_show_message("Something is already planted here.")
			elif inventory["Seeds"] <= 0:
				_show_message("Out of lemon seeds! Buy more at the market.")
			else:
				crops[key] = {"stage": 0, "watered": false}
				inventory["Seeds"] -= 1
				_show_message("Lemon seed planted. Water it!")
		"Water":
			if crops.has(key) and crops[key]["stage"] < 3:
				crops[key]["watered"] = true
				_show_message("Watered! It will grow with time.")
			else:
				_show_message("Plant a seed first.")
		"Harvest":
			if crops.has(key) and crops[key]["stage"] >= 3:
				crops.erase(key)
				inventory["Lemons"] += 1
				_show_message("Harvested a lemon! Sell it at the market.")
			else:
				_show_message("This crop isn't ready yet.")
	_update_ui()
	queue_redraw()

func _nearest_plot() -> String:
	var best := ""
	var best_dist := 99999.0
	for row in FARM_ROWS:
		for col in FARM_COLS:
			var key := str(col) + "," + str(row)
			var center := Vector2(224 + col * 42, 160 + row * 42)
			var dist := player.position.distance_to(center)
			if dist < best_dist:
				best_dist = dist
				best = key
	return best if best_dist < 46 else ""

func _sleep() -> void:
	day += 1
	time_minutes = 6 * 60
	day_seconds = 0
	for key in crops.keys():
		if crops[key]["watered"] and crops[key]["stage"] < 3:
			crops[key]["stage"] += 1
		crops[key]["watered"] = false
	_show_message("A new day begins. Crops watered overnight grew!")

func _show_message(text: String) -> void:
	message = text
	message_timer = 3.5

func _update_ui() -> void:
	if not is_instance_valid(hud_label):
		return
	var hour := int(time_minutes / 60) % 24
	var mins := time_minutes % 60
	var suffix := "AM" if hour < 12 else "PM"
	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12
	hud_label.text = "Day %d  |  %02d:%02d %s" % [day, display_hour, mins, suffix]
	money_label.text = "$ %d" % inventory["Coins"]
	seeds_label.text = "🌱 %d" % inventory["Seeds"]
	lemons_label.text = "🍋  %d" % inventory["Lemons"]
	for i in range(hotbar_buttons.size()):
		hotbar_buttons[i].button_pressed = (i == _selected_tool_index())
		hotbar_buttons[i].modulate = Color(1.0, 0.9, 0.65) if i == _selected_tool_index() else Color.WHITE
	var default_hint := "WASD move • E use/interact • F sleep • Near market: 2 buy seeds / 4 sell lemons"
	hint_label.text = message if message_timer > 0 else default_hint

func _draw() -> void:
	# Warm, cozy farm ground with pixel-art-like patches and paths.
	draw_rect(Rect2(0, 0, 640, 480), Color("#76b85b"))
	for y in range(0, 480, 32):
		for x in range(0, 640, 32):
			var shade := Color("#80c363") if ((x / 32 + y / 32) % 2 == 0) else Color("#72b455")
			draw_rect(Rect2(x, y, 32, 32), shade)
	# farmhouse and porch
	draw_rect(Rect2(70, 58, 145, 92), Color("#c28b58"))
	draw_rect(Rect2(64, 52, 157, 25), Color("#8e493c"))
	draw_rect(Rect2(80, 70, 125, 74), Color("#ead39b"))
	draw_rect(Rect2(92, 90, 25, 25), Color("#7bb9d0"))
	draw_rect(Rect2(166, 90, 25, 25), Color("#7bb9d0"))
	draw_rect(Rect2(132, 108, 22, 36), Color("#7a5038"))
	# path
	for i in range(0, 18):
		draw_rect(Rect2(280 + i * 16, 120, 16, 24), Color("#c5a36b"))
	for i in range(0, 16):
		draw_rect(Rect2(310, 144 + i * 16, 20, 16), Color("#c5a36b"))
	# garden bed
	draw_rect(Rect2(204, 140, 184, 142), Color("#bd8c5b"))
	draw_rect(Rect2(208, 144, 176, 134), Color("#80553b"))
	for row in FARM_ROWS:
		for col in FARM_COLS:
			var key := str(col) + "," + str(row)
			var r := Rect2(224 + col * 42 - 15, 160 + row * 42 - 15, 30, 30)
			draw_rect(r, Color("#9c704b") if tilled.has(key) else Color("#a77a4d"))
			draw_rect(Rect2(r.position + Vector2(2,2), r.size - Vector2(4,4)), Color("#6c492f") if tilled.has(key) else Color("#b88a58"))
			if crops.has(key):
				var stage: int = crops[key]["stage"]
				var c := Color("#80d25c") if stage == 0 else (Color("#55b94b") if stage == 1 else (Color("#399a39") if stage == 2 else Color("#f1d46b")))
				var center := r.position + r.size / 2
				if stage >= 3:
					# Ripe lemons: bright yellow fruit and small leaves.
					draw_circle(center + Vector2(-5, 1), 8, Color("#f5d83f"))
					draw_circle(center + Vector2(6, -4), 7, Color("#f5d83f"))
					draw_circle(center + Vector2(-7, -2), 3, Color("#ffe978"))
					draw_circle(center + Vector2(4, -6), 3, Color("#ffe978"))
					draw_line(center + Vector2(0, -8), center + Vector2(5, -13), Color("#3f7735"), 3)
				else:
					draw_circle(center + Vector2(-5, 1), 5 + stage * 2, c)
					draw_circle(center + Vector2(5, -4), 5 + stage * 2, c)
					draw_line(center + Vector2(0, 6), center + Vector2(0, 13), Color("#3f7735"), 3)
				if crops[key]["watered"]:
					draw_circle(center + Vector2(10, 11), 3, Color("#6ec9e9"))
	# fence around edges
	for x in range(16, 624, 32):
		draw_rect(Rect2(x, 16, 6, 18), Color("#a57549"))
		draw_rect(Rect2(x, 26, 18, 5), Color("#d4ad78"))
		draw_rect(Rect2(x, 454, 6, 18), Color("#a57549"))
		draw_rect(Rect2(x, 464, 18, 5), Color("#d4ad78"))
	for y in range(40, 448, 32):
		draw_rect(Rect2(16, y, 6, 18), Color("#a57549"))
		draw_rect(Rect2(26, y, 18, 5), Color("#d4ad78"))
		draw_rect(Rect2(618, y, 6, 18), Color("#a57549"))
		draw_rect(Rect2(608, y, 18, 5), Color("#d4ad78"))
	# tree clusters, decorative
	for pos in [Vector2(40,85), Vector2(565,85), Vector2(575,380), Vector2(50,390)]:
		draw_rect(Rect2(pos + Vector2(-5,12), Vector2(10,25)), Color("#81583b"))
		draw_circle(pos, 22, Color("#3e8947"))
		draw_circle(pos + Vector2(-10,-8), 15, Color("#53a751"))
		draw_circle(pos + Vector2(10,-7), 15, Color("#5eb759"))
	# market stall
	draw_rect(Rect2(450, 170, 68, 46), Color("#9b6744"))
	draw_rect(Rect2(442, 164, 82, 12), Color("#d7c07d"))
	draw_rect(Rect2(446, 153, 20, 15), Color("#c75a54"))
	draw_rect(Rect2(466, 153, 20, 15), Color("#ead8a4"))
	draw_rect(Rect2(486, 153, 20, 15), Color("#c75a54"))
	# stones and flowers
	for pos in [Vector2(370,320), Vector2(394,326), Vector2(402,310)]:
		draw_circle(pos, 8, Color("#8a9694"))
	for pos in [Vector2(180,330), Vector2(500,360), Vector2(260,350)]:
		draw_circle(pos, 3, Color("#f2df75"))
	# player highlight
	if player:
		draw_circle(player.position + Vector2(0,5), 12, Color(0,0,0,0.12))

func _build_hotbar(root: Control) -> void:
	var hotbar := HBoxContainer.new()
	hotbar.anchor_left = 1.0
	hotbar.anchor_right = 1.0
	hotbar.anchor_top = 0.0
	hotbar.anchor_bottom = 0.0
	hotbar.position = Vector2(-330, 16)
	hotbar.size = Vector2(314, 78)
	hotbar.add_theme_constant_override("separation", 8)
	root.add_child(hotbar)
	var slot_data := ["🪓\n1 Hoe", "🌱\n2 Seeds", "💧\n3 Water", "🍋\n4 Harvest"]
	for i in range(slot_data.size()):
		var button := Button.new()
		button.text = slot_data[i]
		button.custom_minimum_size = Vector2(72, 72)
		button.add_theme_font_size_override("font_size", 17)
		button.toggle_mode = true
		button.pressed.connect(_select_hotbar.bind(i))
		hotbar.add_child(button)
		hotbar_buttons.append(button)

func _build_inventory_corner(root: Control) -> void:
	# A compact, vertically stacked inventory HUD pinned to the bottom-right.
	var stack := VBoxContainer.new()
	stack.anchor_left = 1.0
	stack.anchor_right = 1.0
	stack.anchor_top = 1.0
	stack.anchor_bottom = 1.0
	stack.offset_left = -156
	stack.offset_top = -132
	stack.offset_right = -14
	stack.offset_bottom = -14
	stack.add_theme_constant_override("separation", 6)
	root.add_child(stack)
	money_label = _inventory_label("$  0")
	seeds_label = _inventory_label("🌱  0")
	lemons_label = _inventory_label("🍋  0")
	for label in [money_label, seeds_label, lemons_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.custom_minimum_size = Vector2(128, 30)
		label.add_theme_font_size_override("font_size", 19)
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(142, 34)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.13, 0.19, 0.14, 0.92)
		style.border_color = Color(0.72, 0.58, 0.35, 0.95)
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		style.set_content_margin(SIDE_LEFT, 7)
		style.set_content_margin(SIDE_RIGHT, 7)
		row_panel.add_theme_stylebox_override("panel", style)
		row_panel.add_child(label)
		stack.add_child(row_panel)

func _inventory_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _select_hotbar(index: int) -> void:
	match index:
		0: selected_tool = "Hoe"
		1: selected_tool = "Seeds"
		2: selected_tool = "Water"
		3: selected_tool = "Harvest"
	_update_ui()

func _selected_tool_index() -> int:
	match selected_tool:
		"Hoe": return 0
		"Seeds": return 1
		"Water": return 2
		"Harvest": return 3
	return 0

func _near_market() -> bool:
	return player.position.distance_to(Vector2(484, 194)) < 82

func _handle_market() -> void:
	if selected_tool == "Seeds":
		if inventory["Coins"] >= 10:
			inventory["Coins"] -= 10
			inventory["Seeds"] += 5
			_show_message("Bought 5 lemon seeds for $10.")
		else:
			_show_message("Seeds cost $10 for 5. Not enough money!")
	elif selected_tool == "Harvest":
		if inventory["Lemons"] > 0:
			var quantity: int = inventory["Lemons"]
			var earnings: int = quantity * 15
			inventory["Lemons"] = 0
			inventory["Coins"] += earnings
			_show_message("Sold %d lemons for $%d!" % [quantity, earnings])
		else:
			_show_message("No lemons to sell. Harvest ripe lemon crops first.")
	else:
		_show_message("Market: 2 buys seeds ($10 for 5), 4 sells lemons ($15 each).")
