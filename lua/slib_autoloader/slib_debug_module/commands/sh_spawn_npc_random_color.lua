local snet = snet
local slib = slib
local timer = timer
local CLIENT = CLIENT
--

if CLIENT then
	snet.Callback('cl_snet_debug_create_npc', function(ply, ent)
		ent:slibOnInstanceVarCallback('color', function(new_color)
			ent:SetColor(new_color)
			slib.Log('NPC ', ent, ' new color - ', new_color)
			snet.InvokeServer('cl_snet_debug_create_npc_start_randomizer', ent)
		end)

		ent:slibAddChangeVarCallback('color', function(old_color, new_color)
			ent:SetColor(new_color)
		end)
	end).Validator(SNET_ENTITY_VALIDATOR)
end

slib.RegisterGlobalCommand('snet_debug_create_npc', nil, function(ply)
	local player_pos = ply:GetPos()

	timer.Simple(2, function()
		local new_ent = ents.Create('npc_citizen')
		new_ent:SetPos(player_pos)
		new_ent:Spawn()

		snet.Create('cl_snet_debug_create_npc', new_ent).Complete(function(players)

			snet.Callback('cl_snet_debug_create_npc_start_randomizer', function(ply, ent)
				slib.Log('The player ', ply, ' has start the npc color randomizer')

				ent:slibCreateTimer('color_randomize', 1, 0, function()
					ent:slibSetVar('color', ColorRand(), true)
				 end)

			end).AutoDestroy()

			new_ent:slibSetVar('color', ColorRand())
			new_ent:slibAutoDestroy(10)

		end).InvokeAll()
	end)
end)