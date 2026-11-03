extends CharacterBody2D

@export var velocidade_andar := 60.0
@export var velocidade_correr := 120.0
@export var tempo_para_lamber := 5.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Ordem importa: índice 0 = Leste, e vai girando no sentido horário (eixo Y do Godot aponta pra baixo)
const DIRECOES := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

var machucado := false
var ocioso_tempo := 0.0
var ultima_direcao := "s"  # direção que o personagem está olhando


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("idle_" + ultima_direcao)


func _physics_process(delta: float) -> void:
	if machucado:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var correndo := Input.is_key_pressed(KEY_SHIFT)
	var vel := velocidade_correr if correndo else velocidade_andar

	velocity = direcao * vel
	move_and_slide()

	if direcao != Vector2.ZERO:
		ultima_direcao = _nome_direcao(direcao)
		ocioso_tempo = 0.0
		_tocar(("run_" if correndo else "walk_") + ultima_direcao)
	else:
		_ocioso(delta)


# Converte o vetor em uma das 8 direções (cada fatia tem 45°)
func _nome_direcao(dir: Vector2) -> String:
	var indice := int(round(dir.angle() / (PI / 4.0)))  # -4 a 4
	return DIRECOES[posmod(indice, 8)]


func _ocioso(delta: float) -> void:
	if anim.animation.begins_with("lick") or anim.animation.begins_with("blink"):
		if anim.is_playing():
			return

	ocioso_tempo += delta
	if ocioso_tempo >= tempo_para_lamber:
		ocioso_tempo = 0.0
		_tocar(["lick", "blink"].pick_random() + "_" + ultima_direcao)
	else:
		_tocar("idle_" + ultima_direcao)


func _tocar(nome: String) -> void:
	if anim.animation != nome or not anim.is_playing():
		anim.play(nome)


func levar_dano() -> void:
	if machucado:
		return
	machucado = true
	anim.play("hurt_" + ultima_direcao)


func _on_animation_finished() -> void:
	if anim.animation.begins_with("hurt"):
		machucado = false
	if anim.animation.begins_with("hurt") \
	or anim.animation.begins_with("lick") \
	or anim.animation.begins_with("blink"):
		anim.play("idle_" + ultima_direcao)
