class_name QuestNotification
extends CanvasLayer

signal done

func setup(text: String, color: Color) -> void:
	if not is_inside_tree():
		await ready
	var lbl := $Root/Panel/Label as Label
	if not lbl:
		done.emit()
		queue_free()
		return
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)

	var root := $Root as Control
	root.offset_top = -100.0
	root.offset_bottom = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "offset_top", 20.0, 0.3)
	tween.parallel().tween_property(root, "offset_bottom", 120.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(root, "modulate", Color.TRANSPARENT, 0.3)
	tween.finished.connect(func():
		done.emit()
		queue_free()
	)
