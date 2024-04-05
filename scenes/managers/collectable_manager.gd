class_name  CollectableManager

extends Node

var current_coin_count: int = 0



# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.connect("collect_entity", on_entity_collected)
	
	

func on_entity_collected(collectable_resource: BaseCollectableResource):
	match collectable_resource.collectable_type:
		"":
			print("ERROR NO COLLECTABLE TYPE FOUND")
			return
		"coin":
			current_coin_count += collectable_resource.value
			print("Coin Value: " + str(collectable_resource.value))
			print("Coins: " + str(current_coin_count))
		"weapon":
			pass
