extends CharacterBody3D

class_name Player

# ========== KNOWN BUGS ================
#
# player can still harm enemies when paused -- but no longer crashes!
#
# rhythm is tied to processing speed :(((((
#
# h velocity not conserved when jumping out of slide
##		it seems the jump part of a jump slide is now holding h velocity and still has the player in the SLIDE state, but all h velocity is lost in the fall post jump peak
#
#
# =================== TO DO =====================
#
# Pickupable weapons
#
# Inventory
#
# Beat programmer
#
# Projectile system
#
# experiment with 3d low poly enemy
#
# parkour style climb up. 
##	FAILED TO IMPLEMENT. Non functioning code should exist commented out
#
# Double Jump-- Scratch that-- SHOTGUN JUMP !!!
#
# stairs
#
# smaller collision box on slide
#
# line of sight as precondition for enemy "chase" state
# optimize enemies--lag when too many too close
#
# improve walljumps

#DOESNT WORK BECAUSE I DONT KNOW HOW SIGNALS WORK LOL. I think I need to make the beat system a child scene of game
signal pause_beat_system
signal resume_beat_system
signal collected(collectable)


func collect(collectable):
	collected.emit(collectable)





# ======== PLAYER BODY PARTS ======== #
@onready var head = $Head
@onready var main_camera = %MainCamera
@onready var stamina_bar = %StaminaBar


# PLAYER VARIABLES
@export var stamina: float = 70.0
@export var max_stamina: float = 100.0
var dead = false


# ======= GUNS/WEAPONS ======= #
@onready var gun_ray = $Head/MainCamera/GunManager/GunRay
@onready var shotgun_sprite_3d = $Head/MainCamera/GunManager/ShotgunSprite3D
@onready var pistol_sprite_3d = $Head/MainCamera/GunManager/PistolSprite3D


@onready var melee_ray = $Head/MainCamera/GunManager/MeleeRay
@onready var right_fist_sprite_3d = $Head/MainCamera/GunManager/RightFistSprite3D





# ==== = SOUNDS = ==== #
@onready var one_hi_hat_hit = $ipod/OneHihat1
@onready var open_hi_hat_hit = $ipod/OpenHiHatHit
@onready var one_kick_punch = $ipod/OneKickPunch
@onready var clap = $ipod/OneClap






# FINE TUNE JUMP MECHANICS
@export_category("Movement Parameters")
@export var Jump_Peak_Time: float = .4
@export var Jump_Fall_Time: float = .5
@export var Jump_Height: float = 4.269
#@export var Jump_Distance: float = 4.0


# STAMINA SYSTEM #
var stamina_recovery = 0.5
var jump_stamina_cost = 15.0
var slide_stamina_cost = 17.0


# CAMERA SETTINGS
var mouse_sens = 0.0015
#var cam_clamp_down = -70
#var cam_clamp_up = 80
const BOB_FREQ = 2
const BOB_AMP = .09
var t_bob = 0.0
#var base_fov = 75
#var fov_change = 15

#Movement calcd from accelERATION and FRICTION instead of SPEED
var accel = 90.0
const FRICTION = .85
var Jump_Velocity: float = 17.3


#WALLJUMP KIT
const WALL_FRICTION = .96
const WALL_JUMP_DAMPER = .77
const WALL_JUMP_VELOCITY = 20.0
const WALL_JUMP_ALTERING = 25

#WALLJUMP STATE SENSOR
const FLOOR = 0
const WALL = 1
const AIR = 2
const SLIDE = 4
var current_state := AIR


var Jump_Gravity: float = 17.0
var Fall_Gravity: float = 17.0

# GUN INITIALIZATION
var one_shooting = false
var two_shooting = true
var three_shooting = true

var holding_pistol = true
var holding_shotgun = false
var holding_right_fist = true

var one_stack := []
var two_stack := []
var three_stack := []


func calculate_movement_parameters()->void:
	Jump_Gravity = (2*Jump_Height)/pow(Jump_Peak_Time,2)
	Fall_Gravity = (2*Jump_Height)/pow(Jump_Fall_Time,2)
	Jump_Velocity = Jump_Gravity * Jump_Peak_Time
	



