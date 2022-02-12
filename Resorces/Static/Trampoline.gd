extends Node2D

export (float, 0, 1, 0.01) var power = 0.5

func jumpDetector_body_entered(body: Node):
	
	if body.velocity.y > 0:
		body.velocity.y = -body.velocity.y#-(body.velocity.y - power * body.velocity.y)
		print(body.velocity.y)
