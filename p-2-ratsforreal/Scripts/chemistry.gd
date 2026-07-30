extends Resource

var rust_ : int
var bleach : int
var extinguisher : int

var tree_fluid : int

func _process(delta):
	if Input.is_action_just_pressed("mix"):
		if (rust_ >= 2) && (bleach >= 1) && (extinguisher >= 5):
			rust_ -= 2
			bleach -= 1
			extinguisher -= 5
			tree_fluid += 1
