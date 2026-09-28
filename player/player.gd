extends CharacterBody2D

@export var speed: float = 200.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Vuruş alanını ve içindeki collision'ı koda bağlıyoruz (İsimlerin sahnenle aynı olduğundan emin ol)
@onready var weapon_hitbox: Area2D = $WeaponHitBox
@onready var hitbox_collision: CollisionShape2D = $WeaponHitBox/CollisionShape2D

var last_dir: String = "down"
var is_attacking: bool = false

func _ready() -> void:
	# Oyun başlar başı vuruş kutusu kapalı olsun
	if hitbox_collision:
		hitbox_collision.disabled = true

func _physics_process(delta: float) -> void:
	# 1. Saldırı Tuşuna Basılı Tutuluyor mu?
	if Input.is_action_pressed("ui_accept"):
		start_attack()
		return 
	
	# Eğer saldırı tuşundan elimizi çektiysek ve hala saldırı modundaysak, saldırıyı bitir
	if is_attacking and Input.is_action_just_released("ui_accept"):
		stop_attack()

	# Eğer şu an saldırı yapıyorsak hareket etmeyelim
	if is_attacking:
		return

	# 2. Hareket Girdileri (WASD ve Ok Tuşları)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		
		if abs(direction.x) > abs(direction.y):
			if direction.x < 0:
				last_dir = "left"
				animated_sprite.play("run_left")
				if weapon_hitbox: weapon_hitbox.position = Vector2(-20, 0)
			else:
				last_dir = "right"
				animated_sprite.play("run_right")
				if weapon_hitbox: weapon_hitbox.position = Vector2(20, 0)
		else:
			if direction.y < 0:
				last_dir = "up"
				animated_sprite.play("run_up")
				if weapon_hitbox: weapon_hitbox.position = Vector2(0, -20)
			else:
				last_dir = "down"
				animated_sprite.play("run_down")
				if weapon_hitbox: weapon_hitbox.position = Vector2(0, 20)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)
		animated_sprite.play("idle_" + last_dir)

	move_and_slide()

# Saldırıya başlama veya basılı tutarken devam etme
func start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO # Saldırı yaparken kaymasın
	
	var attack_anim = "attack_" + last_dir
	if animated_sprite.animation != attack_anim:
		animated_sprite.play(attack_anim)
	
	# Saldırı başladığı an vuruş kutusunu aktif et
	if hitbox_collision:
		hitbox_collision.disabled = false

# Tuş bırakıldığında saldırıyı durdur ve idle'a dön
func stop_attack() -> void:
	is_attacking = false
	# Saldırı bitince vuruş kutusunu kapat
	if hitbox_collision:
		hitbox_collision.disabled = true
	animated_sprite.play("idle_" + last_dir)

# Moba vurduğumuzda tetiklenecek olan fonksiyon
func _on_weapon_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "HurtBox":
		# Çarptığımız alanın bir üst düğümü (Mob/Vampire) üzerinden take_damage çağırıyoruz
		var vampire = area.get_parent()
		if vampire.has_method("take_damage"):
			vampire.take_damage(25)
