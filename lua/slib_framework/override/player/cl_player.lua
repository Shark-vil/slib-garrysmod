snet.RegisterCallback('slib_player_notify', function(ply, text, message_type, length, sound_path)
	ply:slibNotify(text, message_type, length, sound_path)
end)