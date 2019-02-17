var resource_common
var resource_uncommon
var resource_rare
var type_id

func _init(id, common_resource, uncommon_resource, rare_resource):
	type_id = id
	resource_common = common_resource
	resource_uncommon = uncommon_resource
	resource_rare = rare_resource

func get_random_resource():
	var r = randf()
	if r < .7:
		return resource_common
	elif r < .95:
		return resource_uncommon
	else:
		return resource_rare