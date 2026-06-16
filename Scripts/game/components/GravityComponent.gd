class_name GravityComponent
extends Node

func activate(body: RigidBody2D) -> void:
	body.gravity_scale = 1.0
