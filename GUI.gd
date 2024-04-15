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
	move_piece(piece_selected, slot.slot_ID)
	if puzzle_mode:
		puzzle_move(slot)
	isWhite = !isWhite
	clear_board_filter()
	piece_selected = null

# Checks if piece selected is correct and moved to proper square
func puzzle_move(slot) -> void:
	if (piece_selected == piece_to_move) && (slot == puzzle_destination):
		print("Nice work")
		puzzle_mode = false
	else: 
		print("Try again")
		
# Move selected piece to given destination
func move_piece(piece, destination) -> void:
	if piece_array[destination]: # Checks if there is a piece existing on destination, if so, remove it from the board
		remove_from_bitboard(piece_array[destination])
		piece_array[destination].queue_free()
		piece_array[destination] = 0
	
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

# When button is pressed, add a piece
func _on_test_button_pressed():
	parse_fen(fen)
	bitboard.call("InitBitBoard", fen)
	#set_board_filter(bitboard.call("GetBlackBitboard")) 


func _on_test_puzzle_pressed():
	current_puzzle = randomly_select_puzzle()
	parse_fen(current_puzzle[0])
	bitboard.call("InitBitBoard", current_puzzle[0])
	piece_to_move = piece_array[current_puzzle[1]]
	puzzle_destination = grid_array[current_puzzle[2]]	
	isWhite = current_puzzle[3]
	puzzle_mode = true
	
func randomly_select_puzzle() -> Array :
	var random_index := randi_range(0, DataHandler.single_move_puzzles.size() - 1)
	var random_puzzle : Array = DataHandler.single_move_puzzles[random_index]
	return random_puzzle
	
func clear_board():
	for i in range(64):
		if piece_array[i]:
			piece_array[i].queue_free()
			piece_array[i] = null
