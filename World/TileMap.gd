#Tilemap uses "odd-q" in RBG terms
#Meaning it pushes odd columns half a row down

extends TileMap

const BIOME_DESERT = 0
const BIOME_OCEAN = 1
const BIOME_FOREST = 2
const BIOME_GRASSLANDS = 3
const BIOME_TUNDRA = 4
const BIOME_LAKE = 5
const BIOME_MOUNTAIN = 6
const BIOME_BORDER = 7

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

var size = 60
var active_map_filling_var_i = -size
var active_map_filling_var_j = -size
var active_map_filling_var_k = -size
var done = false

func _process(delta):
	for i in range(10):
		if !done && progressIterators():
			var loc = axial_to_grid(active_map_filling_var_i,active_map_filling_var_j)
			if get_cell(loc.x, loc.y) == -1:
				set_cell(loc.x, loc.y, getBiome(active_map_filling_var_i,active_map_filling_var_j))
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
					return false
		hit = active_map_filling_var_i+active_map_filling_var_j+active_map_filling_var_k==0
	return true

func getBiome(x,y):
	if isBorder(x, y):
		return BIOME_BORDER
	if isLand(x,y):
		var major_biome = getMajorBiome(x,y)
		if major_biome == BIOME_GRASSLANDS:
			return getGrasslandsBiome(x,y)
		if major_biome == BIOME_TUNDRA:
			return getTundraBiome(x,y)
		else:
			return major_biome
	else:
		return BIOME_OCEAN

func isBorder(x,y):
	return abs(x) == size || abs(y) == size || abs(-y-x) == size

func isLand(i,j):
	if hex_to_pixel(c1.x,c1.y).distance_to(hex_to_pixel(i,j)) < r1:
		return false
	if hex_to_pixel(c2.x,c2.y).distance_to(hex_to_pixel(i,j)) < r2:
		return false
	if hex_to_pixel(c3.x,c3.y).distance_to(hex_to_pixel(i,j)) < r3:
		return false
	return true
	
func isNearOcean(i,j):
	if hex_to_pixel(c1.x,c1.y).distance_to(hex_to_pixel(i,j)) < r1+80:
		return true
	if hex_to_pixel(c2.x,c2.y).distance_to(hex_to_pixel(i,j)) < r2+80:
		return true
	if hex_to_pixel(c3.x,c3.y).distance_to(hex_to_pixel(i,j)) < r3+80:
		return true
	return false

func getMajorBiome(x,y):
	var p = noise(major_biome_noise, MAJOR_BIOME_SCALE*x,MAJOR_BIOME_SCALE*y)
	if p < .3:
		return BIOME_DESERT
	elif p < .7:
		return BIOME_GRASSLANDS
	else:
		return BIOME_TUNDRA

func getGrasslandsBiome(x,y):
	if isNearOcean(x,y):
		return BIOME_GRASSLANDS
	var mp = noise(major_biome_noise, MAJOR_BIOME_SCALE*x,MAJOR_BIOME_SCALE*y)
	if mp < .35 || mp > .65:
		return BIOME_GRASSLANDS
	var p = noise(grassland_biome_noise, MINOR_BIOME_SCALE*x,MINOR_BIOME_SCALE*y)
	if p < .1:
		return BIOME_LAKE
	elif p < .75:
		return BIOME_GRASSLANDS
	else:
		return BIOME_FOREST
		
func getTundraBiome(x,y):
	if isNearOcean(x,y):
		return BIOME_TUNDRA
	var mp = noise(major_biome_noise, MAJOR_BIOME_SCALE*x,MAJOR_BIOME_SCALE*y)
	if mp < .75:
		return BIOME_TUNDRA
	var p = noise(tundra_biome_noise, MINOR_BIOME_SCALE*x,MINOR_BIOME_SCALE*y)
	if p < .08:
		return BIOME_LAKE
	elif p < .75:
		return BIOME_TUNDRA
	elif p < .95:
		return BIOME_MOUNTAIN
	else:
		return BIOME_FOREST

func noise(generator, x,y):
	return (generator.openSimplex2D(x,y)+sqrt(3)/2)/sqrt(3)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func axial_to_grid(x,y):
	var col = x
	var row = -x-y + (x - (x&1)) / 2
	return Vector2(col, row)
	
func hex_to_pixel(i, j):
    var x = (23 * i)
    var y = (15 * i  +  30 * j)
    return Vector2(x, y)