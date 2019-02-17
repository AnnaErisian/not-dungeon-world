
var items = []

func put(priority, value):
	var new = node.new(priority, value)
	for i in range(items.size()):
		var it = items[i]
		if it.priority > priority:
			items.insert(i, new)
			return
	items.append(new)
	

func get():
	var rv
	if ! items.empty():
		rv = items.pop_front()
	return rv.value

func size():
	return items.size()

func empty():
	return items.empty()

func iParent(i):
	return floor((i-1) / 2) # where floor functions map a real number to the smallest leading integer.
func iLeftChild(i):
	return 2*i + 1
func iRightChild(i):
	return 2*i + 2


class node:
	var priority
	var value
	func _init(p,v):
		priority = p
		value = v
