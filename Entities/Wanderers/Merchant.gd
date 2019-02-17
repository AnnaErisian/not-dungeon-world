extends Node2D

const DEBUG = false

var biomes = preload("res://World/Map/Biomes.gd")

#dict of Steadings to arrays of needed resources
var known_steading_needs = {}

#active path to steading we want to trade with
var active_path = null

var world

#resources
var food = 0
var lumber = 0
var stone = 0
var ore = 0
var water = 0
var wealth = 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	world = get_node("../..")

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func take_turn():
	if DEBUG:
		print("---------------");
	register_steading()
	gather()
	if active_path != null:
		follow_active_path()
	else:
		trade_with_steading()
		var target_steading = get_steading_we_can_trade_to()
		if target_steading != null:
			go_to_steading(target_steading)
		else:
			wander()

func register_steading():
	var steading_in_cell = world.get_steading_in_cell_pixel(position)
	if steading_in_cell == null:
		return
	known_steading_needs[steading_in_cell] = steading_in_cell.get_most_needed_resource()
	if DEBUG:
		print("register steading")

func gather():
	var cube_tile = world.pixel_to_cube(position)
	var biome_data = world.cube_get_cell_data(cube_tile)
	var resource_type = biome_data.get_random_resource()
	match resource_type:
		"food":
			food += 1
		"lumber":
			lumber += 1
		"water":
			pass #not useful yet
		"stone":
			stone += 1
		"ore":
			pass #not useful yet
		"wealth":
			pass #not useful yet

func trade_with_steading():
	var steading_in_cell = world.get_steading_in_cell_pixel(position)
	if steading_in_cell == null:
		return
	if DEBUG:
		print("trade with steading")
	steading_in_cell.food += food
	steading_in_cell.lumber += lumber
	steading_in_cell.stone += stone
	steading_in_cell.ore += ore
	steading_in_cell.water += water
	steading_in_cell.wealth += wealth
	food = 0
	lumber = 0
	stone = 0
	ore = 0
	water = 0
	wealth = 0

func get_steading_we_can_trade_to():
	if DEBUG:
		print("get_tradeable_steading")
	for steading in known_steading_needs:
		var needed_resource = known_steading_needs[steading]
		match needed_resource:
			"food":
				if food > 20:
					return steading
			"lumber":
				if lumber > 20:
					return steading
			"stone":
				if stone > 20:
					return steading
			"ore":
				if ore > 20:
					return steading
			"wealth":
				if water > 20:
					return steading
	return null

func go_to_steading(steading):
	if DEBUG:
		print("go to steading")
	#since there's no barriers to movement I can just do this one square at a time thankfully
	var cube_loc = world.pixel_to_cube(position)
	var cube_dest = world.pixel_to_cube(steading.position)
	active_path = world.path_to_pixel(world.find_path(cube_loc, cube_dest))
	follow_active_path()

func follow_active_path():
	if DEBUG:
		print("follow active path")
	var tween = get_node("Tween")
	tween.interpolate_property(self, "position", \
                position, active_path.pop_front(), .95 * get_tree().get_root().get_node("Root/TurnTimer").wait_time, \
                Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	if active_path.empty():
		active_path = null

func wander():
	if DEBUG:
		print("wander")
	var cube_loc = world.pixel_to_cube(position)
	var options = world.cube_ring(cube_loc, 1)
	var real_options = []
	var preferred_option = null
	for option in options:
		if world.cube_get_cell_data(option).type_id != biomes.BORDER:
			real_options.append(option)
			var possible_steading = world.get_steading_in_cell_cube(option)
			if possible_steading != null:
				if !known_steading_needs.keys().has(possible_steading):
					preferred_option = option
	if preferred_option == null:
		active_path = [world.cube_to_pixel(real_options[randi() % real_options.size()])]
	else:
		active_path = [world.cube_to_pixel(preferred_option)]
	follow_active_path()
	

func update_icon():
	$Emblem.generate()