#Beginning of new movement script
var camera_rotation = Vector2(0,0)

func _ready():
	#Connect signals
	
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	calculate_movement_parameters()
	#$CanvasLayer/DeathScreen/Panel/RestartButton.button_up.connect(restart)
	#$CanvasLayer/DeathScreen/Panel/QuitButton.button_up.connect(exit_game)
	%StaminaBar.value = stamina #this next
	
	drum_machine_factory_reset()
	start_beat_count()
	
	if not holding_shotgun: 
		shotgun_sprite_3d.visible = false
	else: shotgun_sprite_3d.visible = true
	
	if not holding_pistol:
		pistol_sprite_3d.visible = false
	else: pistol_sprite_3d.visible = true
	
	if not holding_right_fist:
		right_fist_sprite_3d.visible = false
	else: right_fist_sprite_3d.visible = true
	


func _physics_process(delta):
	update_stamina()
	
	if not is_on_floor():
		if velocity.y>0:
			velocity.y -= Jump_Gravity * delta
		else:
			velocity.y -= Fall_Gravity * delta
	
	if dead:
		return
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_fwd", "move_bwd")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x += direction.x * accel * delta
		velocity.z += direction.z * accel * delta

	if Input.is_action_just_pressed("start_stop_weapons_1slot"):
		start_stop_weapons_1slot()
	if Input.is_action_just_pressed("start_stop_weapons_2slot"):
		start_stop_weapons_2slot()
	if Input.is_action_just_pressed("start_stop_weapons_3slot"):
		start_stop_weapons_3slot()
		
	if Input.is_action_just_pressed("one"):
		cycle_one()
		set_user_hats()#FOR DEBUG
	if Input.is_action_just_pressed("two"):
		cycle_two()
	if Input.is_action_just_pressed("three"):
		cycle_three()
		
		
	if Input.is_action_just_pressed("debug"):
		print(position)
		print(current_state)
		print(velocity)
		
	handle_jump(direction)
	move_and_slide()
	update_state()
	velocity.x *= FRICTION
	velocity.z *= FRICTION
	
	#WALL FRICTION FROM WALLJUMP KIT
	if current_state == WALL:
		velocity.y *= WALL_FRICTION
	
	#HEADBOB
	if not sliding:
		t_bob += delta * velocity.length() * float(is_on_floor())
		main_camera.transform.origin = _headbob(t_bob)




func _input(event):
	if dead:
		return
	if event is InputEventMouseMotion:
		var mouse_event = event.relative * mouse_sens
		head.rotate_x(deg_to_rad(-event.relative.x * mouse_sens))
		camera_look(mouse_event)
	if Input.is_action_just_pressed("slide"):
		slide()
	if Input.is_action_just_pressed("equip"):
		#if not holding_pistol and not holding_right_fist and not holding_shotgun:
		#	start_beat_count()
		equip()
	if Input.is_action_just_pressed("esc"):
		if counting_beat:
			pause_beat_system.emit()
		if !counting_beat:
			resume_beat_system.emit()




func camera_look(movement: Vector2):
	camera_rotation += movement
	camera_rotation.y = clamp(camera_rotation.y, -1.5, 1.6)
	
	transform.basis = Basis()
	main_camera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0), -camera_rotation.x) # first rotate y
	main_camera.rotate_object_local(Vector3(1,0,0), -camera_rotation.y)


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func update_state():
	if is_on_wall_only():
		current_state = WALL
	elif sliding:
		current_state = SLIDE
	elif is_on_floor():
		current_state = FLOOR
	else:
		current_state = AIR

func update_stamina():
	%StaminaBar.value = stamina
	if stamina < max_stamina:
		if current_state != SLIDE and current_state != AIR:
			stamina += stamina_recovery
	if stamina <= 0:
		stamina = 0
	%StaminaBar.value = stamina
	

