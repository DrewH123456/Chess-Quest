extends Node2D

# Class member variables
var fen: String
var previous_variation: Node = null
var next_variations: Array = []

# Initialize the variation with the FEN string
func initialize(fen_string: String) -> void:
	fen = fen_string
	previous_variation = null
	next_variations = []

# Function to set the previous variation
func set_previous(variation: Node) -> void:
	previous_variation = variation

# Function to add a next variation
func add_next(variation: Node) -> void:
	next_variations.append(variation)

# Function to get the FEN string
func get_fen() -> String:
	return fen

# Function to get the previous variation
func get_previous() -> Node:
	return previous_variation

# Function to get the next variations
func get_next() -> Array:
	return next_variations

# Example function to display the variation details (for debugging)
func display_details() -> void:
	print("FEN: ", fen)
	if previous_variation:
		print("Previous: ", previous_variation.get_fen())
	else:
		print("Previous: None")
	for next_variation in next_variations:
		print("Next: ", next_variation.get_fen())
