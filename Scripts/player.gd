extends CharacterBody2D


@export_enum("Right", "Left") var direction: int = 0
@export var movement: bool = true
@export var jumping: bool = true
@export var dynamic_jump_height: bool = false
@export var god_jump: bool = false
@export var speed: float = 100.0
@export var jump_static_strength: float = 200.0
@export var jump_boost_strength: float = 2.0
@export var jump_boost_time: float = 0.5

var gravity: float = 600.0
var jump_buffer_timer: float
var jump_timer: float
var cayot_timer: float
var sprite: Sprite2D


func _ready() -> void:
	sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_direction()
	if movement:
		_movement()
	if jumping:
		_jumping(delta)
	
	_gravity(delta)
	move_and_slide()

func _update_timers(delta: float) -> void:
	if is_on_floor():
		cayot_timer = 0.0
	else:
		cayot_timer += delta
		jump_buffer_timer -= delta

func _direction() -> void:
	direction = 1 if velocity.x < 0 else 0 if velocity.x < 0 else direction
	sprite.flip_h = bool(direction)

func _movement() -> void:
	velocity.x = speed * Input.get_axis("left", "right")

func _jumping(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.1
	if god_jump or cayot_timer <= 0.07 and jump_buffer_timer >= 0.0:
		cayot_timer += 1.0
		jump_buffer_timer -= 1.0
		jump_timer = 0.0
		velocity.y -= jump_static_strength
	elif Input.is_action_pressed("jump") and dynamic_jump_height:
		jump_timer += delta
		if jump_timer >= 0.117 and jump_timer <= jump_boost_time and velocity.y < 0:
			velocity.y -= (1.0 - clamp(jump_timer / jump_boost_time, 0.0, 1.0)) * jump_boost_strength * gravity * delta
	elif Input.is_action_just_released("jump"):
		if jump_timer >= 0.117 and velocity.y < 0:
			velocity.y *= 0.8
		jump_timer += 1.0

func _gravity(delta: float) -> void:
	velocity.y += gravity * delta
