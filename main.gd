extends Control

@onready var slot_scene = preload("res://slot.tscn")
@onready var board_grid = $ChessBoard/BoardGrid
@onready var chess_board = $ChessBoard
@onready var puzzle_button = $Button as Button
@onready var quit_button = $Quit_Button as Button
#@onready var puzzle_mode = preload("res://gui.tscn") as PackedScene
var puzzle_mode = "res://gui.tscn"
var grid_array = []

func _ready():
	for i in range(64):
		# Upon creation of slot, assigned slot_ID, added to board_grid, and inserted into grid_array
		create_slot()
	
	# Alternates colors within row, alternates pattern every column
	var colorbit = 0
	for i in range(8):
		for j in range(8):
			if j % 2 == colorbit:
				grid_array[i * 8 + j].set_background(Color.BISQUE)
		if colorbit == 0:
			colorbit = 1
		else: colorbit = 0
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Upon creation of slot, assigned slot_ID, added to bo	ard_grid, and inserted into grid_array
func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	board_grid.add_child(new_slot)
	grid_array.push_back(new_slot)

func _on_button_pressed():
	print("Hello")
	#var puzzle_instance = puzzle_mode.instance()
	get_tree().change_scene_to_file(puzzle_mode)
	#print("Hello")
	#hide()
	
func _on_quit_button_pressed():
	get_tree().quit()	
