extends Node2D

@export var _sprite_base: Sprite2D
@export var _projectile_path: Line2D
@export var _highlight: Sprite2D
@export var _click_detector: Area2D

var _char_id: int
signal selected(id: int)
signal power_update(power: float)

#constructor
#set id to be used in signaling

#when selected: 


#updating power curve:
#if selected to move -- show curve
#Scale all points line based on how much power is put into the shot


#func get power
