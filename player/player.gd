extends CharacterBody2D

@export var speed: float = 200.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Vuruş alanını ve içindeki collision'ı koda bağlıyoruz
@onready var weapon_hitbox: Area2D = $WeaponHitBox
@onready var hitbox_collision: CollisionShape2D = $WeaponHitBox/CollisionShape2D

var last_dir: String = "down"
var is_attacking: bool = false

func _ready() -> void:
	if hitbox_collision:
		hitbox_collision.disabled = true

func _physics_process(delta: float) -> void:
	# 1. Fare Yönüne Göre Bakış Açısını Belirleme
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	# Fareye göre yönü (up, down, left, right) ve hitbox pozisyonunu güncelleyelim
	update_facing_direction(direction_to_mouse)

	# 2. Saldırı Girdisi (Sol Tık - "attack" input action)
	if Input.is_action_pressed("attack"):
		start_attack()
	else:
		if is_attacking:
			stop_attack()

	# 3. Hareket Girdileri (WASD) - Artık saldırırken durmuyor, hareketle saldırı birleşebiliyor
	var movement_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if movement_vector != Vector2.ZERO:
		velocity = movement_vector * speed
		# Eğer saldırmıyorsak koşu animasyonunu oynat
		if not is_attacking:
			play_run_animation(movement_vector)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)
		# Eğer saldırmıyorsak idle animasyonunu oynat
		if not is_attacking:
			animated_sprite.play("idle_" + last_dir)

	move_and_slide()

# Fare yönüne göre karakterin hangi yöne baktığını ve hitbox'ın nereye konacağını seçer
func update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		if dir.x < 0:
			last_dir = "left"
			if weapon_hitbox: weapon_hitbox.position = Vector2(-20, 0)
		else:
			last_dir = "right"
			if weapon_hitbox: weapon_hitbox.position = Vector2(20, 0)
	else:
		if dir.y < 0:
			last_dir = "up"
			if weapon_hitbox: weapon_hitbox.position = Vector2(0, -20)
		else:
			last_dir = "down"
			if weapon_hitbox: weapon_hitbox.position = Vector2(0, 20)

# Hareket ederken oynatılacak animasyonlar
func play_run_animation(movement_vector: Vector2) -> void:
	if abs(movement_vector.x) > abs(movement_vector.y):
		if movement_vector.x < 0:
			animated_sprite.play("run_left")
		else:
			animated_sprite.play("run_right")
	else:
		if movement_vector.y < 0:
			animated_sprite.play("run_up")
		else:
			animated_sprite.play("run_down")

# Saldırıya başlama
func start_attack() -> void:
	is_attacking = true
	
	var attack_anim = "attack_" + last_dir
	if animated_sprite.animation != attack_anim:
		animated_sprite.play(attack_anim)
	
	if hitbox_collision:
		hitbox_collision.disabled = false

# Saldırıyı durdur
func stop_attack() -> void:
	is_attacking = false
	if hitbox_collision:
		hitbox_collision.disabled = true

# Moba vurduğumuzda tetiklenecek olan fonksiyon
func _on_weapon_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "HurtBox":
		var vampire = area.get_parent()
		if vampire.has_method("take_damage"):
			vampire.take_damage(25)
