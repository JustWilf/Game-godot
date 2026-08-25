extends CharacterBody2D


@export_enum("Left", "Right") var direction: int = 0
@export var movement: bool = false
@export var jumping: bool = false
@export var running: bool = false
@export var dashing: bool = false
@export var sliding: bool = false
@export var dynamic_jump_height: bool = false
@export var double_jump: bool = false
@export var god_jump: bool = false
@export var max_fall_speed: float = 1000.0
@export var speed: float = 100.0
@export var jump_static_strength: float = 230.0
@export var jump_boost_strength: float = 8.0
@export var jump_boost_time: float = 0.25
@export var dash_strength: float = 250.0
@export var dash_coldown: float = 0.3
@export var dash_time: float = 0.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_stand: CollisionShape2D = $"CollisionShape2D-stand"
@onready var col_slide: CollisionShape2D = $"CollisionShape2D-slide"
@onready var camera: Camera2D = $Camera2D

var gravity: float = 600.0
var real_jump_boost_time: float
var cayot_limit: float
var can_dash: bool = false
var can_double_jump: bool = false
var real_dash_coldown: float

var jump_buffer_timer: float
var jump_timer: float
var cayot_timer: float
var dash_timer: float

var is_running: bool = false
var is_dashing: bool = false
var is_sliding: bool = false
var was_jump_pressed_in_frame: bool = false

func _ready() -> void:
	_set_camera_limit(0, -1000, 1078, 255)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if not is_dashing and not is_sliding:
		_direction()
	if movement and not is_dashing and not is_sliding:
		_movement()
	if jumping and not is_dashing and not is_sliding:
		_jumping(delta)
	if double_jump and not is_dashing and not is_sliding:
		_double_jump()
	if dashing and not is_sliding:
		_dashing(delta)
	
	_gravity(delta)
	move_and_slide()
	update_animation()

func _update_timers(delta: float) -> void:
	real_dash_coldown -= delta
	was_jump_pressed_in_frame = false
	if is_on_floor():
		cayot_timer = 0.0
		can_dash = true
		can_double_jump = true
	else:
		cayot_timer += delta
		jump_buffer_timer -= delta

func _direction() -> void:
	direction = 0 if velocity.x > 0 else 1 if velocity.x < 0 else direction
	sprite.flip_h = bool(direction)
	col_stand.position.x = -0.5 if direction else 1.5
	col_slide.position.x = 5.5 if direction else -5.5

func _movement() -> void:
	var move_koeff: float = 1.0
	if Input.is_action_pressed("run") and running:
		is_running = true
		move_koeff = 1.5 if velocity.y <= 0 else 1.2
	else:
		is_running = false
	velocity.x = speed * move_koeff * Input.get_axis("left", "right")

func _jumping(delta: float) -> void:
	real_jump_boost_time = jump_boost_time / 1.5 if is_running else jump_boost_time
	cayot_limit = 0.1 if is_running else 0.07
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.07
	if (god_jump and Input.is_action_just_pressed("jump")) or (cayot_timer <= cayot_limit and jump_buffer_timer >= 0.0):
		was_jump_pressed_in_frame = true
		cayot_timer += 1.0
		jump_buffer_timer -= 1.0
		jump_timer = 0.0
		velocity.y = -jump_static_strength if not god_jump else -jump_static_strength + gravity*0.8 * delta
	elif Input.is_action_pressed("jump") and dynamic_jump_height and can_double_jump:
		jump_timer += delta
		if jump_timer >= 0.117 and jump_timer <= real_jump_boost_time and velocity.y < 0:
			velocity.y -= (1.0 - clamp(jump_timer / real_jump_boost_time, 0.0, 1.0)) * jump_boost_strength * gravity * delta
	elif Input.is_action_just_released("jump") and can_double_jump:
		if jump_timer >= 0.117 and velocity.y < 0:
			velocity.y *= 0.8
		jump_timer += 1.0

func _dashing(delta: float) -> void:
	if Input.is_action_just_pressed("dash") and can_dash and real_dash_coldown <= 0.0:
		is_dashing = true
		can_dash = false
		real_dash_coldown = dash_coldown
		velocity.y = 0.0
		velocity.x = dash_strength * (-1.0 if direction else 1.0)
	if is_dashing:
		dash_timer += delta
	else:
		dash_timer = 0.0
	if dash_timer > dash_time:
		is_dashing = false

func _double_jump() -> void:
	if Input.is_action_just_pressed("jump") and can_double_jump and not was_jump_pressed_in_frame:
		can_double_jump = false
		velocity.y = -jump_static_strength

func _gravity(delta: float) -> void:
	if not is_dashing:
		velocity.y += gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)

func update_animation() -> void:
	if is_sliding:
		sprite.play("sliding")
	elif not is_on_floor():
		if velocity.y < 0.0:
			sprite.play("jump_static")
		#else:
			#sprite.play("fall")
	elif velocity.x != 0.0:
		sprite.play("walk" if not is_running else "run")
	else:
		sprite.play("idle")

func _set_camera_limit(left: int, top: int, right: int, bottom: int) -> void:
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom
	camera.reset_smoothing()
