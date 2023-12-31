extends Node2D

@export var game_duration : int = 60;
@export var slowness_mode : bool = false
@export var stomping_needs_press : bool = true

var positions = {
	0: Vector2(300,300),
	1: Vector2(500,300),
	2: Vector2(700,300),
	3: Vector2(900,300)
}

@onready var player_manager = $PlayerManager
@onready var screen_shaker = $ScreenShaker 
@onready var timer = $Timer
@onready var animation_player = $AnimationPlayer
@onready var winner_banner = $WinnerBanner
@onready var end_timer = $roundEndTimer

var slowness = 50
var players = {}
var points = {0: 0, 1: 0, 2: 0, 3:0}
var max_points = 10
var current_max = 0
var player_points_scene = preload("res://UI/player_points.tscn")
var player_points = {}
var game_finished = false

func _ready():
	if ConfigLoader.get_config()["volume"] == 0:
		$bgMusic.volume_db = -80
	else:
		$bgMusic.volume_db = (1 - ConfigLoader.get_config()["volume"]) * -40
		
	player_manager.set("needs_pressing", stomping_needs_press)
	player_manager.instantiate_draw_players(positions)
	players = player_manager.get_players()
	var i=0
	for p in players:
		players[p].stomped.connect(stomped)
		var pl_p = player_points_scene.instantiate()
		pl_p.select_character(players[p].get("character"))
		pl_p.set("position", Vector2(280,150+i*20))
		add_child(pl_p)
		player_points[p] = pl_p
		i += 1
		
	

func stomped(who: int, enemy : int): # depending on the level it works in one way or another (exchanging crown for example)
	if players[enemy].get("has_crown"):
		players[enemy].lose_crown()
		players[who].receive_crown()
		screen_shaker.shake()
		$pickup.play()
		if slowness_mode:
			players[enemy].set("slowness", 0)
			players[who].set("slowness", slowness)
	players[enemy].get_stomped()


func _on_tortilla_entered(body):
	if body.is_in_group("players"):
		$pickup.play()
		body.receive_crown()
		if slowness_mode:
			body.set("slowness", slowness)
		$Tortilla1.queue_free()

func end_game(winner : int):
	game_finished = true
	winner_banner.set_winner(GameStorage.get_players()[winner][0])
	GameStorage.update_points(winner,GameStorage.get_player_points(winner)+1)
	end_timer.start()
	

func update_winner():
	if not game_finished:
		for p in players:
			if points[p] == current_max:
				player_points[p].set_winner(true)
				if slowness_mode:
					players[p].set("slowness", slowness)
			else:
				player_points[p].set_winner(false)
		

func _on_timer_timeout():
	game_duration -=1
	
	if not game_finished:
		for i in players:
			if players[i].has_object():
				points[i] += 1
				if points[i] >= current_max:
					current_max = points[i]
					update_winner()
				player_points[i].set_points(points[i])
				if points[i] == max_points:
					animation_player.stop()
					end_game(i)


func _on_audio_finished():
	$bgMusic.play()


func _on_round_timer_end():
	GameStorage.set_drawers([])
	SceneTransition.change_scene("res://Levels/post_round.tscn")
