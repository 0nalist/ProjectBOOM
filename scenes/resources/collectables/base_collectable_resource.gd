class_name BaseCollectableResource
extends Resource


#OLD
@export var collectable_texture: Texture = null
@export var collectable_type: String = ""
#ENDOLD

@export_enum("Health", "Mana", "Currency", "Weapon") var tag = "EMPTY"

@export var value: int = 0




