
const SimpleBiome = preload("res://World/Map/TileTypes/SimpleBiome.gd")

const DESERT = 0
const OCEAN = 1
const FOREST = 2
const GRASSLANDS = 3
const TUNDRA = 4
const LAKE = 5
const MOUNTAIN = 6
const BORDER = 7

func register_tile_types(hashmap):
	hashmap[DESERT] = SimpleBiome.new(DESERT, "","wealth","food")
	hashmap[OCEAN] = SimpleBiome.new(OCEAN, "food","","wealth")
	hashmap[FOREST] = SimpleBiome.new(FOREST, "lumber","food","water")
	hashmap[GRASSLANDS] = SimpleBiome.new(GRASSLANDS, "food","food","")
	hashmap[TUNDRA] = SimpleBiome.new(TUNDRA, "water","food","lumber")
	hashmap[LAKE] = SimpleBiome.new(LAKE, "food","water","")
	hashmap[MOUNTAIN] = SimpleBiome.new(MOUNTAIN, "stone","ore","food")
	hashmap[BORDER] = SimpleBiome.new(BORDER, "","","")
