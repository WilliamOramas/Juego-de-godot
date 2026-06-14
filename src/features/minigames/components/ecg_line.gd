class_name ECGLineControl
extends Control

var lives: int = 3
var _ecg_time: float = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	_ecg_time += delta
	queue_redraw()

func _draw() -> void:
	var points = PackedVector2Array()
	var w = size.x
	# The old script had base_y hardcoded to 90.0, or center.
	var base_y = size.y / 2.0
	if size.y == 0:
		base_y = 90.0

	var freq = 1.0
	if lives == 2: freq = 1.5
	elif lives == 1: freq = 2.5
	elif lives <= 0: freq = 0.0

	var color = Color(0.2, 1.0, 0.2)
	if lives == 2: color = Color(1.0, 0.8, 0.2)
	elif lives <= 1: color = Color(1.0, 0.2, 0.2)

	for x in range(0, int(w), 4):
		var nx = x / w
		var y = base_y
		if freq > 0.0:
			var phase = fmod(nx * 5.0 - _ecg_time * freq, 1.0)
			if phase > 0.4 and phase < 0.6:
				var spike = sin((phase - 0.4) * 5.0 * PI)
				y += spike * 30.0
		points.append(Vector2(x, y))

	if points.size() > 1:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i+1], color, 2.0, true)
