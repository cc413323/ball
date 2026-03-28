extends Node2D

var k: Array[int] = [1]
@onready var ball = get_parent().get_node("ball")
@onready var bot = get_parent().get_node("bot")
@onready var trainer = get_parent().get_node("trainer")
@onready var main = get_parent()
@onready var vector_to_ball_x:float = ball.position.x - trainer.position.x
@onready var vector_to_ball_y:float = ball.position.y - trainer.position.y
@onready var forward_x = trainer.direction
@onready var forward_y = trainer.direction
@onready var dot_forward_ball = (forward_x * vector_to_ball_x + forward_y * vector_to_ball_y) / main.distance
@onready var cross_forward_ball = forward_x * vector_to_ball_y - forward_y * vector_to_ball_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#clear()
	var distance = max(main.distance, 0.001)
	
	vector_to_ball_x = ball.position.x - trainer.position.x
	vector_to_ball_y = ball.position.y - trainer.position.y
	var vector_to_ball = Vector2(vector_to_ball_x, vector_to_ball_y)
	forward_x = trainer.direction.normalized().x
	forward_y = trainer.direction.normalized().y
	var forward = trainer.direction.normalized()
	dot_forward_ball = forward.dot(vector_to_ball.normalized())
	cross_forward_ball = forward.cross(vector_to_ball.normalized())
	
	if trainer.direction.length() > 0.1 or randf() < 0.03:
		save_game()
		


func save():
	var screen = get_viewport_rect().size  # screen width and height
	var half_w = screen.x / 2
	var half_h = screen.y / 2

	# normalize so 0 = left/top edge, 1 = right/bottom edge
	var fx = (trainer.global_position.x + half_w) / screen.x
	var fy = (trainer.global_position.y + half_h) / screen.y
	var save_dict = {
		"distance" : clamp(main.distance / 500.0, 0, 1),
		"dot_product": dot_forward_ball,
		"cross_product": cross_forward_ball,
		"dx": trainer.direction.normalized().x,
		"dy": trainer.direction.normalized().y,
		"fx": fx,
		"fy": fy
	}
	return save_dict

func clear():
	var save_file = FileAccess.open("user://train.save", FileAccess.WRITE)
	if save_file:
		save_file.close()
	else:
		print("Failed to clear train.save!")
		
func save_game():
	var save_file = FileAccess.open("user://train.save", FileAccess.READ_WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	save_file.seek_end()
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)
		
	save_file.close()
