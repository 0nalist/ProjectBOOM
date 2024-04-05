extends CanvasLayer

class_name UI



signal start_game()

@onready var main_menu = %MainMenu
@onready var score_label = %Score


'''
@onready var SFX_BUS_ID
@onready var MUSIC_BUS_ID



'''


func _on_main_menu_start_game() -> void:
	start_game.emit()



var score = 0:
	set(new_score):
		score = new_score
		update_score_label()
		
		
# Called when the node enters the scene tree for the first time.
func _ready():
	update_score_label()

func update_score_label():
	score_label.text = str(score)
	
	
	
'''
func on_collected(collectable) -> void:
	score += 100
'''

