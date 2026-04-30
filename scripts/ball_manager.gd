extends Node2D

var active_ball:Node2D = null
var ball_scene = preload("res://scenes/ball.tscn")
# angle of where ball is facing relative to world 0-2pi
@onready var screen_size = get_viewport_rect().size
@onready var trainer = get_parent().get_node("trainer")
@onready var ball = get_parent().get_node("ball")
@onready var bot = get_parent().get_node("bot")

var direction: Vector2 = Vector2.ZERO
var speed: float = 500
var moving_along_edge: bool = true

func _ready():
	# start at a random edge
	place_ball_at_random_edge()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	ball.position += direction * speed * delta

	if is_offscreen(ball.position):
		place_ball_at_random_edge()

	# pick random edge for a camera-centered screen
func place_ball_at_random_edge():
	var screen_size = get_viewport_rect().size / 2  # half-width / half-height
	var side = randi() % 4

	match side:
		0: ball.position = Vector2(randf() * screen_size.x * 2 - screen_size.x, screen_size.y)      # top
		1: ball.position = Vector2(randf() * screen_size.x * 2 - screen_size.x, -screen_size.y)     # bottom
		2: ball.position = Vector2(-screen_size.x, randf() * screen_size.y * 2 - screen_size.y)     # left
		3: ball.position = Vector2(screen_size.x, randf() * screen_size.y * 2 - screen_size.y)      # right

	# aim directly at trainer
	if $"..".shouldTrain:
		direction = (trainer.position - ball.position).normalized()
	else:
		direction = (bot.position - ball.position).normalized()

	# check if offscreen for camera-centered coordinates
func is_offscreen(pos: Vector2) -> bool:
	var s = get_viewport_rect().size / 2
	return pos.x < -s.x or pos.x > s.x or pos.y < -s.y or pos.y > s.y
