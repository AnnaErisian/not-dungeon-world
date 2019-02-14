extends Node2D

var biomes = preload("res://World/Biomes.gd")

enum SIZE{
	Ghost,
	Village,
	Town,
	Keep,
	City
}
enum PROSPERITY{
	Dirt,
	Poor,
	Moderate,
	Wealthy,
	Rich
}
enum POPULATION{
	Exodus,
	Shrinking,
	Steady,
	Growing,
	Booming
}
enum DEFENSES{
	None,
	Militia,
	Watch,
	Guard,
	Garrison,
	Battalion,
	Legion
}

var size = SIZE.Ghost
var prosperity = PROSPERITY.Dirt
var population = POPULATION.Exodus
var defenses = DEFENSES.None
var tags = []

#resources
var food = 0
var lumber = 0
var stone = 0
var ore = 0

# Set to true when resources are not available for next turn
var lacking_resources = false

func _ready():
	update_icon()

func increase_size():
	match size:
		SIZE.Village:
			set_size(SIZE.Town)
		SIZE.Town:
			set_size(SIZE.City)
		SIZE.Keep:
			set_size(SIZE.City)
func decrease_size():
	match size:
		SIZE.City:
			set_size(SIZE.Town)
		SIZE.Keep:
			set_size(SIZE.Town)
		SIZE.Town:
			set_size(SIZE.Village)
		SIZE.Village:
			set_size(SIZE.Ghost)
func get_size():
	return size
func set_size(new_size):
	size = new_size
	update_icon()

func increase_prosperity():
	if prosperity < PROSPERITY.Rich:
		prosperity+=1
func decrease_prosperity():
	if prosperity > PROSPERITY.Dirt:
		prosperity-=1
func get_prosperity():
	return prosperity
		
func increase_population():
	if population < POPULATION.Booming:
		population+=1
func decrease_population():
	if population > POPULATION.Exodus:
		population-=1
func get_population():
	return population
		
func increase_defenses():
	if defenses < DEFENSES.None:
		defenses+=1
func decrease_defenses():
	if defenses > DEFENSES.Legion:
		defenses-=1
func get_defenses():
	return defenses

func gain_tag(tag):
	if ! tags.has(tag):
		tags.append(tag)
func has_tag(tag):
	return tags.has(tag)
func lose_tag(tag):
	if tags.has(tag):
		tags.erase(tag)

func roll_initiative():
	pass
func get_initiative():
	return 0;

func take_turn():
	print(to_string())
	if size == SIZE.Ghost:
		print("GHOST")
		return #We're dead, we do nothing
	
	#try to do things
	_attempt_actions()
	
	_use_up_resources()

func _attempt_actions():
	if(try_collapse()):
		print("COLLAPSE")
		return
	if(try_want()):
		print("WANT")
		return
	if(try_growth()):
		print("GROWTH")
		return
	if(try_profit()):
		print("PROFIT")
		return
	if(try_breed()):
		print("BREED")
		return
	if(try_create_wanderers()):
		print("CREATE WANDERERS")
		return
	if(try_fend()):
		print("FEND")
		return
	if(try_gather()):
		print("GATHER")
		return
	print("NOTHING?")

func _use_up_resources():
	var required_food = ceil(3.2*get_population())
	var required_material = ceil(1*get_size())
	#get our 'lacking' materials
	var food_need = required_food - food
	var building_material_need = required_material - (lumber+stone)
	var total_unmet_needs = 0
	# if we are lacking either type, note how much
	if food_need > 0:
		total_unmet_needs += food_need
	if building_material_need > 0:
		total_unmet_needs += building_material_need
	#prosperity lets us ignore some needs if we have people, but if they're too much we're in trouble
	if total_unmet_needs > min(get_prosperity(), get_population()):
		lacking_resources = true
	#reduce food, min 0
	food = max(0,food-required_food)
	#reduce lumber, then stone
	var remaining_building_need = required_material - lumber
	lumber = max(0,lumber-required_material)
	if remaining_building_need > 0:
		stone = max(0,stone-remaining_building_need)


