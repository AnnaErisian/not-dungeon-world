extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _process():
	print($TurnTimer.time_left)

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:  # Mouse button down.
			var mouse_last_location = $Terrain.get_global_mouse_position() - $Terrain.position
			var cell = $Terrain.pixel_to_offset(mouse_last_location)
			print(cell)
			print($Terrain.get_cell(cell.x, cell.y))

func _on_TurnTimer_timeout():
	for x in $Terrain/Steadings.get_children():
		x.take_turn()
	for x in $Terrain/Merchants.get_children():
		x.take_turn()