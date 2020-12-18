extends PopupPanel

func set_text(msg):
	$ScrollContainer/Label.text = msg


func _on_MsgPopup_popup_hide():
	queue_free()
