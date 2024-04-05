class_name BaseCollectableEntity
extends Area3D
#CoffeeCrow Tutorial

@onready var sprite_3d = $Sprite3D as Sprite3D
@onready var animation_player = $AnimationPlayer as AnimationPlayer


@export var collectable_resource: BaseCollectableResource = null



signal collect_entity


func _ready():
	connect("collect_entity", on_collect)
	sprite_3d.texture = collectable_resource.collectable_texture
	handle_animations()
	
	

func on_collect() -> void:
	SignalBus.emit_collect_entity(collectable_resource)
	handle_sounds()
	#queue_free()


func handle_animations() -> void:
	match collectable_resource.collectable_type:
		"":
			return
		"coin":
			if collectable_resource.value == 1:
				animation_player.play("coin1")



func handle_sounds() -> void:
	match collectable_resource.collectable_type:
		"":
			return
		"coin":
			var sound_to_play = house_fourths[randi() % house_fourths.size()]
			house_fourth_player.stream = sound_to_play
			house_fourth_player.play()
			
			
			
			


@onready var house_fourth_player = $ipod/HouseFourthPlayer
var house_fourths = [
	preload("res://assets/audio/pickups/coins/housefourth1.ogg"),
	preload("res://assets/audio/pickups/coins/housefourth2.ogg"),
	preload("res://assets/audio/pickups/coins/househit3.ogg")
	 ]
