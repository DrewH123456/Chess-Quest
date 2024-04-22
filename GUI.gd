extends Control

@onready var slot_scene = preload ("res://slot.tscn")
@onready var board_grid = $ChessBoard/BoardGrid
@onready var piece_scene = preload ("res://piece.tscn")
@onready var chess_board = $ChessBoard
@onready var bitboard = $BitBoard
@onready var GeneratePath = $GeneratePath

var grid_array := [] # Contains all 64 slots(This is how you interact with slots)
var piece_array := [] # Represents piece assigned to each of the 64 slots. 0 if empty
var icon_offset := Vector2(39, 39) # Centers chess pieces within slot
# var fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" # Represents starting chess position
var fen = "8/8/k4r1R/8/8/5n2/n7/8"
var puzzle_fen = "r3n1k1/pb5q/1p2N2p/P2pP2r/4nQ2/1PbRRN1P/5PBK/8 w - - 3 30"
var piece_selected = null
var piece_to_move = null
var puzzle_destination = null
var puzzle_mode : bool = false
var isWhite : bool = true
var current_puzzle = null
var puzzle_move_count = 0
var total_puzzle_moves = 0
var enemy_piece = null
var enemy_destination = null
var lock_movement : bool = false
var piece_to_unmove = null
var unmove_slot = null
var allow_retry : bool = false
var removed_piece_slot = null
var removed_piece_type = null
var second_hint : bool = false
var puzzle_set = null
var test_puzzle = ["4r3/1pp2rbk/6pn/4n3/P3BN1q/1PB2bPP/8/2Q1RRK1 b - - 0 31", [39, 46], [46, 54], [37], [54], 2, false]

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
	new_slot.slot_clicked.connect(_on_slot_clicked) # Assigns slot a signal, activated when it is clicked

# Handles when a slot is clicked on the GUI
func _on_slot_clicked(slot) -> void:
	# Do nothing if slot clicked without having a piece selected
	if not piece_selected:
		return
	if slot.state != DataHandler.slot_states.FREE: 
		return
	# Otherwise, move selected piece to given slot
	var prev_slot = piece_selected.slot_ID
	move_piece(piece_selected, slot.slot_ID)
	if puzzle_mode:
		puzzle_move(slot, prev_slot)
	isWhite = !isWhite
	clear_board_filter()
	piece_selected = null

# Checks if piece selected is correct and moved to proper square
func puzzle_move(slot, prev_slot) -> void:
	second_hint = false
	if (piece_selected == piece_to_move) && (slot == puzzle_destination):
		print("Nice work")
	else: 
		print("Try again")
		#SAVE THE SLOT AND PIECE_SELECTED SO PREV CAN
		piece_to_unmove = piece_selected
		unmove_slot = prev_slot
		lock_movement = true
		allow_retry = true
		return # insert retry logic
	puzzle_move_count += 1
	if (puzzle_move_count == total_puzzle_moves):
		puzzle_end() 
		return
	piece_selected = piece_array[current_puzzle[1][puzzle_move_count]]
	puzzle_destination = grid_array[current_puzzle[2][puzzle_move_count]]
	enemy_piece = piece_array[current_puzzle[3][puzzle_move_count-1]]
	enemy_destination = current_puzzle[4][puzzle_move_count-1]
	lock_movement = true
	await get_tree().create_timer(.5).timeout
	lock_movement = false
	move_piece(enemy_piece, enemy_destination)
	isWhite = !isWhite
		
func puzzle_end():
	lock_movement = true
	puzzle_mode = false
	allow_retry = false
	print("Puzzle solved!")

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
	lock_movement = false
	puzzle_mode = false
	removed_piece_slot = null
	removed_piece_type = null
	piece_to_unmove = null
	unmove_slot = null
	allow_retry = false
	puzzle_move_count = 0
	clear_board_filter()
	bitboard.ClearBitboard()
	for i in range(64):
		if piece_array[i]:
			piece_array[i].queue_free()
			piece_array[i] = null

func _on_test_button_pressed():
	clear_board()
	init_puzzle(test_puzzle)

func _on_test_puzzle_pressed():
	puzzle_set = DataHandler.single_move_puzzles

func _on_test_multi_puzzle_pressed():
	puzzle_set = DataHandler.multi_move_puzzles

func init_puzzle(current_puzzle: Array):
	parse_fen(current_puzzle[0])
	bitboard.call("InitBitBoard", current_puzzle[0])
	piece_to_move = piece_array[current_puzzle[1][0]]
	puzzle_destination = grid_array[current_puzzle[2][0]]
	total_puzzle_moves = current_puzzle[5]	
	isWhite = current_puzzle[6]
	puzzle_mode = true

func _on_test_clear_pressed():
	current_puzzle = null
	clear_board()

func _on_provide_hint_pressed():
	if !puzzle_mode:
		print("Not in puzzle mode")
		return
	if second_hint:
		print("h")
	else:
		if allow_retry:
			_on_previous_pressed()
			await get_tree().create_timer(0.25).timeout
		grid_array[piece_to_move.slot_ID].set_filter(DataHandler.slot_states.HINT)
		second_hint = true
	

func _on_restart_pressed():
	if current_puzzle:
		clear_board()
		parse_fen(current_puzzle[0])
		bitboard.call("InitBitBoard", current_puzzle[0])
		piece_to_move = piece_array[current_puzzle[1][0]]
		puzzle_destination = grid_array[current_puzzle[2][0]]
		total_puzzle_moves = current_puzzle[5]	
		isWhite = current_puzzle[6]
		puzzle_mode = true
	else:
		print("Not in puzzle mode")

func _on_previous_pressed():
	if !allow_retry:
		print("Can't retry")
		return
	move_piece(piece_to_unmove, unmove_slot)
	if removed_piece_slot:
		add_piece(removed_piece_type, removed_piece_slot)
		bitboard.call("AddPiece", 63 - removed_piece_slot, removed_piece_type) #unsure what this does
	isWhite = !isWhite
	lock_movement = false
	allow_retry = false
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