func handle_jump(dir):
	if Input.is_action_just_pressed("jump") and can_jump:
		if stamina <= jump_stamina_cost: return
		if current_state == AIR: return
		stamina -= jump_stamina_cost
		if current_state == FLOOR:
			velocity.y = Jump_Velocity
		if current_state == SLIDE:
			velocity.y += Jump_Velocity #+ velocity.y * slide_speed ##Thisone
			velocity = Vector3(velocity.x*slide_speed, Jump_Velocity, velocity.z*slide_speed)
		if current_state == WALL:
			'''
			if can_climb:
				climb()
				return
			'''
			velocity = get_wall_normal() * WALL_JUMP_VELOCITY
			print(get_wall_normal())
			velocity += -dir * WALL_JUMP_ALTERING
			velocity.y += Jump_Velocity * WALL_JUMP_DAMPER
		
		

#CONDITIONAL VARIABLES for CLIIMB UP !!!DOESNT WORK!!!!
var can_jump := true
#walclimb
var camera_can_move := true
var is_crouching := false

func can_climb():
	
	if !$Head/ChestRay3D.is_colliding():
		return false
	for ray in $Head/ReachRays.get_children():
		if ray.is_colliding():
			return false
	return true
	




func climb():
	pass
	
	
	'''#BROKEN AS FUCK-- SENDS THE PLAYER TO A SPECIFIC GLOBAL POSITION INSTEAD OF RELATIVE POSITION
	
	#MTemporarily disable controls that should not function during climbing
	velocity = Vector3.ZERO
	can_jump = false
	camera_can_move = false #unnecessary
	
	var v_move_time = 0.4
	var h_move_time = 0.2
	
	var vertical_target = global_transform.origin * Vector3(0, 1.85, 0)
	var forward_target = global_transform.origin + (-global_transform.basis.z * 1.2)
	
	var vm_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	#var camera_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	vm_tween.tween_property(self, "global_transform:origin", vertical_target, v_move_time)
	#camera_tween.tween_property(main_camera, "rotation_degrees:x", clamp(main_camera.rotation_degrees.x - 20.0, -85, 90), v_move_time)
	#camera_tween.tween_property(main_camera, "rotation_degrees:z", -5.0*sign(randf_range(-10000,10000)), v_move_time)
		
	await vm_tween.finished
	
	var fm_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	fm_tween.tween_property(self, "global_position", forward_target, h_move_time)
	
	var camera_reset = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	camera_reset.tween_property(main_camera, "rotation_degrees:x", 0.0, h_move_time)
	camera_reset.tween_property(main_camera, "rotation_degrees:z", 0.0, h_move_time)
	
	await fm_tween.finished
	
	can_jump = true
	camera_can_move = true
'''



		
func damage_player(value: int):
	$PlayerStatHandler.take_damage(value)

func heal(value: int):
	$PlayerStatHandler.add_health(value)
	


var sliding = false
var slide_time = 0.314159
var slide_speed = 3.14
var slide_cooldown = 0.1

func slide():
	if sliding: return
	if stamina <= slide_stamina_cost: return
	else:
		if is_on_floor():
			sliding = true
			stamina -= slide_stamina_cost
			var preslide_speed = accel
			accel *= slide_speed
			get_tree().create_tween().tween_property(main_camera, "position:y", main_camera.position.y-.8, slide_time/2 )
			await get_tree().create_timer(slide_time).timeout
			accel = preslide_speed
			
			get_tree().create_tween().tween_property(main_camera, "position:y", main_camera.position.y+.8 , slide_time/2 )
			await get_tree().create_timer(slide_cooldown).timeout
			sliding = false
	



func equip_(weapon):
	return weapon
	#I WANT to be able to pass the weapon, parse the weapon


func equip():
	equip_shotgun()
	equip_pistol()
	equip_right_fist()

var pistol_damage := 3
var shotgun_damage := 7
var right_fist_damage := 5


func equip_pistol():
	pistol_sprite_3d.visible = true
	pistol_sprite_3d.play("equip")
	holding_pistol = true
	if "magnum" not in one_stack:
		one_stack.append("magnum")

