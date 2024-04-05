extends Area3D
class_name Pickup

@onready var label_3d = $Label3D

@export var label_text: Resource

'''
func _on_body_entered(body):
	if body.is_in_group("player"):
		
		body.collect(self)
		#delay
		queue_free()
'''
func _physics_process(delta):
	rotate(Vector3(0,1,0), 1*delta)
	
	#do a sinewave up/down sway



func _on_pickup_area_body_entered(body):
	if body.is_in_group("player"):
		
		label_3d.show()
		
		


func _on_pickup_area_body_exited(body):
	if body.is_in_group("player"):
		label_3d.hide()
