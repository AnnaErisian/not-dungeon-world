extends TileMap

var PriorityQueue = preload("res://scripts/PriorityQueue.gd")

#int to anything
#represents the data attached to each type of tile
var tile_type_data = {}

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
	
func cube_get_cell_data(cube):
	var offset = cube_to_offset(cube)
	return tile_type_data[get_cell(offset.x, offset.y)]

func cube_distance(a, b):
	return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2