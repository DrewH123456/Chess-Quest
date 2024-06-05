extends Control

@onready var slot_scene = preload("res://slot.tscn")
@onready var board_grid = $ChessBoard/BoardGrid
@onready var piece_scene = preload("res://piece.tscn")
@onready var chess_board = $ChessBoard
@onready var bitboard = $BitBoard
@onready var GeneratePath = $GeneratePath
@onready var PuzzleTextEdit = $PuzzleTextEdit
@export var dropdown_path: NodePath
@onready var dropdown = get_node(dropdown_path)
var main_menu = "res://main.tscn"

var grid_array := [] # Contains all 64 slots(This is how you interact with slots)
var piece_array := [] # Represents piece assigned to each of the 64 slots. 0 if empty
var icon_offset := Vector2(39, 39) # Centers chess pieces within slot
# var fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" # Represents starting chess position
var fen = "8/8/k4r1R/8/8/5n2/n7/8"
var puzzle_fen = "r3n1k1/pb5q/1p2N2p/P2pP2r/4nQ2/1PbRRN1P/5PBK/8 w - - 3 30"
var piece_selected = null
var puzzle_mode : bool = false
var isWhite : bool = true
var current_puzzle = null
var puzzle_move_count = 0
var total_puzzle_moves = 0
var lock_movement : bool = false
var piece_to_unmove = null
var prev_slot = null
var allow_retry : bool = false
var removed_piece_slot = null
var removed_piece_type = null
var second_hint : bool = false
var puzzle_set = null

# Spawns slots
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
		
	piece_array.resize(64)
	piece_array.fill(0)
	load_puzzles_from_file("res://singlemove_puzzles2.txt", DataHandler.single_move_puzzles)
	load_puzzles_from_file("res://multimove_puzzles2.txt", DataHandler.multi_move_puzzles)
	add_items()

func add_items():
	dropdown.add_item("Puzzle 1")
	dropdown.add_item("Puzzle 2")
	dropdown.add_item("Puzzle 3")
	dropdown.add_item("Puzzle 4")
	dropdown.add_item("Puzzle 5")
	dropdown.add_item("Puzzle 1")
	dropdown.add_item("Puzzle 2")
	dropdown.add_item("Puzzle 3")
	dropdown.add_item("Puzzle 4")
	dropdown.add_item("Puzzle 5")
	dropdown.add_item("Puzzle 1")
	dropdown.add_item("Puzzle 2")
	dropdown.add_item("Puzzle 3")
	dropdown.add_item("Puzzle 4")
	dropdown.add_item("Puzzle 5")
	dropdown.add_item("Puzzle 1")
	dropdown.add_item("Puzzle 2")
	dropdown.add_item("Puzzle 3")
	dropdown.add_item("Puzzle 4")
	dropdown.add_item("Puzzle 5")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse_right") and piece_selected:
		piece_selected = null
		clear_board_filter()

func current_board_to_fen(pieces: Array) -> String:
	var blank_slots = 0
	var fen_string = ""
	for i in range(64): 
		if (i % 8 == 0  && 	i != 0):
			if (blank_slots != 0):
				fen_string += str(blank_slots)
			blank_slots = 0
			fen_string += "/"
		if !pieces[i]:
			blank_slots += 1
		else:
			if (blank_slots != 0):
				fen_string += str(blank_slots)
			blank_slots = 0
			fen_string += DataHandler.reverse_fen_dict[pieces[i].type]
	if blank_slots != 0:
			fen_string += str(blank_slots)
	return fen_string

# Load DataHandler arrays with puzzle data from given txt file
func load_puzzles_from_file(file_path: String, datahandler_array: Array) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file.file_exists(file_path):
		while !file.eof_reached():
			var line = file.get_line().strip_edges()
			if line.is_empty():
				continue
			var parsed_puzzle = line.split(";", true, 2)
			var appended_array = []
			appended_array.append(parse_fen_array(parsed_puzzle[0]))
			appended_array.append(int(parsed_puzzle[1]))
			appended_array.append(string_to_bool(parsed_puzzle[2]))
			datahandler_array.append(appended_array)
	else:
		file.close()
		assert(false, "Failed to load file")
	file.close()

# Turn string into fen string array
func parse_fen_array(str_array: String) -> Array:
	# Remove brackets and split the string into individual numbers
	var fen_array = str_array.substr(1, str_array.length() - 2).split(",")
	for i in range(fen_array.size()):
		fen_array[i] = fen_array[i].strip_edges()
	# Return the array of FEN strings
	return fen_array

