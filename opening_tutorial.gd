extends Control

@onready var slot_scene = preload("res://slot.tscn")
@onready var board_grid = $ChessBoard/BoardGrid
@onready var piece_scene = preload("res://piece.tscn")
@onready var chess_board = $ChessBoard
@onready var bitboard = $BitBoard
@onready var GeneratePath = $GeneratePath
@onready var OpeningTextEdit = $OpeningTextEdit
@onready var variation_scene = preload("res://variation.tscn")
var main_menu = "res://main.tscn"

var grid_array = []
var piece_array := []
var icon_offset := Vector2(39, 39) # Centers chess pieces within slot
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
var taken_slot_array = []
var taken_type_array = []
var prev_piece_array = []
var prev_slot_array = []
var tutorial_mode : bool = false
var prev_move_made : bool = false
var took_piece_bool = []
var variations = []
var current_variation = null
var variations_mode : bool = false

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
	load_puzzles_from_file("res://queens_gambit_opening.txt", DataHandler.queens_gambit_boardstates)
	load_variations("variations.json")
	for i in variations:
		i.display_details()
	
	#load_puzzles_from_file("res://multimove_puzzles2.txt", DataHandler.multi_move_puzzles)
	pass # Replace with function body.

# Function to load variations from a file
func load_variations(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_as_text = file.get_as_text()
	file.close()
	var json_as_dict = JSON.parse_string(json_as_text)
	if json_as_dict:
		print(json_as_dict)
	else:
		print("Error parsing JSON: ")
		return
	if not json_as_dict.has("variations"):
		print("JSON does not contain 'variations' key")
		return
	
	var variations_data = json_as_dict
	var variations_array = variations_data["variations"]
#
	# Create variations
	for variation_data in variations_array:
		var variation = variation_scene.instantiate()
		variation.initialize(variation_data["fen"])
		variations.append(variation)
#
	# Link variations
	for i in range(variations.size()):
		var variation_data = variations_array[i]
		var variation = variations[i]
#
		if "previous" in variation_data:
			if variation_data["previous"] != null:
				variation.set_previous(variations[variation_data["previous"]])
#
		if "next" in variation_data:
			for next_index in variation_data["next"]:
				variation.add_next(variations[next_index])

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
		OpeningTextEdit.call("add_text", "Nice work")
	else: 
		print("Try again")
		OpeningTextEdit.call("add_text", "Try again")
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
	#print("Puzzle Move Count: ", puzzle_move_count)
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
	# save destination_slot and next_enemy_move in array
	if tutorial_mode:
		#print("Last move made:")
		#print("Reverting from: ", destination_slot)
		#print("Reverting to: ", next_enemy_move.slot_ID)
		prev_piece_array.append(destination_slot)
		prev_slot_array.append(next_enemy_move.slot_ID)
		if typeof(piece_array[slot_1]) == TYPE_INT || typeof(piece_array[slot_2]) == TYPE_INT:
			took_piece_bool.append(false)
		else:
			took_piece_bool.append(true)
	move_piece(next_enemy_move, destination_slot)
	puzzle_move_count += 1

func make_tutorial_move(next_fen: String) -> void:
	print("Puzzle Move Count: ", puzzle_move_count)
	var next_board = fen_to_piece_array(next_fen) #piece_array but for next move's fen 
	var next_enemy_move = null
	var destination_slot = null
	var slots_array = differentiate_fen(piece_array, next_board) #contains two slots that contain different pieces
	var slot_1 = slots_array[0]
	var slot_2 = slots_array[1]
	var string = ""
	if typeof(piece_array[slot_1]) == TYPE_INT: # if slot_1 does not contain a piece, piece to move is in slot_2
		next_enemy_move = piece_array[slot_2]
		destination_slot = slot_1
		string = "1"
	elif ((piece_array[slot_1].type < 6 && isWhite) || (piece_array[slot_1].type > 6 && !isWhite)): #if slot_1 contains piece to move
		next_enemy_move = piece_array[slot_1]
		destination_slot = slot_2
		string = "2"
	else:
		next_enemy_move = piece_array[slot_2] #if slot_2 contains piece to move
		destination_slot = slot_1
		string = "3"
	# save destination_slot and next_enemy_move in array
	if tutorial_mode:
		prev_piece_array.append(destination_slot)
		prev_slot_array.append(next_enemy_move.slot_ID)
		if typeof(piece_array[slot_1]) == TYPE_INT || typeof(piece_array[slot_2]) == TYPE_INT:
			took_piece_bool.append(false)
		else:
			took_piece_bool.append(true)
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
	OpeningTextEdit.call("add_text", "Puzzle solved!")

# Move selected piece to given destination
func move_piece(piece, destination) -> void:
	if piece_array[destination]: # Checks if there is a piece existing on destination, if so, remove it from the board
		var piece_to_remove = piece_array[destination]
		if tutorial_mode && !prev_move_made:
			#print("piece type removing: ", piece_to_remove.type)
			#print("piece removed location: ", piece_to_remove.slot_ID)
			taken_type_array.append(piece_to_remove.type)
			taken_slot_array.append(piece_to_remove.slot_ID)
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
	OpeningTextEdit.call("add_text", "")
	lock_movement = false
	puzzle_mode = false
	tutorial_mode = false
	removed_piece_slot = null
	removed_piece_type = null
	piece_to_unmove = null
	prev_slot = null
	allow_retry = false
	puzzle_move_count = 0
	clear_board_filter()
	bitboard.ClearBitboard()
	for i in range(64):
		if piece_array[i]:
			piece_array[i].queue_free()
			piece_array[i] = 0

func _on_test_button_pressed():
	var curr_boardstate = current_board_to_fen(piece_array)
	clear_board()
	#init_puzzle(test_puzzle)
	parse_fen(curr_boardstate)
	bitboard.call("InitBitBoard", curr_boardstate)
	print(curr_boardstate)
	OpeningTextEdit.call("add_text", curr_boardstate)

func init_puzzle(current_puzzle: Array):
	parse_fen(current_puzzle[0][0])
	bitboard.call("InitBitBoard", current_puzzle[0][0])
	total_puzzle_moves = current_puzzle[1]
	isWhite = current_puzzle[2]
	puzzle_mode = true

# Upon being clicked, sends user to main menu
func _on_main_pressed():
	get_tree().change_scene_to_file(main_menu)

func _on_queens_gambit_tutorial_pressed():
	clear_board()
	variations_mode = false
	tutorial_mode = true
	current_puzzle = DataHandler.queens_gambit_boardstates[0]
	parse_fen(current_puzzle[0][0])
	bitboard.call("InitBitBoard", current_puzzle[0][0])
	total_puzzle_moves = current_puzzle[1]
	isWhite = current_puzzle[2]
	lock_movement = true

func _on_prev_pressed():
	#var add_piece = removed_piece_slot
	OpeningTextEdit.call("add_text", "")
	var temp_removed_piece_type = removed_piece_type
	var temp_removed_piece_slot = removed_piece_slot
	if !allow_retry:
		print("Can't retry")
		OpeningTextEdit.call("add_text", "Can't retry")
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

func _on_next_pressed():
	if puzzle_move_count >= total_puzzle_moves:
		print("No more next moves")
		return
	print("Next:")
	make_enemy_move()
	#for i in took_piece_bool:
		#print(i)
	print("Puzzle Move Count: ", puzzle_move_count)
	isWhite = !isWhite

func _on_previous_pressed():
	if variations_mode:
		variations_previous()
		return
	if puzzle_move_count <= 0:
		print("No more previous moves")
		return
	print("Prev:")
	prev_move_made = true
	var move_slot = null
	var piece_to_move = null
	var prev_taken_slot = null
	var prev_taken_type = null
	piece_to_move = prev_piece_array.pop_back()
	move_slot = prev_slot_array.pop_back()
	move_piece(piece_array[piece_to_move], move_slot)
	print("Before: Taken array size: ", taken_slot_array.size(), ", ", "Move count: ", puzzle_move_count)
	if (took_piece_bool.pop_back()):
		prev_taken_slot = taken_slot_array.pop_back()
		prev_taken_type = taken_type_array.pop_back()
		#print("Previous taken type: ", prev_taken_type)
		#print("Previous taken slot: ", prev_taken_slot)
		add_piece(prev_taken_type, prev_taken_slot)
		bitboard.call("AddPiece", 63 - prev_taken_slot, prev_taken_type)
	puzzle_move_count -= 1
	prev_move_made = false
	isWhite = !isWhite
	print("After: Taken array size: ", taken_slot_array.size(), ", ", "Move count: ", puzzle_move_count)
	
func variations_previous():
	if current_variation.get_previous() != null:
		current_variation = current_variation.get_previous()
		make_tutorial_move(current_variation.fen)
	else:
		print("No more prev")
	
func _on_variation_1_pressed():
	if current_variation.next_variations.size() > 0:
		current_variation = current_variation.next_variations[0]
		make_tutorial_move(current_variation.fen)
		isWhite = !isWhite
	else:
		print("No more next")


func _on_variation_2_pressed():
	if current_variation.next_variations.size() > 1:
		current_variation = current_variation.next_variations[1]
		make_tutorial_move(current_variation.fen)
		isWhite = !isWhite
	else:
		print("No more next")


func _on_variation_3_pressed():
	if current_variation.next_variations.size() > 2:
		current_variation = current_variation.next_variations[2]
		make_tutorial_move(current_variation.fen)
		isWhite = !isWhite
	else:
		print("No more next")


func _on_slav_pressed():
	variations_mode = true
	clear_board()
	current_variation = variations[0]
	parse_fen(current_variation.fen)
	bitboard.call("InitBitBoard", current_variation.fen)


func _on_declined_pressed():
	variations_mode = true
	clear_board()
	current_variation = variations[6]
	parse_fen(current_variation.fen)
	bitboard.call("InitBitBoard", current_variation.fen)


func _on_accepted_pressed():
	variations_mode = true
	clear_board()
	current_variation = variations[5]
	parse_fen(current_variation.fen)
	bitboard.call("InitBitBoard", current_variation.fen)
