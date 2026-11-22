extends CharacterBody2D

@export var speed := 95.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var state_machine = get_node_or_null("statemachine")
	if state_machine:
		state_machine.queue_free()
var facing := Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("walk left", "walk right", "walk up", "walk down")
	if input_dir.length() > 0.0:
		facing = input_dir.normalized()
		velocity = input_dir.normalized() * speed
		move_and_slide()
		_play_walk()
	else:
		velocity = Vector2.ZERO
		_play_idle()

func _play_walk() -> void:
	if abs(facing.x) > abs(facing.y):
		sprite.play("walk_right" if facing.x > 0 else "walk_left")
	else:
		sprite.play("walk_front" if facing.y > 0 else "walk back")

func _play_idle() -> void:
	if abs(facing.x) > abs(facing.y):
		sprite.play("idle_right" if facing.x > 0 else "idle_left")
	else:
		sprite.play("idle_front" if facing.y > 0 else "idle_back")
