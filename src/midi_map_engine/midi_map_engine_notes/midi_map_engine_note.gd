extends PathFollow2D
class_name MidiMapEngineNote


var note_travel_rate = 0.0

func _ready():
	pass
	
func set_polygon(width:=100.0, height:=50.0):
	var the_polygon =  PackedVector2Array([Vector2(-0.5*width,-0.5*height),Vector2(0.5*width,-0.5*height),Vector2(0.5*width,0.5*height),Vector2(-0.5*width,0.5*height)])

	$Polygon2D.polygon = the_polygon
	$Area2D/CollisionPolygon2D.polygon = the_polygon
	
func start():
	note_travel_rate = 500/3
	
func _process(delta):
	progress += note_travel_rate*delta
	#print(progress_ratio)

