snet.RegisterCallback('slib_player_notify', function(ply, text, type, length, sound)
   ply:slibNotify(text, type, length, sound)
end)