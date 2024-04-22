extends Node

var assets := []
enum PieceNames {WHITE_BISHOP, WHITE_KING, WHITE_KNIGHT, WHITE_PAWN, WHITE_QUEEN, WHITE_ROOK, BLACK_BISHOP, BLACK_KING, BLACK_KNIGHT, BLACK_PAWN, BLACK_QUEEN, BLACK_ROOK}
var fen_dict := {"b" = PieceNames.BLACK_BISHOP, "k" = PieceNames.BLACK_KING,
					"n" = PieceNames.BLACK_KNIGHT, "p" = PieceNames.BLACK_PAWN,
					"q" = PieceNames.BLACK_QUEEN, "r" = PieceNames.BLACK_ROOK,
					"B" = PieceNames.WHITE_BISHOP, "K" = PieceNames.WHITE_KING,
					"N" = PieceNames.WHITE_KNIGHT, "P" = PieceNames.WHITE_PAWN,
					"Q" = PieceNames.WHITE_QUEEN, "R" = PieceNames.WHITE_ROOK, }

enum slot_states {NONE, FREE, CHECK, HINT}

# Called when the node enters the scene tree for the first time.
func _ready():
	assets.append("res://Piece Images/white_bishop.png")
	assets.append("res://Piece Images/white_king.png")
	assets.append("res://Piece Images/white_knight.png")
	assets.append("res://Piece Images/white_pawn.png")
	assets.append("res://Piece Images/white_queen.png")
	assets.append("res://Piece Images/white_rook.png")
	assets.append("res://Piece Images/black_bishop.png")
	assets.append("res://Piece Images/black_king.png")
	assets.append("res://Piece Images/black_knight.png")
	assets.append("res://Piece Images/black_pawn.png")
	assets.append("res://Piece Images/black_queen.png")
	assets.append("res://Piece Images/black_rook.png")
	pass # Replace with function body.

# Fen string, piece_to_move, puzzle_destination, enemy_piece, enemy_destination, total moves, isWhite
var single_move_puzzles := [
	["4r2k/1p3rbp/2p1N1p1/p3n3/P2NB1nq/1P6/4R1P1/B1Q2RK1 b - - 4 32", [39], [55], [], [], 1, false],
	["r2q1rk1/1bppb1pp/n3p3/5P2/2BP1P2/4P3/1PPnQK1P/R1B3NR b - - 1 12", [12], [39], [], [], 1, false],
	["2rqk2r/pp1bn2p/3bp3/6pP/1PBPN1Pn/1R6/P1P5/2BQ1RK1 w - - 7 23", [36], [19], [], [], 1, true],
	["1nN1k1r1/1p3b2/r7/3p2qB/pb2p2p/3P3P/PP3N2/R2Q1R1K b - - 5 29", [33], [9], [], [], 1, false],
	["3Q2b1/1p3kr1/1n2r3/2P1b3/p3N2p/P4B1P/8/1R3R1K w - - 1 39", [45], [31], [], [], 1, true],
]

# Fen string, piece_to_move, puzzle_destination, enemy_piece, enemy_destination, total moves, isWhite
var multi_move_puzzles := [
	["4r3/1pp2rbk/6pn/4n3/P3BN1q/1PB2bPP/8/2Q1RRK1 b - - 0 31", [39, 46], [46, 54], [37], [54], 2, false], 
	["r3n1k1/pb5q/1p2N2p/P2pP2r/4nQ2/1PbRRN1P/5PBK/8 w - - 3 30", [37], [5], [], [], 1, true]
]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
