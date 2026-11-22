extends CharacterBody2D

@export var speed := 95.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := Vector2.DOWN
var walk_sound := AudioStreamPlayer.new()
var frozen := false

# Called by farm_game.gd (intro, fades, sleeping) to stop the player moving.
func set_frozen(value: bool) -> void:
	frozen = value
	if frozen:
		velocity = Vector2.ZERO
		walk_sound.stop()
		if sprite:
			_play_idle()

func _ready() -> void:
	# The old state machine is not used by this controller.
	var state_machine = get_node_or_null("statemachine")
	if state_machine:
		state_machine.queue_free()
	# Footstep loop: plays only while the player is moving.
	var stream := load("res://Audio/walking.mp3") as AudioStreamMP3
	if stream:
		stream.loop = true
		walk_sound.stream = stream
	add_child(walk_sound)

func _physics_process(_delta: float) -> void:
	if frozen:
		return
	var input_dir := Input.get_vector("walk left", "walk right", "walk up", "walk down")
	if input_dir.length() > 0.0:
		facing = input_dir.normalized()
		velocity = input_dir.normalized() * speed
		move_and_slide()
		_play_walk()
		if walk_sound.stream and not walk_sound.playing:
			walk_sound.play()
	else:
		velocity = Vector2.ZERO
		_play_idle()
		if walk_sound.playing:
			walk_sound.stop()

func _play_walk() -> void:
	if abs(facing.x) > abs(facing.y):
		sprite.play("walk_right" if facing.x > 0 else "walk_left")
	else:
		sprite.play("walk_front" if facing.y > 0 else "walk_back")

func _play_idle() -> void:
	if abs(facing.x) > abs(facing.y):
		sprite.play("idle_right" if facing.x > 0 else "idle_left")
	else:
		sprite.play("idle_front" if facing.y > 0 else "idle_back")
