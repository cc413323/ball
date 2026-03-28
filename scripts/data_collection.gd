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
	vector_to_ball_x = ball.position.x - trainer.position.x
	vector_to_ball_y = ball.position.y - trainer.position.y
	forward_x = trainer.direction.normalized().x
	forward_y = trainer.direction.normalized().y
	dot_forward_ball = (forward_x * vector_to_ball_x + forward_y * vector_to_ball_y) / main.distance
	cross_forward_ball = forward_x * vector_to_ball_y - forward_y * vector_to_ball_x
	#clear()
	#save_game()


func save():
	var save_dict = {
		"distance" : clamp(main.distance / 500.0, 0, 1),
		"dot_product": dot_forward_ball,
		"cross_product": cross_forward_ball,
		"dx": trainer.direction.x,
		"dy": trainer.direction.y
	}
	return save_dict

func clear():
	var save_file = FileAccess.open("user://train.save", FileAccess.WRITE)

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
