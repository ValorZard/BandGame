extends TextureRect

class_name NoteTimeline

@export var beatmap_maker : BeatmapMaker # easy way to get reference to parent

# the position of the notes should update based on the number of beat subdivisions
var note_array : Array

var note_selector : PackedScene = preload("res://src/mapping_engine/note_selector.tscn")

var scroll : Node

# Called when the node enters the scene tree for the first time.
func _ready():
	scroll = get_parent()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("I've been clicked at: ", event.position)
			# convert the position of the click to the ratio of the song by using the length of the note timeline
			# TODO: Make it snap to grid
			
			var current_position_in_song : float = (scroll.scroll_horizontal + (event.position.x / size.x)) / scroll.get_h_scroll_bar().max_value * beatmap_maker.song_length
			
			print("Current Song Location: ", current_position_in_song)
			# TODO: Make it so that you can change the type of note in that location
			var note_obj : RhythmGameUtils.Note = RhythmGameUtils.Note.new(RhythmGameUtils.NOTES.A, current_position_in_song)
			var note_sprite := note_selector.instantiate()
			# add note object to sprite
			note_sprite.note = note_obj
			# put the note sprite on the right place in the timeline while keeping it centered
			note_sprite.position.x = event.position.x
			note_sprite.position.y = self.size.y / 2
			# make sure to actually add the note object to the note array, and add the note sprite to the scene
			add_child(note_sprite)
			note_array.append([note_obj, note_sprite])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
