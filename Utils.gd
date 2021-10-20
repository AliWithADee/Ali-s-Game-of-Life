extends Node

func choose(choises):
	randomize()
	var rand_index = randi() % choises.size()
	return choises[rand_index]

func create_timer(wait_time):
	var timer = Timer.new()
	timer.set_wait_time(wait_time)
	timer.set_one_shot(true)
	timer.connect("timeout", timer, "queue_free")
	add_child(timer)
	timer.start()
	return timer