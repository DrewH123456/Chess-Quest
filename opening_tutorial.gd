extends Control

@onready var puzzle_mode = preload("res://puzzle_mode.tscn")
@onready var slot_scene = preload("res://slot.tscn")
@onready var board_grid = $ChessBoard/BoardGrid
@onready var chess_board = $ChessBoard
var main_menu = "res://main.tscn"

var grid_array = []
var piece_selected = null

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
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse_right") and piece_selected:
		piece_selected = null
		clear_board_filter()

# Upon creation of slot, assigned slot_ID, added to board_grid, and inserted into grid_array
func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	board_grid.add_child(new_slot)
	grid_array.push_back(new_slot)

# Upon being clicked, sends user to main menu
func _on_button_pressed():
	get_tree().change_scene_to_file(main_menu)

