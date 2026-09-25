@tool
extends Control
class_name LoadingScreen

@onready var animation: LoadingAnimation = $%animation

func set_progress(value: float):
	animation.progressBar.value = value
