extends TileMap

const ALIVE = 0
const DEAD = -1
onready var on_off = get_parent().get_node("CanvasLayer/UI/TopPanel/Buttons/OnOff")

var undo_stack = []
var ctrl_down = false
var simulate = false

func _ready():
	update_on_off()

func _process(delta):
	if Input.is_action_pressed("mouse_left"):
		var mouse_pos = get_global_mouse_position()
		var cell_pos = world_to_map(mouse_pos)
		set_alive(cell_pos)
	elif Input.is_action_pressed("mouse_right"):
		var mouse_pos = get_global_mouse_position()
		var cell_pos = world_to_map(mouse_pos)
		set_dead(cell_pos)
	
	if simulate: next_generation()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_CONTROL:
			ctrl_down = event.pressed
		elif event.pressed and event.scancode == KEY_Z and ctrl_down:
			undo_action()

func undo_action():
	if undo_stack.size() > 0:
		var action = undo_stack.pop_back()
		match action["action"]:
			"set_alive": set_cell(action["cell_pos"].x, action["cell_pos"].y, DEAD)
			"set_dead": set_cell(action["cell_pos"].x, action["cell_pos"].y, ALIVE)

func set_alive(pos):
	if get_cell(pos.x, pos.y) == DEAD:
		set_cell(pos.x, pos.y, ALIVE)
		undo_stack.append({"action": "set_alive", "cell_pos": pos})

func set_dead(pos):
	if get_cell(pos.x, pos.y) == ALIVE:
		set_cell(pos.x, pos.y, DEAD)
		undo_stack.append({"action": "set_dead", "cell_pos": pos})

func get_bounds() -> Dictionary:
	var used_cells = get_used_cells()
	var min_x: int
	var max_x: int
	var min_y: int
	var max_y: int
	for cell_pos in used_cells:
		if cell_pos.x < min_x: min_x = cell_pos.x
		elif cell_pos.x > max_x: max_x = cell_pos.x
		if cell_pos.y < min_y: min_y = cell_pos.y
		elif cell_pos.y > max_y: max_y = cell_pos.y
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}
	
func next_generation():
	var changed_cells = []
	
	var bounds = get_bounds()
	for x in range(bounds["min_x"]-1, bounds["max_x"]+2):
		for y in range(bounds["min_y"]-1, bounds["max_y"]+2):
			var cell = get_cell(x, y)
			
			var alive_neighbours = 0
			for x_off in [-1, 0, 1]:
				for y_off in [-1, 0, 1]:
					if x_off != y_off or x_off != 0:
						if get_cell(x + x_off, y + y_off) == ALIVE:
							alive_neighbours += 1
			
			if cell == ALIVE:
				if alive_neighbours < 2 or alive_neighbours > 3:
					changed_cells.append({"pos_x": x, "pos_y": y, "new_value": DEAD})
			elif cell == DEAD:
				if alive_neighbours == 3:
					changed_cells.append({"pos_x": x, "pos_y": y, "new_value": ALIVE})
					
	for changed_cell in changed_cells:
		set_cell(changed_cell["pos_x"], changed_cell["pos_y"], changed_cell["new_value"])

func clear():
	var bounds = get_bounds()
	for x in range(bounds["min_x"]-1, bounds["max_x"]+2):
		for y in range(bounds["min_y"]-1, bounds["max_y"]+2):
			set_cell(x, y, DEAD)
	
func _on_ButtonSim_pressed():
	simulate = !simulate
	update_on_off()

func _on_ButtonStep_pressed():
	next_generation()
	
func _on_ButtonClear_pressed():
	clear()
	simulate = false
	update_on_off()

func update_on_off():
	match simulate:
		true: on_off.get_node("Sprite").texture = preload("res://Assets/Green-Circle.png")
		false: on_off.get_node("Sprite").texture = preload("res://Assets/Red-Circle.png")
