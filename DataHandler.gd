extends Node

var assets := []
enum PieceNames {WHITE_BISHOP, WHITE_KING, WHITE_KNIGHT, WHITE_PAWN, WHITE_QUEEN, WHITE_ROOK, BLACK_BISHOP, BLACK_KING, BLACK_KNIGHT, BLACK_PAWN, BLACK_QUEEN, BLACK_ROOK}
var fen_dict := {"b" = PieceNames.BLACK_BISHOP, "k" = PieceNames.BLACK_KING,
					"n" = PieceNames.BLACK_KNIGHT, "p" = PieceNames.BLACK_PAWN,
					"q" = PieceNames.BLACK_QUEEN, "r" = PieceNames.BLACK_ROOK,
					"B" = PieceNames.WHITE_BISHOP, "K" = PieceNames.WHITE_KING,
					"N" = PieceNames.WHITE_KNIGHT, "P" = PieceNames.WHITE_PAWN,
					"Q" = PieceNames.WHITE_QUEEN, "R" = PieceNames.WHITE_ROOK, }

enum slot_states {NONE, FREE, CHECK}

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

# Fen string, piece_to_move, puzzle_destination, isWhite
var single_move_puzzles := [
	["4r2k/1p3rbp/2p1N1p1/p3n3/P2NB1nq/1P6/4R1P1/B1Q2RK1 b - - 4 32", 38, 54, false],
	["r3n1k1/pb5q/1p2N2p/P2pP2r/4nQ2/1PbRRN1P/5PBK/8 w - - 3 30", 37, 5, true]
]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
