extends Node2D

signal move_camera_left()
signal move_camera_right()
signal can_respawn1()
signal can_respawn2()

func _ready():
	$Detector1.monitoring = false
	$Detector2.monitoring = false
	$Detector3.monitoring = false
	$Detector4.monitoring = false


func _on_passage_left_right():
	print("Passage left right")
	$GateLeft.open()
	$GateRight.open()
	$Detector3.monitoring = true
	$Detector4.monitoring = true


func _on_passage_right_left():
	print("Passage right left")
	$GateLeft.open()
	$GateRight.open()
	$Detector1.monitoring = true
	$Detector2.monitoring = true


func _on_detector1_entered(body):
	print("Detector1 triggered by: ", body, " type: ", typeof(body))
	if body.is_in_group("player"):
		print("Detector 1 entered")
		$Detector1.set_deferred("monitoring", false)
		$GateLeft.close()
		emit_signal("can_respawn1")


func _on_detector2_entered(body):
	print("Detector1 triggered by: ", body, " type: ", typeof(body))
	
	if body.is_in_group("player"):
		print("Detector 2 entered")
		$Detector2.set_deferred("monitoring", false)
		$GateRight.close()
		emit_signal("move_camera_left")


func _on_detector3_entered(body):
	print("Detector1 triggered by: ", body, " type: ", typeof(body))
	
	if body.is_in_group("player"):
		print("Detector 3 entered")
		$Detector3.set_deferred("monitoring", false)
		$GateLeft.close()
		emit_signal("move_camera_right")


func _on_detector4_entered(body):
	print("Detector1 triggered by: ", body, " type: ", typeof(body))
	
	if body.is_in_group("player"):
		print("Detector 4 entered")
		$Detector4.set_deferred("monitoring", false)
		$GateRight.close()
		#respawn dead player
		emit_signal("can_respawn2")
		