func equip_shotgun():
	shotgun_sprite_3d.visible = true
	shotgun_sprite_3d.play("equip")
	holding_shotgun = true



func equip_right_fist():
	right_fist_sprite_3d.visible = true
	right_fist_sprite_3d.play("equip")
	holding_right_fist = true



func start_stop_weapons_1slot():
	if not one_shooting:
		one_shooting = true
	else:
		one_shooting = false
	#await get_tree().create_timer(1.0).timeout

func start_stop_weapons_2slot():
	if not two_shooting:
		two_shooting = true
	else:
		two_shooting = false

func start_stop_weapons_3slot():
	if not three_shooting:
		three_shooting = true
	else:
		three_shooting = false




var one_slot_current = 0
func cycle_one():
	# Cycles hihat tracks for now. This will be handled by pickups and menus later
	# cycle_one() will then be swapped out with functionality to cycle hihat samples
	one_slot_current = (one_slot_current + 1) % hat_pats.size()
	if one_slot_current > hat_pats.size():
		one_slot_current = 0
	
var two_slot_current = 0
func cycle_two():
	two_slot_current = (two_slot_current + 1) % snare_pats.size()
	if two_slot_current > snare_pats.size():
		two_slot_current = 0
		
var three_slot_current = 0
func cycle_three():
	three_slot_current = (three_slot_current + 1) % kick_pats.size()
	if three_slot_current > kick_pats.size():
		three_slot_current = 0



# ______ P A T T E R N   M E M O R Y _______ #
var hat_pats: Array = [[],[],[]]
var user_hats: Array = []
var snare_pats: Array = [[]]
var kick_pats: Array = [[],[]]

func set_user_hats(): #set_user_hats(sixteenth)
	user_hats.append(1)
	print(user_hats)

func drum_machine_factory_reset():
	
	# = = = = = HATS = = = = = #
	#hat_pats[0] = [0,0,0,0, 0,0,0,0,0, 0,0,0,0, 0,0,0,0]
	hat_pats[0] = [3,7,11,15]
	#hat_pats[1] = [1,5,9,12,13,14]
	#hat_pats[2] = [1,2,5,6,9,10,13,14]
	hat_pats[1] = [1,2,3,5,6,7,9,10,11,12,13,14]
	#hat_pats[3] = [1,2,4,5,6,8,9,10,12,13,14,16]
	hat_pats[2] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
	
	# === SNARES & CLAPS === #
	snare_pats[0] = [5,13] 
	
	# = ===== = KICKS = ===== = #
	kick_pats[0] = [1,11]
	kick_pats[1] = [1,5,9,13]



# ===== ==== === == BEATSHOTS SYSTEM == === ==== ===== #
var beat_count := 0
var bar_beat := 0
var counting_beat := false
var bpm := 140.0
var bps := bpm/60.0
var sixteenth := 0
var bar_sixteenth := 0
var bar_one_twenty_eighth := 0

func start_beat_count():
	counting_beat = true
	var sixteenth_duration = (60.0 / bpm) / 4.0
	while counting_beat: # and not game_paused:
		check_for_shots()
		await get_tree().create_timer(sixteenth_duration).timeout
		sixteenth += 1
		#@warning_ignore("integer_division")  WORKS, but not using "beats" for anything at the moment
		#beat_count = sixteenth / 4
		bar_sixteenth += 1
		bar_one_twenty_eighth += 1
		
		if bar_sixteenth > 16:
			bar_sixteenth = 1
		if bar_one_twenty_eighth > 128:
			bar_one_twenty_eighth = 1
		#print(sixteenth)

func stop_beat_count():
	counting_beat = false

