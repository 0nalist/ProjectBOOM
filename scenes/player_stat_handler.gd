extends Node3D


@export var max_health: float = 100
@onready var player = $".."


var current_health: float = 1
var current_coins: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	#Connects functions
	SignalBus.health_collected.connect(on_health_collected)
	SignalBus.currency_collected.connect(on_currency_collected)
	SignalBus.weapon_collected.connect(on_weapon_collected)
	
	#Sets variables at start
	current_health = max_health-20
	SignalBus.emit_on_update_health(current_health, max_health)
	SignalBus.emit_on_update_currency(current_coins)

func on_health_collected(resource: BaseCollectableResource) -> void:
	current_health += resource.value
	SignalBus.emit_on_update_health(current_health, max_health)


func on_currency_collected(resource: BaseCollectableResource) -> void:
	current_coins += resource.value
	SignalBus.emit_on_update_currency(current_coins)


func on_weapon_collected(resource: BaseCollectableResource) -> void:
	player.equip(resource.collectable_type)##right here
	SignalBus.emit_on_pickup_weapon(resource.collectable_type)


func take_damage(amount: float):
	current_health -= amount
	SignalBus.emit_on_update_health(current_health, max_health)
	if current_health <= 0:
		player.kill()
	
func add_health(amount: float):
	take_damage(-amount)
	#current_health += amount
	#SignalBus.emit_on_update_health(current_health, max_health)
