#Tilemap uses "odd-q" in RBG terms
#Meaning it pushes odd columns half a row down

extends "res://World/Map/HexMap.gd"

var biomes = preload("res://World/Map/Biomes.gd")

const MAJOR_BIOME_SCALE = .04
const MINOR_BIOME_SCALE = .16


var softnoiseFactory = preload("res://scripts/softnoise.gd")
var land_noise
var major_biome_noise
var grassland_biome_noise
var tundra_biome_noise

var c1
var c2
var c3
var r1
var r2
var r3

func _ready():
	prepare_tile_types()
	randomize()
	land_noise = softnoiseFactory.SoftNoise.new(randi())
	major_biome_noise = softnoiseFactory.SoftNoise.new(randi())
	grassland_biome_noise = softnoiseFactory.SoftNoise.new(randi())
	tundra_biome_noise = softnoiseFactory.SoftNoise.new(randi())
	
	c1 = Vector3(size*sign(randf()-.5), 0, 0)
	c1.y = randf()*c1.x*-1
	c1.z = -c1.x-c1.y
	c1 *= 2.0
	r1 = size*40*(.8+.15*randf())
	c2 = Vector3(0, size*sign(randf()-.5), 0)
	c2.z = randf()*c2.y*-1
	c2.x = -c2.z-c2.y
	c2 *= 2.0
	r2 = size*40*(.8+.15*randf())
	c3 = Vector3(0, 0, size*sign(randf()-.5))
	c3.x = randf()*c3.z*-1
	c3.y = -c3.x-c3.z
	c3 *= 2.0
	r3 = size*40*(.8+.15*randf())

func prepare_tile_types():
	biomes.register_tile_types(tile_type_data)

var size = 20
var active_map_filling_var_i = -size
var active_map_filling_var_j = -size
var active_map_filling_var_k = -size
var done = false

func _process(delta):
	for i in range(10):
		if !done && progressIterators():
			var loc = axial_to_offset(Vector2(active_map_filling_var_i,active_map_filling_var_j))
			if get_cell(loc.x, loc.y) == -1:
				#print("%s %s | %s %s" % [active_map_filling_var_i, active_map_filling_var_j, loc.x, loc.y])
				var biome_type = getBiome(Vector2(active_map_filling_var_i,active_map_filling_var_j))
				set_cell(loc.x, loc.y, biome_type)
				update()

func progressIterators():
	var hit = false
	while(!hit):
		active_map_filling_var_k+=1
		if(active_map_filling_var_k>size):
			active_map_filling_var_k=-size
			active_map_filling_var_j+=1
			if(active_map_filling_var_j>size):
				active_map_filling_var_j=-size
				active_map_filling_var_i+=1
				if(active_map_filling_var_i>size):
					done=true
					setupSteadings()
					setupMerchants()
					return false
		hit = active_map_filling_var_i+active_map_filling_var_j+active_map_filling_var_k==0
	return true

func getBiome(axial):
	var x = axial.x
	var y = axial.y
	if isBorder(axial):
		return biomes.BORDER
	if isLand(x,y):
		var major_biome = getMajorBiome(x,y)
		if major_biome == biomes.GRASSLANDS:
			return getGrasslandsBiome(x,y)
		if major_biome == biomes.TUNDRA:
			return getTundraBiome(x,y)
		else:
			return major_biome
	else:
		return biomes.OCEAN

func isBorder(axial):
	return abs(axial.x) == size || abs(axial.y) == size || abs(-axial.y-axial.x) == size

func isLand(i,j):
	if axial_to_pixel(c1).distance_to(axial_to_pixel(Vector2(i,j))) < r1:
		return false
	if axial_to_pixel(c2).distance_to(axial_to_pixel(Vector2(i,j))) < r2:
		return false
	if axial_to_pixel(c3).distance_to(axial_to_pixel(Vector2(i,j))) < r3:
		return false
	return true
	
func isNearOcean(i,j):
	if axial_to_pixel(c1).distance_to(axial_to_pixel(Vector2(i,j))) < r1+80:
		return true
	if axial_to_pixel(c2).distance_to(axial_to_pixel(Vector2(i,j))) < r2+80:
		return true
	if axial_to_pixel(c3).distance_to(axial_to_pixel(Vector2(i,j))) < r3+80:
		return true
	return false

func getMajorBiome(x,y):
	var p = noise(major_biome_noise, MAJOR_BIOME_SCALE*x,MAJOR_BIOME_SCALE*y)
	if p < .3:
		return biomes.DESERT
	elif p < .7:
		return biomes.GRASSLANDS
	else:
		return biomes.TUNDRA

func getGrasslandsBiome(x,y):
	if isNearOcean(x,y):
		return biomes.GRASSLANDS
	var mp = noise(major_biome_noise, MAJOR_BIOME_SCALE*x,MAJOR_BIOME_SCALE*y)
	if mp < .35 || mp > .65:
		return biomes.GRASSLANDS
	var p = noise(grassland_biome_noise, MINOR_BIOME_SCALE*x,MINOR_BIOME_SCALE*y)
	if p < .1:
		return biomes.LAKE
	elif p < .75:
		return biomes.GRASSLANDS
	else:
		return biomes.FOREST
		
func getTundraBiome(x,y):
	if isNearOcean(x,y):
		return biomes.TUNDRA
	var mp = noise(major_biome_noise, MAJOR_BIOME_SCALE*x,MAJOR_BIOME_SCALE*y)
	if mp < .75:
		return biomes.TUNDRA
	var p = noise(tundra_biome_noise, MINOR_BIOME_SCALE*x,MINOR_BIOME_SCALE*y)
	if p < .08:
		return biomes.LAKE
	elif p < .75:
		return biomes.TUNDRA
	elif p < .95:
		return biomes.MOUNTAIN
	else:
		return biomes.FOREST

func noise(generator, x,y):
	return (generator.openSimplex2D(x,y)+sqrt(3)/2)/sqrt(3)

#
#       ENTITY PLACEMENT
#
func setupSteadings():
	var steadingScene = load("res://Entities/Steading.tscn")
	for r in range(1,size):
		var possible_cells = cube_ring(Vector3(0,0,0), r)
		var target = possible_cells[randi()%possible_cells.size()]
		var new_steading = steadingScene.instance()
		new_steading.position = axial_to_pixel(cube_to_axial(target))
		new_steading.size = new_steading.SIZE.City
		new_steading.prosperity = new_steading.PROSPERITY.Rich
		new_steading.population = new_steading.POPULATION.Booming
		$Steadings.add_child(new_steading)
		new_steading.update_icon()
		
func setupMerchants():
	var merchantScene = load("res://Entities/Wanderers/Merchant.tscn")
	for r in range(6,size*3):
		var possible_cells = cube_ring(Vector3(0,0,0), floor(r/5))
		var target = possible_cells[randi()%possible_cells.size()]
		var new_merchant = merchantScene.instance()
		new_merchant.position = axial_to_pixel(cube_to_axial(target))
		$Merchants.add_child(new_merchant)
		new_merchant.update_icon()

#
#        ENTITY MANAGEMENT
#
func get_steading_in_cell_pixel(pixel):
	var offset_coord = pixel_to_offset(pixel)
	return get_steading_in_cell_offset(offset_coord)
	
func get_steading_in_cell_cube(cube):
	var offset_coord = cube_to_offset(cube)
	return get_steading_in_cell_offset(offset_coord)

func get_steading_in_cell_offset(offset):
	for steading in $Steadings.get_children():
		var steading_offset = pixel_to_offset(steading.position)
		if steading_offset == offset:
			return steading
	return null