# Interpret "White" as true and "Black" as false for is_white bool
func string_to_bool(is_white: String) -> bool:
	is_white = is_white.dedent()
	if (is_white.to_lower() == "white"):
		return true
	elif (is_white.to_lower() == "black"):
		return false
	else:
		assert(false, "Error loading text file, is_white must be either 'White' or 'Black'")
		return false

# Upon creation of slot, assigned slot_ID, added to bo	ard_grid, and inserted into grid_array
func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	board_grid.add_child(new_slot)
	grid_array.push_back(new_slot)
	new_slot.slot_clicked.connect(_on_slot_clicked) # Assigns slot a signal, activated when it is clicked

# Handles when a slot is clicked on the GUI
func _on_slot_clicked(slot) -> void:
	# Do nothing if slot clicked without having a piece selected
	if not piece_selected:
		return
	if slot.state != DataHandler.slot_states.FREE: 
		return
	# Otherwise, move selected piece to given slot
	prev_slot = piece_selected.slot_ID
	move_piece(piece_selected, slot.slot_ID)
	if puzzle_mode:
		puzzle_move(slot)
	isWhite = !isWhite
	clear_board_filter()
	piece_selected = null

# Checks if piece selected is correct and moved to proper square
func puzzle_move(slot) -> void:
	second_hint = false
	# if current board matches correct puzzle move
	if (current_board_to_fen(piece_array) == current_puzzle[0][puzzle_move_count+1]):
		print("Nice work")
		PuzzleTextEdit.call("add_text", "Nice work")
	else: 
		print("Try again")
		PuzzleTextEdit.call("add_text", "Try again")
		#SAVE THE SLOT AND PIECE_SELECTED SO PREV CAN
		piece_to_unmove = piece_selected
		lock_movement = true
		allow_retry = true
		return # insert retry logic
	puzzle_move_count += 1
	if (puzzle_move_count == total_puzzle_moves):
		puzzle_end() 
		return
	lock_movement = true
	await get_tree().create_timer(.5).timeout
	lock_movement = false # should this go after move_piece?
	make_enemy_move()
	isWhite = !isWhite
	
func make_enemy_move() -> void:
	var next_board = fen_to_piece_array(current_puzzle[0][puzzle_move_count + 1]) #piece_array but for next move's fen 
	#for i in piece_array:
		#print(i)
		#if !typeof(i) == TYPE_INT: 
			#print(i.type)
	#print("+++++++++")
	#for i in next_board:
		#print(i)
		#if !typeof(i) == TYPE_INT: 
			#print(i.type)	
	var next_enemy_move = null
	var destination_slot = null
	var slots_array = differentiate_fen(piece_array, next_board) #contains two slots that contain different pieces
	var slot_1 = slots_array[0]
	var slot_2 = slots_array[1]
	if typeof(piece_array[slot_1]) == TYPE_INT: # if slot_1 does not contain a piece, piece to move is in slot_2
		next_enemy_move = piece_array[slot_2]
		destination_slot = slot_1
	elif ((piece_array[slot_1].type < 6 && isWhite) || (piece_array[slot_1].type > 6 && !isWhite)): #if slot_1 contains piece to move
		next_enemy_move = piece_array[slot_1]
		destination_slot = slot_2
	else:
		next_enemy_move = piece_array[slot_2] #if slot_2 contains piece to move
		destination_slot = slot_1
	move_piece(next_enemy_move, destination_slot)
	puzzle_move_count += 1

func differentiate_fen(current_board: Array, next_board: Array) -> Array:
	var slots = []
	for i in range(64):
		if !typeof(current_board[i]) == TYPE_INT && !typeof(next_board[i]) == TYPE_INT:
			if current_board[i].type != next_board[i].type: # if both occupied, but changed types
				slots.append(i)
		else: # if empty slot vs. occupied
			if !typeof(current_board[i]) == TYPE_INT || !typeof(next_board[i]) == TYPE_INT:
				slots.append(i)
	if slots.size() != 2:
		#for i in slots:
			#print(i)
		assert(false, "Error identifying 2 different slots when comparing fen strings")
	return slots
		
func fen_to_piece_array(desired_state: String) -> Array:
	var board_index := 0
	var temp_piece_array = []
	temp_piece_array.resize(64)
	temp_piece_array.fill(0)
	for i in desired_state:
		if i == "/": continue
		if i.is_valid_int():
			board_index += i.to_int()
		else:
			var new_piece = piece_scene.instantiate()
			new_piece.type = DataHandler.fen_dict[i]
			temp_piece_array[board_index] = new_piece
			new_piece.slot_ID = board_index
			board_index += 1
	return temp_piece_array		
		
