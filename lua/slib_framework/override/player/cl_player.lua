snet.RegisterCallback('slib_player_notify', function(ply, text, message_type, length, sound_path)
	ply:slibNotify(text, message_type, length, sound_path)
end)

hook.Add('SlibPlayerFirstSpawn', 'SlibInitializeGlobalClientLanguage', function(ply)
	snet.InvokeServer('slib_player_set_language', GetConVar('cl_language'):GetString())
end)