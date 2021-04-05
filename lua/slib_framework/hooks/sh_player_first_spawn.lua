local n_slib_first_player_spawn = slib.GetNetworkString('Slib', 'FirstPlayerSpawn')

if SERVER then	
	hook.Add("PlayerSpawn", "Slib_PlayerFirstSpawnFixer", function(ply)
      if ply.slibIsSpawn_plug then return end
		ply.slibIsSpawn_plug = true

		local hook_name = 'SlibFirstSpawn' .. slib.GenerateUid(ply:UserID())
		hook.Add("SetupMove", hook_name, function(p, mv, cmd)
			if p == ply and not cmd:IsForced() then
				timer.Simple(3, function()
					if not IsValid(ply) then return end
		
					ply.slibIsSpawn = true
					hook.Run('SlibPlayerFirstSpawn', ply)
		
					snet.Invoke(n_slib_first_player_spawn, ply)
				end)

				hook.Remove("SetupMove", hook_name)
			end
		end)
	end)
else
	snet.RegisterCallback(n_slib_first_player_spawn, function()
		LocalPlayer().slibIsSpawn = true
		hook.Run('SlibPlayerFirstSpawn', LocalPlayer())
	end)
end