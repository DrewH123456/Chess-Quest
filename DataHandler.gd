extends Node

var assets := []

enum PieceNames {WHITE_BISHOP, WHITE_KING, WHITE_KNIGHT, WHITE_PAWN, WHITE_QUEEN, WHITE_ROOK, BLACK_BISHOP, BLACK_KING, BLACK_KNIGHT, BLACK_PAWN, BLACK_QUEEN, BLACK_ROOK}

var fen_dict := {"b" = PieceNames.BLACK_BISHOP, "k" = PieceNames.BLACK_KING,
					"n" = PieceNames.BLACK_KNIGHT, "p" = PieceNames.BLACK_PAWN,
					"q" = PieceNames.BLACK_QUEEN, "r" = PieceNames.BLACK_ROOK,
					"B" = PieceNames.WHITE_BISHOP, "K" = PieceNames.WHITE_KING,
					"N" = PieceNames.WHITE_KNIGHT, "P" = PieceNames.WHITE_PAWN,
					"Q" = PieceNames.WHITE_QUEEN, "R" = PieceNames.WHITE_ROOK, }	
					
var reverse_fen_dict := {
		PieceNames.BLACK_BISHOP: "b", PieceNames.BLACK_KING: "k",
	PieceNames.BLACK_KNIGHT: "n", PieceNames.BLACK_PAWN: "p",
	PieceNames.BLACK_QUEEN: "q", PieceNames.BLACK_ROOK: "r",
	PieceNames.WHITE_BISHOP: "B", PieceNames.WHITE_KING: "K",
	PieceNames.WHITE_KNIGHT: "N", PieceNames.WHITE_PAWN: "P",
	PieceNames.WHITE_QUEEN: "Q", PieceNames.WHITE_ROOK: "R"
}

enum slot_states {NONE, FREE, CHECK, HINT}

# Called when the node enters the scene tree for the first time.
func _ready():
	assets.append("res://Piece Images/Chess_blt60.png")
	assets.append("res://Piece Images/Chess_klt60.png")
	assets.append("res://Piece Images/Chess_nlt60.png")
	assets.append("res://Piece Images/Chess_plt60.png")
	assets.append("res://Piece Images/Chess_qlt60.png")
	assets.append("res://Piece Images/Chess_rlt60.png")
	assets.append("res://Piece Images/Chess_bdt60.png") 
	assets.append("res://Piece Images/Chess_kdt60.png")
	assets.append("res://Piece Images/Chess_ndt60.png")
	assets.append("res://Piece Images/Chess_pdt60.png")
	assets.append("res://Piece Images/Chess_qdt60.png")
	assets.append("res://Piece Images/Chess_rdt60.png")
	pass # Replace with function body.

# Fen strings, total moves, isWhite
var single_move_puzzles := [
]

# Fen strings, total moves, isWhite
var multi_move_puzzles := [
]

# Fen strings, total moves, isWhite
var queens_gambit_boardstates := [
]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
