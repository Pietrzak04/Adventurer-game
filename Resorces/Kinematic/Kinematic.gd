extends KinematicBody2D

class_name Kinematic

const FLOOR_NORMAL = Vector2.UP

export var gravity: = 3000.0
export var speed: = Vector2(300.0, 0.0)
var direction = Vector2.ZERO
var velocity: = Vector2.ZERO setget ,get_velocity
export (float, 0, 1.0) var friction = 0.2
export (float, 0, 1.0) var acceleration = 0.2

var max_health = 100
var health = max_health

func get_velocity():
	return velocity
