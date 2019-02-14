extends "res://Entities/Steading.gd"

enum THREAT{
	Harmless,
	Insignificant,
	Caution,
	Serious,
	Deadly,
	Absurd,
	Extraordinary,
	Unprecedented
}
var threat = THREAT.Harmless

var dormant_rounds


func take_turn():
	if size == SIZE.Ghost:
		if dormant_rounds == -1:
			return #permadead
		dormant_rounds -= 1
		if dormant_rounds == 0:
			size = SIZE.Village
		else:
			return
	
	#try to do things
	_attempt_actions()
	
	_use_up_resources()
	
func die():
	size = SIZE.Ghost
	var r = randi()%6+1
	if threat == THREAT.Harmless && r == 1:
		dormant_rounds = -1
	else:
		dormant_rounds = r+threat


func release_wanderer():
	pass #release band of monsters