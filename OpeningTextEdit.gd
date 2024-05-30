extends TextEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	set_text(" ")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_text(text: String):
	set_text(text)