func puzzle_end():
	lock_movement = true
	puzzle_mode = false
	allow_retry = false
	print("Puzzle solved!")
	PuzzleTextEdit.call("add_text", "Puzzle solved!")

# Move selected piece to given destination
func move_piece(piece, destination) -> void:
	if piece_array[destination]: # Checks if there is a piece existing on destination, if so, remove it from the board
		var piece_to_remove = piece_array[destination]
		if puzzle_mode:
			removed_piece_type = piece_to_remove.type
			removed_piece_slot = piece_to_remove.slot_ID
		remove_from_bitboard(piece_to_remove)
		piece_to_remove.queue_free()
		piece_to_remove = 0
	else:
		removed_piece_type = null
		removed_piece_slot = null
	
	remove_from_bitboard(piece)
	# Smoothly move piece from original position to destination
	var tween = get_tree().create_tween()
	tween.tween_property(piece, "global_position", grid_array[destination].global_position + icon_offset, 0.25)
	# Empty out previous position, insert piece into piece_array for destination
	piece_array[piece.slot_ID] = 0
	piece_array[destination] = piece
	piece.slot_ID = destination
	bitboard.call("AddPiece", 63 - destination, piece.type)
	
func remove_from_bitboard(piece):
	bitboard.call("RemovePiece", 63 - piece.slot_ID, piece.type)
	
# New piece added to chess board and piece_array. Piece type, slot ID and global position assigned. Texture loaded 
func add_piece(piece_type, location) -> void:
	var new_piece = piece_scene.instantiate()
	chess_board.add_child(new_piece)
	new_piece.type = piece_type
	new_piece.load_icon(piece_type)
	new_piece.global_position = grid_array[location].global_position + icon_offset
	piece_array[location] = new_piece
	new_piece.slot_ID = location
	new_piece.piece_selected.connect(_on_piece_selected)

# Handles when piece is selected on GUI
func _on_piece_selected(piece):
	if lock_movement:
		return
	if piece_selected:
		_on_slot_clicked(grid_array[piece.slot_ID])
	else:
		if isWhite != (piece.type < 6):
			return
		piece_selected = piece
		var WhiteBoard = bitboard.call("GetWhiteBitboard")
		var BlackBoard = bitboard.call("GetBlackBitboard")
		#check for color
		var isBlack := true
		var function_to_call : String
		if piece.type<6: isBlack = false 
		#match piece type
		match piece.type%6:
			0:
				function_to_call = "BishopPath"
			1:
				function_to_call = "KingPath"
			2:
				function_to_call = "KnightPath"
			3:
				function_to_call = "PawnPath"
			4:
				function_to_call = "QueenPath"
			5:
				function_to_call = "RookPath"
		if isBlack:
			set_board_filter(GeneratePath.call(function_to_call,63 - piece.slot_ID, BlackBoard, WhiteBoard, isBlack))
		else:
			set_board_filter(GeneratePath.call(function_to_call,63 - piece.slot_ID, WhiteBoard, BlackBoard, isBlack))

# sets up board filter using bitmap
func set_board_filter(bitmap: int):
	for i in range(64):
		if bitmap&1:
			grid_array[63 - i].set_filter(DataHandler.slot_states.FREE) # https://youtu.be/JOQkz-9yu7w?t=635 might not need to have 63 - i
		bitmap = bitmap >> 1
		
func clear_board_filter():
	for i in grid_array:
		i.set_filter()
		
# takes fen string, ignores /'s, ints are slot skips, and letters represent pieces
# if it takes in a letter, adds piece to board based on type and location	
func parse_fen(fen: String) -> void:
	var boardstate = fen.split(" ")
	var board_index := 0
	for i in boardstate[0]:
		if i == "/": continue
		if i.is_valid_int():
			board_index += i.to_int()
		else:
			add_piece(DataHandler.fen_dict[i], board_index)
			board_index += 1
	
func randomly_select_puzzle(puzzles: Array) -> Array :
	var random_index := randi_range(0, puzzles.size() - 1)
	var random_puzzle : Array = puzzles[random_index]
	return random_puzzle
	
