extends Node3D


@export var max_health: int = 0
@onready var player = $".."


var current_health: int = 1
var current_coins: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	#Connects functions
	SignalBus.health_collected.connect(on_health_collected)
	SignalBus.currency_collected.connect(on_currency_collected)
	
	#Sets variables at start
	SignalBus.emit_on_update_health(current_health, max_health)
	player.current_health = current_health
	SignalBus.emit_on_update_currency(current_coins)

func on_health_collected(resource: BaseCollectableResource) -> void:
	current_health += resource.value
	SignalBus.emit_on_update_health(current_health, max_health)


func on_currency_collected(resource: BaseCollectableResource) -> void:
	current_coins += resource.value
	SignalBus.emit_on_update_currency(current_coins)
