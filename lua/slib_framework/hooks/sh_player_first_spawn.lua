if SERVER then	
	hook.Add("PlayerSpawn", "Slib_PlayerFirstSpawnFixer", function(ply)
      if ply.slibIsSpawn then return end

		timer.Simple(3, function()
			if not IsValid(ply) or ply.slibIsSpawn then return end

			ply.slibIsSpawn = true
         hook.Run('SlibPlayerFirstSpawn', ply)

			timer.Simple(1, function()
				if not IsValid(ply) then return end
				snet.Invoke(slib.GetNetworkString('Slib', 'FirstPlayerSpawn'), ply)
			end)
		end)
	end)
else
	snet.RegisterCallback(slib.GetNetworkString('Slib', 'FirstPlayerSpawn'), function()
		LocalPlayer().slibIsSpawn = true
		hook.Run('SlibPlayerFirstSpawn', LocalPlayer())
	end)
end