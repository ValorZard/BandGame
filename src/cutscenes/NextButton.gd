extends Button

@export var scene_to_change_to : PackedScene
@export var beatmap_file_for_next_song : StringName

@export var is_next_scene_song := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_up():
	if !is_next_scene_song:
		SceneSwitcher.goto_packed_scene(scene_to_change_to)
	else:
		# have the scene we're going to change to load in after the song
		SceneSwitcher.goto_song(beatmap_file_for_next_song, scene_to_change_to)
		pass
