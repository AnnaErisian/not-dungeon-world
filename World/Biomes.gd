
const DESERT = 0
const OCEAN = 1
const FOREST = 2
const GRASSLANDS = 3
const TUNDRA = 4
const LAKE = 5
const MOUNTAIN = 6
const BORDER = 7

const NONE = -1
const FOOD = 0
const LUMBER = 1
const WATER = 2
const STONE = 3
const ORE = 4
const WEALTH = 5

const resourceTypes = {DESERT: [-1,5,0], OCEAN: [0,-1,5], FOREST: [1,0,2], GRASSLANDS: [0,0,-1], TUNDRA: [2,0,1], LAKE: [0,2,-1], MOUNTAIN: [2,4,0], BORDER: [-1,-1,-1]}

static func gather_resource(biome_id):
	var possibilities = resourceTypes[biome_id]
	var r = randf()
	if(r<.7):
		return possibilities[0]
	elif(r<.95):
		return possibilities[1]
	else:
		return possibilities[2]