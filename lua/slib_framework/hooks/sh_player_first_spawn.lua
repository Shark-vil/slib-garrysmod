if SERVER then
	hook.Add('PlayerDisconnected', 'Slib_PlayerDisconnectedRemoveLoadedPlayer', function(disconnected_player)
		if disconnected_player and IsValid(disconnected_player) then
			local hook_name = disconnected_player.slib_first_spawn_hook_name
			if hook_name and isstring(hook_name) then
				hook.Remove('SetupMove', hook_name)
			end
		end

		for i = #slib.Storage.LoadedPlayers, 1, -1 do
			local ply = slib.Storage.LoadedPlayers[i]
			if not IsValid(ply) or ply == disconnected_player then
				slib.DebugLog('The player ', ply, ' has disconnected from the server')
				table.remove(slib.Storage.LoadedPlayers, i)
			end
		end

		snet.InvokeAll('slib_player_disconnected_sync', disconnected_player)
	end)

	hook.Add('PlayerSpawn', 'Slib_PlayerFirstSpawnFixer', function(ply)
		if ply.slib_player_spawn then return end
		ply.slib_player_spawn = true

		local hook_name = 'slib.FirstSpawnSetupMove_' .. slib.GenerateUid(ply:UserID())
		ply.slib_first_spawn_hook_name = hook_name

		hook.Add('SetupMove', hook_name, function(p, mv, cmd)
			if p and ply and IsValid(ply) and IsValid(p) and p == ply and not cmd:IsForced() then
				ply.snet_ready = true
				ply.slib_first_spawn_hook_name = nil

				table.insert(slib.Storage.LoadedPlayers, ply)

				hook.Run('slib.FirstPlayerSpawn', ply)
				snet.Request('slib_first_player_spawn', ply).InvokeAll()

				-- timer.Simple(1.5, function()
				-- 	if not ply or not IsValid(ply) then return end
				-- 	snet.Request('slib_first_player_spawn', ply).InvokeAll()
				-- end)

				hook.Remove('SetupMove', hook_name)
			end
		end)
	end)

	hook.Add('slib.FirstPlayerSpawn', 'Slib_SyncExistsNetworkVariable', function(ply)
		for _, ent in ipairs(ents.GetAll()) do
			if ent.slibVariables and table.Count(ent.slibVariables) ~= 0 then
				for key, value in pairs(ent.slibVariables) do
					if value ~= nil then
						snet.Invoke('slib_entity_variable_set', ply, ent, key, value)
					end
				end
			end
		end

		local players = {}

		for _, aply in ipairs(player.GetAll()) do
			if aply ~= ply and aply.snet_ready then
				table.insert(players, aply)
			end
		end

		snet.Invoke('slib_first_player_spawn_sync', ply, players)
	end)
else
	snet.Callback('slib_first_player_spawn', function(_, ply)
		slib.DebugLog('Player ', ply, ' first spawn on the server')
		if ply == LocalPlayer() then
			slib.DebugLog('You spawned on the server for the first time')
		end

		ply.snet_ready = true
		table.insert(slib.Storage.LoadedPlayers, ply)

		hook.Run('slib.FirstPlayerSpawn', ply)
	end).Validator(SNET_ENTITY_VALIDATOR)

	snet.Callback('slib_first_player_spawn_sync', function(_, players)
		for i = 1, #players do
			local ply = players[i]

			ply.snet_ready = true
			table.insert(slib.Storage.LoadedPlayers, ply)

			slib.DebugLog('Player sync -', ply)
		end
	end).Validator(SNET_ENTITY_VALIDATOR)

	snet.Callback('slib_player_disconnected_sync', function(_, disconnected_player)
		for i = #slib.Storage.LoadedPlayers, 1, -1 do
			local ply = slib.Storage.LoadedPlayers[i]
			if not IsValid(ply) or ply == disconnected_player then
				slib.DebugLog('The player ', ply, ' has disconnected from the server')
				table.remove(slib.Storage.LoadedPlayers, i)
			end
		end
	end)
end