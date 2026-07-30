extends Control

var isOpen = false

func _ready() -> void:
	close()
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		if isOpen == true:
			close()
		else:
			open()

func open() -> void:
	visible = true
	isOpen = true


func close() -> void:
	visible = false
	isOpen = false
