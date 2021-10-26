snet.RegisterCallback('slib_player_set_language', function(ply, lang)
	ply:slibSetVar('slib_client_language', lang)
end)