#Check every 16th note. I will have to redo this to support modular drum patterns
func check_for_shots():
	if holding_pistol and one_shooting:
		if bar_sixteenth in hat_pats[one_slot_current]: # LIGHT HATS
			shoot_play_closed_hihat()
	
	if holding_shotgun and two_shooting:
		if bar_sixteenth in snare_pats[two_slot_current]: # STANDARD OFFBEAT OPENHAT
			shoot_play_shotgun()
			
			
	if holding_right_fist and three_shooting:
		if bar_sixteenth in kick_pats[three_slot_current]: # STANDARD 4 4 KICK
			shoot_play_kick_punch()
		if bar_one_twenty_eighth in [63, 122, 123, 125, 127]: # 
			shoot_play_kick_punch()



func shoot_play_closed_hihat():
	one_hi_hat_hit.play()
	pistol_sprite_3d.play("shoot")
	if gun_ray.is_colliding() and gun_ray.get_collider().has_method("take_damage"):
		gun_ray.get_collider().take_damage(pistol_damage)
		print("hihathit")
		heal(.1)
	velocity *= 0.95
	#var temp_accel = accel
	#accel *= 0.5
	#await get_tree().create_timer(.1).timeout
	#accel = temp_accel


func shoot_play_shotgun():
	#open_hi_hat_hit.play()
	clap.play()
	shotgun_sprite_3d.play("shoot")
	
	#PUSHBACK
	# Calculate backward direction in local space
	var backward_direction = -global_transform.basis.z
	# Scale the backward direction to adjust the push force
	var push_force = backward_direction * 25
	# Apply the push force to the player's velocity
	velocity -= push_force
	
	#IF POINTING AT GROUND: (having trouble finding this)
	#var upward_direction = global_transform.basis.y
	#velocity += upward_direction * 15
	
	#damage target if hit
	if gun_ray.is_colliding() and gun_ray.get_collider().has_method("take_damage"): #THIS LINE gives "Attempt to call function 'has_method' in base 'null instance' on a null instance." when an enemy is killed while paused
		gun_ray.get_collider().take_damage(right_fist_damage)
		heal(.1)




func shoot_play_kick_punch():
	right_fist_sprite_3d.play("punch")
	one_kick_punch.play()
	
	#FORWARD MOMENTUM
	# Calculate backward direction in local space
	var backward_direction = -global_transform.basis.z
	# Scale the backward direction to adjust the push force
	var push_force = backward_direction * 15
	# Apply the push force to the player's velocity
	velocity += push_force
	
	
	if melee_ray.is_colliding() and melee_ray.get_collider().has_method("take_damage"):
		melee_ray.get_collider().take_damage(right_fist_damage)
		heal(.1)
		nudge_bass_cutoff_filter(-10)
		print("punch")
	velocity *= 0.8



#var bassfx = AudioServer.get_bus_index("bassfx")

# AUDIO FX SYSTEM
func nudge_bass_cutoff_filter(value):
	pass
	''' NOT WORKING. Consult godotdocs
	var bus_name = "bassfx"
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	# Assuming the filter effect is the first effect on the bus; adjust if necessary
	var effect_index = 0
	
	# Identify the parameter index for the cutoff frequency; this varies by effect type
	# For a LowPassFilter, 'cutoff_hz' might be the first parameter (index 0)
	var param_index = 0
	
	# Get the current value of the cutoff frequency
	var current_cutoff = AudioServer.get_bus_effect(bus_index, param_index)
	#get_bus_effect_parameter(bus_index, effect_index, param_index)
	
	# Calculate the new cutoff frequency by adding the provided value
	var new_cutoff = current_cutoff + value
	
	# Ensure the new cutoff frequency is within the acceptable range for the effect
	# This range varies by effect; you might need to look up the specific effect's documentation
	# For demonstration, assuming a general range of 20 to 22000 Hz for a low-pass filter
	new_cutoff = clamp(new_cutoff, 20, 22000)
	
	# Set the new cutoff frequency
	AudioServer.add_bus_effect(bus_index, effect_index, new_cutoff)
	#set_bus_effect(bus_index, effect_index, param_index, new_cutoff)
'''
















func exit_game():
	get_tree().quit()

func restart():
	get_tree().reload_current_scene()

func kill():
	dead = true
	$CanvasLayer/DeathScreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



func _on_restart_button_button_up():
	restart()
