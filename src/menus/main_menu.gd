extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/PlayButton.connect("button_up", play_game)
	$VBoxContainer/OptionsButton.connect("button_up", open_options)
	$VBoxContainer/CreditsButton.connect("button_up", show_credits)
	$VBoxContainer/QuitButton.connect("button_up", quit_game)

func play_game():
	get_tree().change_scene_to_file("res://src/game_engine/beatmap.tscn")

func open_options():
	print("doesn't exist yet")

func show_credits():
	print("doesn't exist yet")

# https://docs.godotengine.org/en/stable/tutorials/inputs/handling_quit_requests.html
func quit_game():
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
