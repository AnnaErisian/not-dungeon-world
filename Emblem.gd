extends Sprite

const BORDER_COLOR = Color("#222034")

export(int, 360) var c1_min_h = 0
export(int, 360) var c1_max_h = 360
export(float, 1) var c1_min_s = 0
export(float, 1) var c1_max_s = 1
export(float, 1) var c1_min_l = 0
export(float, 1) var c1_max_l = 1
export(int, 360) var c2_min_h = 0
export(int, 360) var c2_max_h = 360
export(float, 1) var c2_min_s = 0
export(float, 1) var c2_max_s = 1
export(float, 1) var c2_min_l = 0
export(float, 1) var c2_max_l = 1
export(int, 360) var c3_min_h = 0
export(int, 360) var c3_max_h = 360
export(float, 1) var c3_min_s = 0
export(float, 1) var c3_max_s = 1
export(float, 1) var c3_min_l = 0
export(float, 1) var c3_max_l = 1

var c1
var c2
var c3
var image

func _ready():
	randomize()
	
	image = Image.new()
	image.create(10,10,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	
	generate()
	update()

#var counter = 0
#const DELAY = 1
#func _process(delta):
#	counter += delta
#	if(counter > DELAY):
#		counter = 0
#		generate()

func generate():
	image.lock()
	randomColors()
	var r = randf()
	if(r < .3):
		generate_top_left()
		mirror_l_r()
		mirror_t_b()
	else:
		generate_left()
		mirror_l_r()
	generate_border()
	image.unlock()
	texture = ImageTexture.new()
	texture.create_from_image(image, 0)

func randomColors():
	var hsl_1 = random_hsl_color(c1_min_h, c1_max_h, c1_min_s, c1_max_s, c1_min_l, c1_max_l)
	c1 = hsl_to_rgb(hsl_1)
	var hsl_2 = random_hsl_color(c2_min_h, c2_max_h, c2_min_s, c2_max_s, c2_min_l, c2_max_l)
	while hsl_color_dist(hsl_1, hsl_2) < 0.2:
		hsl_2 = random_hsl_color(c2_min_h, c2_max_h, c2_min_s, c2_max_s, c2_min_l, c2_max_l)
	c2 = hsl_to_rgb(hsl_2)
	var hsl_3 = random_hsl_color(c3_min_h, c3_max_h, c3_min_s, c3_max_s, c3_min_l, c3_max_l)
	while hsl_color_dist(hsl_1, hsl_3) < 0.2 &&  hsl_color_dist(hsl_2, hsl_3) < 0.2:
		hsl_2 = random_hsl_color(c2_min_h, c2_max_h, c2_min_s, c2_max_s, c2_min_l, c2_max_l)
	c3 = hsl_to_rgb(hsl_3)

func generate_left():
	var x = 1
	for y in [3,4,5,6]:
		set_random(x,y)
	x = 2
	for y in [2,3,4,5,6,7]:
		set_random(x,y)
	x = 3
	for y in [1,2,3,4,5,6,7,8]:
		set_random(x,y)
	x = 4
	for y in [1,2,3,4,5,6,7,8]:
		set_random(x,y)
		
func generate_top():
	var y = 1
	for x in [3,4,5,6]:
		set_random(x,y)
	y = 2
	for x in [2,3,4,5,6,7]:
		set_random(x,y)
	y = 3
	for x in [1,2,3,4,5,6,7,8]:
		set_random(x,y)
	y = 4
	for x in [1,2,3,4,5,6,7,8]:
		set_random(x,y)
		
func generate_top_left():
	var x = 1
	for y in [3,4]:
		set_random(x,y)
	x = 2
	for y in [2,3,4]:
		set_random(x,y)
	x = 3
	for y in [1,2,3,4]:
		set_random(x,y)
	x = 4
	for y in [1,2,3,4]:
		set_random(x,y)

func generate_border():
	var diags = [[1,2],[2,1],[7,1],[8,2],[2,8],[1,7],[7,8],[8,7]]
	for pair in diags:
		image.set_pixel(pair[0],pair[1],BORDER_COLOR)
	for y in [3,4,5,6]:
		image.set_pixel(0,y,BORDER_COLOR)
		image.set_pixel(9,y,BORDER_COLOR)
	for x in [3,4,5,6]:
		image.set_pixel(x,0,BORDER_COLOR)
		image.set_pixel(x,9,BORDER_COLOR)

func mirror_l_r():
	for x in range(0,5):
		for y in range(0,10):
			image.set_pixel(10-1-x,y,image.get_pixel(x,y))
			
func mirror_t_b():
	for x in range(0,10):
		for y in range(0,5):
			image.set_pixel(x,10-1-y,image.get_pixel(x,y))

func set_random(x,y):
	var r = randf()
	if(r < 0.333):
		image.set_pixel(x,y,c3)
	elif(r < 0.666):
		image.set_pixel(x,y,c2)
	else:
		image.set_pixel(x,y,c1)

func random_hsl_color(min_h, max_h, min_s, max_s, min_l, max_l):
	var span_h = max_h - min_h
	var span_s = max_s - min_s
	var span_l = max_l - min_l
	return Vector3(min_h+span_h*randf(), min_s+span_s*randf(), min_l+span_l*randf())
	

func hsl_to_rgb(hsl):
	var h = hsl.x
	var s = hsl.y
	var l = hsl.z
	var c = (1-abs(2*l-1))*s
	var h_prime = h/60.0
	var x = c * (1-abs((h_prime - 2 * floor(h_prime/2)) - 1))
	
	var pre_color
	
	if h_prime<=1:
		pre_color = Color(c,x,0)
	elif h_prime<=2:
		pre_color = Color(x,c,0)
	elif h_prime<=3:
		pre_color = Color(0,c,x)
	elif h_prime<=4:
		pre_color = Color(0,x,c)
	elif h_prime<=5:
		pre_color = Color(x,0,c)
	else:
		pre_color = Color(c,0,x)
	var m = l - c/2
	return Color(pre_color.r + m, pre_color.g + m, pre_color.b + m)

func hsl_color_dist(ca,cb):
	return Vector3(ca.x/255.0, ca.y, ca.z*3).distance_to(Vector3(cb.x/255.0, cb.y, cb.z*3))
