extends CharacterBody2D  # or whatever your bot node is

# --- Config ---
var speed = 200.0
var A = []  # trained 5x2 matrix
var mean = []
var std = []
var json = JSON.new()

# reference to the ball node
@onready var ball = get_parent().get_node("ball")  # adjust path to your ball

func _ready():
	if FileAccess.file_exists("res://data/bot_model.json"):
		var file = FileAccess.open("res://data/bot_model.json", FileAccess.READ)
		var text = file.get_as_text()
		file.close()

		if json.parse(text) == OK:
			A = json.data["A"]
			mean = json.data["mean"]
			std = json.data["std"]
			print("Loaded model")
		else:
			push_error("Failed to parse JSON!")
	else:
		push_error("bot_model.json not found!")

# --- Compute input features ---
func compute_features(bot_pos: Vector2, bot_theta: float, ball_pos: Vector2) -> Array:
	var vector_to_ball = ball_pos - bot_pos
	var distance = clamp(vector_to_ball.length() / 500.0, 0, 1)

	var forward = Vector2(cos(bot_theta), sin(bot_theta))
	var dot_forward_ball = forward.dot(vector_to_ball.normalized())
	
	var cross_forward_ball = forward.cross(vector_to_ball.normalized())
	#var cross_forward_ball = forward.x * vector_to_ball.y - forward.y * vector_to_ball.x
	
	
	var screen = get_viewport_rect().size  # screen width and height
	var half_w = screen.x / 2
	var half_h = screen.y / 2
	# normalize so 0 = left/top edge, 1 = right/bottom edge
	var fx = (global_position.x + half_w) / screen.x
	var fy = (global_position.y + half_h) / screen.y
	
	return [distance, dot_forward_ball, cross_forward_ball,fx,fy]

# --- Predict movement ---
func predict_move(features: Array) -> Vector2:
	var norm = []
	for i in range(features.size()):
		norm.append((features[i] - mean[i]) / std[i])

	var dx = 0.0
	var dy = 0.0
	
	for i in range(5):
		dx += norm[i] * A[i][0]
		dy += norm[i] * A[i][1]

	return Vector2(dx, dy)

# --- Snap to 8 directions ---
func snap_8_directions(vec: Vector2) -> Vector2:
	if vec.length() == 0:
		return Vector2.ZERO
	var angle = vec.angle()
	var step = PI / 4
	var index = int(round(angle / step)) % 8
	var dirs = [
		Vector2(0,1), Vector2(0.707,0.707), Vector2(1,0), Vector2(0.707,-0.707),
		Vector2(0,-1), Vector2(-0.707,-0.707), Vector2(-1,0), Vector2(-0.707,0.707)
	]
	return dirs[index]

# --- Main movement loop ---
func _physics_process(delta):
	var features = compute_features(global_position, rotation, ball.global_position)
	if features[0] < 0.05:  # distance already normalized
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var move_vec = predict_move(features)
	if move_vec.length() < 0.2:
		move_vec = Vector2.ZERO
	#move_vec = snap_8_directions(move_vec)

	move_vec = move_vec.normalized() * speed

	# Set the velocity
	velocity = move_vec

	move_and_slide()  # NO arguments in Godot 4!
	
	var margin = 50
	var screen = get_viewport_rect().size

	if global_position.x < margin:
		move_vec.x += 1
	if global_position.x > screen.x - margin:
		move_vec.x -= 1
	if global_position.y < margin:
		move_vec.y += 1
	if global_position.y > screen.y - margin:
		move_vec.y -= 1
		
	if move_vec.length() < 0.1:
		move_vec = Vector2.ZERO
		
