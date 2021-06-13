local n_slib_first_player_spawn = slib.GetNetworkString('Slib', 'FirstPlayerSpawn')

if SERVER then	
	hook.Add("PlayerSpawn", "Slib_PlayerFirstSpawnFixer", function(ply)
      if ply.snet_ready_plug then return end
		ply.snet_ready_plug = true

		local hook_name = 'SlibFirstSpawn' .. slib.GenerateUid(ply:UserID())
		hook.Add("SetupMove", hook_name, function(p, mv, cmd)
			if p == ply and not cmd:IsForced() then
				if not IsValid(ply) then return end
		
				ply.snet_ready = true
				hook.Run('SlibPlayerFirstSpawn', ply)
				snet.Invoke(n_slib_first_player_spawn, ply)

				hook.Remove("SetupMove", hook_name)
			end
		end)
	end)
else
	snet.RegisterCallback(n_slib_first_player_spawn, function()
		LocalPlayer().snet_ready = true
		hook.Run('SlibPlayerFirstSpawn', LocalPlayer())
	end)
end