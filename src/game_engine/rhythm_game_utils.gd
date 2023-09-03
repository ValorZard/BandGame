extends Node

# note data
# duration of a note doesnt matter
enum NOTE_TYPES {NORMAL, HOLD}
# sorta analagous to actual notes (B, C, C#, etc)
# Convert to the actual keys needing to be pressed
enum NOTES {
	NOTE1, 
	NOTE2, 
	NOTE3,
	NOTE4,
}

enum HIT_RESULTS {NO_HIT, HIT, PERFECT}

# visual stuff

# we hit this note when it needs to be hit
class NoteData:
	var note_name : NOTES
	var start_time : float
	var note_type : NOTE_TYPES
	var already_hit : bool
	
	func _init(note_name : NOTES, start_time : float):
		self.note_name = note_name
		self.start_time = start_time
		self.note_type = NOTE_TYPES.NORMAL
		self.already_hit = false
	
	# returns a tuple of the hit result and the absolute time between time hit and start time
	func check_hit(time_hit : float) -> float:
		#print(time_hit, " ", self.start_time)\
		# absolute value of the tiem difference
		var time_difference : float = abs(start_time - time_hit)
		return time_difference

class NoteObject:
	var data : NoteData 
	var sprite : Node # this could either be a texture rect or a sprite, so Node is a safe bet
	
	func _init(data : NoteData, sprite):
		self.data = data
		self.sprite = sprite

# we hold this note for as long as it takes
class HoldNote extends NoteData:
	var end_time : float
	func _init(note_name, start_time, end_time):
		super._init(note_name, start_time)
		self.note_type = NOTE_TYPES.HOLD
		self.end_time = end_time
