-- function slib.GetAllLoadedPlayers()
--    local players = player.GetAll()
--    local loaded_players = {}

--    for i = 1, #players do
--       local ply = players[i]
--       if ply.snet_ready then table.push(loaded_players, ply) end
--    end

--    return loaded_players
-- end

function slib.PlayerReady(ply)
   return ( ply and ply.snet_ready == true )
end