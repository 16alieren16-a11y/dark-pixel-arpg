extends CharacterBody2D

@export var speed: float = 60.0
@export var wander_radius: float = 150.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var health_bar: ProgressBar = $HealthBar

var start_position: Vector2
var movement_direction: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_dead: bool = false # <--- Vampirin ölü olup olmadığını takip eden bayrak

var max_health: int = 100
var current_health: int = 100

func _ready() -> void:
	start_position = global_position
	choose_new_direction()
	
	health_bar.max_value = max_health
	health_bar.value = current_health

func _physics_process(delta: float) -> void:
	# Eğer öldüyse hiçbir fizik ve hareket kodu çalışmasın!
	if is_dead:
		return

	if is_moving:
		velocity = movement_direction * speed
		play_walk_animation()
		
		if global_position.distance_to(start_position) > wander_radius:
			movement_direction = (start_position - global_position).normalized()
	else:
		velocity = Vector2.ZERO
		play_idle_animation()

	move_and_slide()

func _on_timer_timeout() -> void:
	# Eğer öldüyse Timer yeni yön seçmesin
	if is_dead:
		return
	choose_new_direction()

func choose_new_direction() -> void:
	if is_dead:
		return
		
	if randf() > 0.5:
		is_moving = true
		movement_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	else:
		is_moving = false
		movement_direction = Vector2.ZERO
	
	if timer:
		timer.wait_time = randf_range(1.5, 3.5)

func play_walk_animation() -> void:
	if abs(movement_direction.x) > abs(movement_direction.y):
		if movement_direction.x < 0:
			animated_sprite.play("vampire_walk_left")
		else:
			animated_sprite.play("vampire_walk_right")
	else:
		if movement_direction.y < 0:
			animated_sprite.play("vampire_walk_up")
		else:
			animated_sprite.play("vampire_walk_down")

func play_idle_animation() -> void:
	var current_anim = animated_sprite.animation
	if "left" in current_anim:
		animated_sprite.play("vampire_idle_left")
	elif "right" in current_anim:
		animated_sprite.play("vampire_idle_right")
	elif "up" in current_anim:
		animated_sprite.play("vampire_idle_up")
	else:
		animated_sprite.play("vampire_idle_down")

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	current_health -= amount
	health_bar.value = current_health
	print("Vampir hasar aldı! Kalan can: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
		
	is_dead = true # Artık öldü olarak işaretliyoruz
	print("Vampir öldü!")
	
	# Timer'ı tamamen durduralım ki yeni yön seçmeye kalkmasın
	if timer:
		timer.stop()
		
	is_moving = false
	velocity = Vector2.ZERO
	
	if health_bar:
		health_bar.visible = false
	
	# Son baktığı yöne göre ölüm animasyonunu seçelim
	var death_anim = "vampire_death_down"
	var current_anim = animated_sprite.animation
	
	if "left" in current_anim:
		death_anim = "vampire_death_left"
	elif "right" in current_anim:
		death_anim = "vampire_death_right"
	elif "up" in current_anim:
		death_anim = "vampire_death_up"
	elif "down" in current_anim:
		death_anim = "vampire_death_down"
		
	animated_sprite.play(death_anim)
	
	if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
		animated_sprite.animation_finished.connect(_on_death_animation_finished)

func _on_death_animation_finished() -> void:
	if animated_sprite.animation.begins_with("vampire_death_"):
		queue_free()
