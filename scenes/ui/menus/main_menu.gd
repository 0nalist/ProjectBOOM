extends Control

#class_name MainMenu

signal start_game()
signal main_menu_showing()

@onready var buttons_vbox = $MarginContainer/VBoxContainer/ButtonsVbox
@onready var label = $MarginContainer/VBoxContainer/Label



var splash_texts = [
	"- working title -",
	"- demo made hastily && with love -",
	"- all art is placeholder -",
	#"- investigate 311 -",
	"- basic ass features coming soon -",
	"- don't try to use the options menu -",
	"- i'm more of an 'ideas' guy -",
	"- who let the dogs out -",
	"- pre-pre-alpha version 0.0.0.02 -",
	'- "LeArN tO cOdE!"... ok -',
	'- all systems are placeholder -',
	'- i just need to implement this new feature... -',
	"- brb refactoring every single function -",
	"- please help me -",
	
]




func _ready():
	focus_button()
	set_random_splash_text()
	

func set_random_splash_text():
	var rand = randi() % splash_texts.size()
	label.text = splash_texts[rand]


func _on_start_game_button_pressed() -> void:
	start_game.emit()
	hide()

func _on_options_button_pressed():
	pass # Replace with function body.

func _on_quit_game_button_pressed():
	get_tree().quit()



func _on_visibility_changed() -> void:
	if visible:
		focus_button()

func focus_button():
	if buttons_vbox:
		var button: Button = buttons_vbox.get_child(0)
		if button is Button:
			button.grab_focus()