func try_want():
	if lacking_resources:
		lacking_resources = false
		var r = randf()
		var held_losable_tags = []
		if has_tag("Guild"):
			held_losable_tags.append("Guild")
		if has_tag("Craft"):
			held_losable_tags.append("Craft")
		if has_tag("Market"):
			held_losable_tags.append("Market")
		if r < .4 && held_losable_tags.size() > 0:
			lose_tag(held_losable_tags[randi()%held_losable_tags.size()])
		elif r < .6:
			decrease_prosperity()
		else:
			decrease_population()
			release_caravan()
		return true
	else:
		return false
		
func try_growth():
	if get_population()==POPULATION.Booming && get_size() < SIZE.Keep && get_prosperity() >= PROSPERITY.Moderate:
		population = 3
		increase_size()
		decrease_prosperity()
		decrease_defenses()
		gain_tag("Market")
		gain_tag("Guild")
		return true
	else:
		return false
		
func try_collapse():
	if get_population()==POPULATION.Exodus && get_prosperity() <= PROSPERITY.Poor:
		population = 3
		match get_size():
			SIZE.City:
				set_size(SIZE.Town)
				increase_prosperity()
			SIZE.Keep:
				set_size(SIZE.Town)
				increase_defenses()
			SIZE.Town:
				set_size(SIZE.Village)
				increase_prosperity()
			SIZE.Village:
				die()
		return true
	else:
		return false

func try_profit():
	if get_prosperity() == PROSPERITY.Rich:
		return false
	if get_resource_total() > 3 * get_prosperity():
		increase_prosperity()
		return true
	else:
		return false

func try_breed():
	if get_population() == POPULATION.Booming:
		return false
	if get_prosperity() > get_population() && get_resource_total() > 3 * get_prosperity():
		increase_population()
		return true
	else:
		return false

func try_create_wanderers():
	pass
	#NOTYET: Adventurers are backburner for now
	#if no adventurers within 2 hexes
	#create a random party
	#later tags will influence spawned adventurers, but not yet

func try_fend():
	pass
	#NOTYET: Monsters are backburner for now
	#if there's a band of monsters in this cell, damage a number of monsters equal to size for damage equal to defenses

func try_gather():
	#gather random resources based on size+population from own+surrounding cells
	var tilemap = get_parent().get_parent()
	var pos_cube = tilemap.pixel_to_cube(position)
	var surroundings = tilemap.cube_spiral(pos_cube, 1)
	for i in range(get_population()*get_size()):
		gather_resources(tilemap, surroundings[randi()%surroundings.size()])
	return true

func gather_resources(tilemap, cube_tile):
	var tile_type = tilemap.cube_get_cell(cube_tile)
	var resource_type = biomes.gather_resource(tile_type)
	match resource_type:
		biomes.FOOD:
			food += 1
		biomes.LUMBER:
			lumber += 1
		biomes.WATER:
			pass #not useful yet
		biomes.STONE:
			stone += 1
		biomes.ORE:
			pass #not useful yet
		biomes.WEALTH:
			pass #not useful yet


func get_resource_total():
	return food+lumber+ore+stone
		
		
		
		
		
		
		
		
func release_caravan():
	pass

func release_wanderer():
	pass #release advendurers

func die():
	set_size(SIZE.Ghost)

func update_icon():
	$SteadingIcon.steading_size = get_size()
	$SteadingIcon.generate()
	var new_width = $SteadingIcon.icon_width
	$SteadingIcon.position.x = -(new_width/2.0)+2

func to_string():
	return "Size: %s, Pros: %s, Pop: %s, Def: %s\n Food: %s, Lumber: %s, Stone: %s" % \
		[get_size(), get_prosperity(), get_population(), get_defenses(), food, lumber, stone]