func clear_board():
	PuzzleTextEdit.call("add_text", "")
	lock_movement = false
	puzzle_mode = false
	removed_piece_slot = null
	removed_piece_type = null
	piece_to_unmove = null
	prev_slot = null
	allow_retry = false
	second_hint = false
	puzzle_move_count = 0
	clear_board_filter()
	bitboard.ClearBitboard()
	for i in range(64):
		if piece_array[i]:
			piece_array[i].queue_free()
			piece_array[i] = 0

func init_puzzle(current_puzzle: Array):
	parse_fen(current_puzzle[0][0])
	bitboard.call("InitBitBoard", current_puzzle[0][0])
	total_puzzle_moves = current_puzzle[1]
	isWhite = current_puzzle[2]
	puzzle_mode = true

func _on_test_clear_pressed():
	current_puzzle = null
	clear_board()

func _on_provide_hint_pressed():
	if !puzzle_mode:
		print("Not in puzzle mode")
		PuzzleTextEdit.call("add_text", "Not in puzzle mode")
		return
	if second_hint:
		print("h")
		PuzzleTextEdit.call("add_text", "h")
	else:
		if allow_retry:
			_on_previous_pressed()
			await get_tree().create_timer(0.25).timeout
		var hint_piece = null
		var current_board = fen_to_piece_array(current_puzzle[0][puzzle_move_count])
		var next_board = fen_to_piece_array(current_puzzle[0][puzzle_move_count + 1])
		var slots = differentiate_fen(current_board, next_board)
		var slot_1 = slots[0]
		var slot_2 = slots[1]
		if typeof(piece_array[slot_1]) == TYPE_INT: # if slot_1 does not contain a piece, piece to move is in slot_2
			hint_piece = piece_array[slot_2]
		elif ((piece_array[slot_1].type < 6 && isWhite) || (piece_array[slot_1].type > 6 && !isWhite)): #if slot_1 contains piece to move
			hint_piece = piece_array[slot_1]
		else:
			hint_piece = piece_array[slot_2] #if slot_2 contains piece to move
		grid_array[hint_piece.slot_ID].set_filter(DataHandler.slot_states.HINT)
		second_hint = true	

func _on_restart_pressed():
	if current_puzzle:
		clear_board()
		parse_fen(current_puzzle[0][0])
		bitboard.call("InitBitBoard", current_puzzle[0][0])
		total_puzzle_moves = current_puzzle[1]	
		isWhite = current_puzzle[2]
		puzzle_mode = true
	else:
		print("Not in puzzle mode")
		PuzzleTextEdit.call("add_text", "Not in puzzle mode")

func _on_previous_pressed():
	#var add_piece = removed_piece_slot
	PuzzleTextEdit.call("add_text", "")
	var temp_removed_piece_type = removed_piece_type
	var temp_removed_piece_slot = removed_piece_slot
	if !allow_retry:
		print("Can't retry")
		PuzzleTextEdit.call("add_text", "Can't retry")
		return
	move_piece(piece_to_unmove, prev_slot)
	if temp_removed_piece_slot:
		add_piece(temp_removed_piece_type, temp_removed_piece_slot)
		bitboard.call("AddPiece", 63 - temp_removed_piece_slot, temp_removed_piece_type)
	isWhite = !isWhite
	lock_movement = false
	allow_retry = false
	temp_removed_piece_type = null
	temp_removed_piece_slot = null
	removed_piece_slot = null
	removed_piece_type = null

func _on_puzzle_1_pressed():
	clear_board()
	current_puzzle = puzzle_set[0]
	init_puzzle(puzzle_set[0])

func _on_puzzle_2_pressed():
	clear_board()
	current_puzzle = puzzle_set[1]
	init_puzzle(puzzle_set[1])

func _on_puzzle_3_pressed():
	clear_board()
	current_puzzle = puzzle_set[2]
	init_puzzle(puzzle_set[2])

func _on_puzzle_4_pressed():
	clear_board()
	current_puzzle = puzzle_set[3]
	init_puzzle(puzzle_set[3])

func _on_puzzle_5_pressed():
	clear_board()
	current_puzzle = puzzle_set[4]
	init_puzzle(puzzle_set[4])

func _on_main_menu_pressed():
	#get_tree().get_root().get_node(main_menu).queue_free()
	get_tree().change_scene_to_file(main_menu)
	#get_tree().reload_current_scene() 


func _on_single_puzzle_pressed():
	puzzle_set = DataHandler.single_move_puzzles


func _on_multi_puzzle_pressed():
	puzzle_set = DataHandler.multi_move_puzzles


func _on_help_pressed():
	PuzzleTextEdit.call("add_text", "Help")
