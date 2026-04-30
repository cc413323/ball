extends Node2D

@onready var ball = get_node("ball")
@onready var bot = get_node("bot")
@onready var trainer = get_node("trainer")
# straight line distance between ball and bot
@onready var distance:float = ball.position.distance_to(trainer.position)
@onready var ball_scene:PackedScene = preload("res://scenes/ball.tscn")

# if true, clears existing data and starts updating the new data
var shouldTrain = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	distance = ball.position.distance_to(trainer.position)
	
	if Input.is_action_pressed("switchTrainSim"):
		shouldTrain = !shouldTrain
