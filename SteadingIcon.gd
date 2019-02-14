extends Sprite

const BORDER_COLOR = Color("#222034")

const IMAGE_WIDTH = 19
const IMAGE_HEIGHT = 20

export(int, 360) var c1_min_h = 0
export(int, 360) var c1_max_h = 360
export(float, 1) var c1_min_s = 0
export(float, 1) var c1_max_s = 1
export(float, 1) var c1_min_l = 0
export(float, 1) var c1_max_l = 1

export(int, 0, 4) var steading_size = 4

var color

var image

var icon_width = 0
var icon_height = 0

func _ready():
	randomize()
	
	image = Image.new()
	image.create(IMAGE_WIDTH,IMAGE_HEIGHT,false,Image.FORMAT_RGBA8)
	
	generate()

func generate():
	image.lock()
	clear_image()
	if !color:
		randomColor()
	match steading_size:
		0:
			generate_ghost_steading()
		1:
			generate_village()
		2:
			generate_town()
		3:
			generate_keep()
		4:
			generate_city()
	image.unlock()
	texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	update()

func randomColor():
	color = hsl_to_rgba(random_hsl_color(c1_min_h, c1_max_h, c1_min_s, c1_max_s, c1_min_l, c1_max_l))


func generate_ghost_steading():
	print("GENERATE GHOST")
	icon_width = 7+2*(randi()%2)
	icon_height = 0
	for i in range(icon_width):
		var col_h = max(0, randi()%8-2)
		fill_box(i,icon_height,i+1,icon_height+col_h)

func generate_village():
	print("GENERATE VILLAGE")
	icon_width = 7+2*(randi()%2)
	icon_height = 2+randi()%5
	fill_base()
	fill_low_tri(ceil(icon_width/2), icon_height, ceil(icon_width/2)+1)

func generate_town():
	print("GENERATE TOWN")
	icon_width = 11+2*(randi()%2)
	icon_height = 4+randi()%4
	fill_base()
	# 0=low, 1=high, 2=tower
	var feature_right = randi()%3
	var feature_left = randi()%3
	var x_right = icon_width - randi()%2 - 1
	var x_left = randi()%2
	place_feature(feature_right, x_right, 0)
	place_feature(feature_left, x_left, 1)

func generate_keep():
	print("GENERATE KEEP")
	icon_width = 11+2*(randi()%2)
	icon_height = 4+randi()%5
	icon_width = 9+2*(randi()%2)
	icon_height = 3+randi()%3
	fill_base()
	# 0=low, 1=high, 2=tower
	var feature = randi()%3
	var feature_x = randi()%icon_width
	place_feature(feature, feature_x, 0 if feature_x+2>=icon_width else 1)
	crenellate()

func generate_city():
	print("GENERATE CITY")
	icon_width = 15+2*(randi()%3)
	icon_height = 4+randi()%3
	fill_base()
	for i in range(4):
		# 0=low, 1=high, 2=tower
		var feature = randi()%4
		if feature == 3:
			feature = 2 #prefer towers
		var feature_x = i*icon_width/4 + randi()%(icon_width/4)
		if feature != 2:
			 feature_x += -3 if i>1 else 3 # heavily center triangles
		place_feature(feature, feature_x, 0 if i>1 else 1)
	set_pixel(0,icon_height,color)
	set_pixel(icon_width-1,icon_height,color)
	

func place_feature(feature, x, left):
	match feature:
		0:
			if left==1:
				x+=2
			else:
				x-=2
			fill_low_tri(x, icon_height, 3)
		1:
			if left==1:
				x+=2
			else:
				x-=2
			fill_high_tri(x, icon_height, 3)
		2:
			if left==0:
				x-=1
			fill_box(x,icon_height, x+2, icon_height+2+randi()%3)

func crenellate():
	for x in range(0,icon_width,2):
		set_pixel(x,icon_height,color)

func fill_box(x1,y1,x2,y2):
	for x in range(x1,x2):
		for y in range(y1,y2):
			set_pixel(x,y,color)

func clear_image():
	var t = color
	color = Color(0,0,0,0)
	fill_box(0,0,IMAGE_WIDTH,IMAGE_HEIGHT)
	color = t
	
func fill_low_tri(base_x, base_y, height):
	for x in range(base_x-height, base_x+height):
		for y in range(abs(height - abs(x - base_x))):
			set_pixel(x,base_y+y,color)
			
func fill_high_tri(base_x, base_y, height):
	for x in range(base_x-height, base_x+height):
		for y in range(2*abs(height - abs(x - base_x))):
			set_pixel(x,base_y+y,color)

func fill_base():
	fill_box(0,0,icon_width,icon_height)

func set_pixel(x,y,c):
	image.set_pixel(x,IMAGE_HEIGHT-y-1,c)

func random_hsl_color(min_h, max_h, min_s, max_s, min_l, max_l):
	var span_h = max_h - min_h
	var span_s = max_s - min_s
	var span_l = max_l - min_l
	return Vector3(min_h+span_h*randf(), min_s+span_s*randf(), min_l+span_l*randf())
	

func hsl_to_rgba(hsl):
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
