extends TextureRect

class_name NoteTimeline

@export var beatmap_maker : BeatmapMaker # easy way to get reference to parent

# the position of the notes should update based on the number of beat subdivisions
var note_array : Array

var note_selector : PackedScene = preload("res://src/mapping_engine/note_selector.tscn")

var scroll : ScrollContainer

var raw_note_times : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	scroll = get_parent()

func snap_to_subdivision(measure_percent : float) -> float:
	for i in range(beatmap_maker.measure_subdivisions, -1, -1):
		if measure_percent >= (float(i) / beatmap_maker.measure_subdivisions):
			return float(i)/beatmap_maker.measure_subdivisions
	return 0.0

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("\nI've been clicked at: ", event.position)
			# convert the position of the click to the ratio of the song by using the length of the note timeline
			# TODO: Make it snap to grid
			
			var current_position_in_song : float = ((scroll.scroll_horizontal / scroll.get_h_scroll_bar().max_value + event.position.x) / scroll.get_h_scroll_bar().max_value) * beatmap_maker.song_length
			
			# get the current measure based on the time.
			# _s postfix in variable names indicates seconds unit.
			var beat_length_s = (60 / beatmap_maker.beats_per_minute)
			var measure_length_s = beat_length_s * beatmap_maker.number_of_notes_in_measure
			var current_measure_position : float = current_position_in_song / measure_length_s
			print(beat_length_s, ' ', measure_length_s, ' ', current_measure_position, ' ', current_position_in_song)
			
			var snapped_measure_percent : float = snap_to_subdivision(current_measure_position - floor(current_measure_position))
			var time_offset_s = snapped_measure_percent * measure_length_s
						
			current_position_in_song = floor(current_measure_position) * measure_length_s + time_offset_s
			
			# add current song position in note times to make sure you cant have overlapping notes
			if current_position_in_song in raw_note_times.keys():
				print("can't put a note here")
				return
			raw_note_times[current_position_in_song] = true
			
			#current_position_in_song += (beatmap_maker.time_offset_ms * 0.001)
			
			print(current_position_in_song, ' ', time_offset_s)
			
			print("Current Song Location: ", current_position_in_song)
			# TODO: Make it so that you can change the type of note in that location
			var note_data : RhythmGameUtils.NoteData = RhythmGameUtils.NoteData.new(RhythmGameUtils.NOTES.NOTE1, current_position_in_song)
			var note_sprite := note_selector.instantiate()
			# add note object to sprite
			note_sprite.note = note_data
			# set up note sprite signals
			note_sprite.note_deleted.connect(delete_note)
			# put the note sprite on the right place in the timeline while keeping it centered
			note_sprite.position.x = (note_data.start_time / beatmap_maker.song_length) * custom_minimum_size.x
			note_sprite.position.y = self.size.y / 2
			# make sure to actually add the note object to the note array, and add the note sprite to the scene
			add_child(note_sprite)
			note_array.append([note_data, note_sprite])

func delete_note(note_data : RhythmGameUtils.NoteData, note_sprite):
	# remove note from note array
	note_array.erase([note_data, note_sprite])
	raw_note_times.erase(note_data.start_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
