extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("I've been clicked at: ", event.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
