function slib.GetAllLoadedPlayers()
   local players = player.GetAll()
   local loaded_players = {}

   for i = 1, #players do
      local ply = players[i]
      if ply.slibIsSpawn then array.insert(loaded_players, ply) end
   end

   return loaded_players
end