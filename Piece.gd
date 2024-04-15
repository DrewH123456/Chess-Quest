extends Node2D

signal piece_selected(piece)
@onready var icon_path = $Icon
var slot_ID := -1
var type : int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Icon gets image loaded into it from DataHandler, based on piece_name
func load_icon(piece_name) -> void:
	icon_path.texture = load(DataHandler.assets[piece_name])

# Emits piece_selected signal upon mouse click, passing in self as piece
func _on_icon_gui_input(event):
	if event.is_action_pressed("mouse_left"):
		emit_signal("piece_selected", self)
