extends AnimationPlayer

# to have custscene that can be played and paused between scenes
# have a function called track events that uses signals
# and store data within the animation player itself

var animation_time_elasped : float = 0
var is_cutscene_done := false

# Called when the node enters the scene tree for the first time.
func _ready():
	play("test")
	self.connect("animation_finished", on_animation_finished)

func track_event():
	pass

func play_dialog(dialog : String, label_path : NodePath):
	# todo: animate text to make cutscenes more fancy
	var label := get_tree().get_current_scene().get_node(label_path)
	if label is RichTextLabel:
		label.text = dialog
	# pause dialog here so we can read it
	pause()

func show_next_button(button_path : NodePath):
	var button := get_tree().get_current_scene().get_node(button_path)
	if button is Button:
		button.visible = true
		is_cutscene_done = true

func unpause_cutscene():
	play()

func on_animation_finished():
	animation_time_elasped = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("note1") and !is_cutscene_done and !self.is_playing():
		unpause_cutscene()
	
	if self.is_playing():
		animation_time_elasped += delta
