#Tilemap uses "odd-q" in RBG terms
#Meaning it pushes odd columns half a row down

extends TileMap

var biomes = preload("res://World/Biomes.gd")
var PriorityQueue = preload("res://scripts/PriorityQueue.gd")

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
				set_cell(loc.x, loc.y, getBiome(Vector2(active_map_filling_var_i,active_map_filling_var_j)))
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

#
#        PATHFINDING
#

#Both arguments are cube coordinates
func find_path(start,goal):
	var frontier = PriorityQueue.new()
	frontier.put(0, start)
	var came_from = {}
	var cost_so_far = {}
	came_from[start] = null
	cost_so_far[start] = 0
	
	while not frontier.empty():
		var current = frontier.get()
		
		if current == goal:
			break
		
		for next in get_neighbors(current):
			var new_cost = cost_so_far[current] + 0 # nothing special for now graph.cost(current, next)
			if !cost_so_far.has(next) or new_cost < cost_so_far[next]:
				cost_so_far[next] = new_cost
				var priority = new_cost + heuristic(goal, next)
				frontier.put(priority, next)
				came_from[next] = current
	
	var current = goal 
	var path = []
	while current != start: 
	   path.append(current)
	   current = came_from[current]
	path.invert()
	return path

func path_to_axial(path):
	var npath = []
	for p in path:
		npath.append(Vector2(p.x, p.y))
	return npath

func path_to_pixel(path):
	var npath = []
	for p in path:
		npath.append(cube_to_pixel(p))
	return npath

func get_neighbors(cube):
	return cube_ring(cube,1)

#both cubic
func heuristic(goal,cell):
	return cube_distance(goal,cell)

#
#        HEX GRID OPERATIONS
#

var cube_directions = [
    Vector3(+1, -1, 0), Vector3(+1, 0, -1), Vector3(0, +1, -1), 
    Vector3(-1, +1, 0), Vector3(-1, 0, +1), Vector3(0, -1, +1), 
]
func cube_direction(direction):
    return cube_directions[direction]
	
func cube_neighbor(cube, direction):
    return cube + cube_direction(direction)

func cube_ring(center, radius):
    var results = []
    # this code doesn't work for radius == 0; can you see why?
    var cube = center + cube_scale(cube_direction(4), radius)
    for i in range(6):
        for j in range(radius):
            results.append(cube)
            cube = cube_neighbor(cube, i)
    return results

func cube_scale(cube, magnitude):
	return cube * magnitude

func cube_spiral(center, radius):
    var results = [center]
    for k in range(1,radius+1):
        results = results + cube_ring(center, k)
    return results

func axial_to_offset(axial):
	var col = axial.x
	var row = -axial.x-axial.y + (axial.x + (int(axial.x)&1)) / 2
	return Vector2(col, -row)
	
func axial_to_pixel(axial):
    var x = (23 * axial.x)+23
    var y = (15 * axial.x  +  30 * axial.y)+15
    return Vector2(x, y)
	
func cube_to_pixel(axial):
    return axial_to_pixel(cube_to_axial(axial))

func pixel_to_axial(pos):
	var q = (pos.x+7.5-23)/23.0
	var r = (pos.x+7.5-23)/-46.0 + (pos.y-1-15) / 30.0
	return axial_round(Vector2(q,r))

func pixel_to_cube(pos):
	var axial = pixel_to_axial(pos)
	return Vector3(axial.x, axial.y, -axial.x-axial.y)

func axial_round(axial):
    return cube_to_axial(cube_round(axial_to_cube(axial)))

func axial_to_cube(axial):
	return Vector3(axial.x,axial.y,0-axial.x-axial.y)

func cube_to_axial(cube):
	return Vector2(cube.x,cube.y)

func cube_to_offset(cube):
	return axial_to_offset(cube_to_axial(cube))
	
func cube_round(cube):
	var rx = round(cube.x)
	var ry = round(cube.y)
	var rz = round(cube.z)
	
	var x_diff = abs(rx - cube.x)
	var y_diff = abs(ry - cube.y)
	var z_diff = abs(rz - cube.z)
	
	if x_diff > y_diff and x_diff > z_diff:
		 rx = -ry-rz
	elif y_diff > z_diff:
		ry = -rx-rz
	else:
		rz = -rx-ry
	
	return Vector3(rx, ry, rz)

func pixel_to_offset(pos):
	return axial_to_offset(pixel_to_axial(pos))
	
func cube_get_cell(cube):
	var offset = cube_to_offset(cube)
	return get_cell(offset.x, offset.y)

func cube_distance(a, b):
	return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2