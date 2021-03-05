function slib.GetAllLoadedPlayers()
   local players = {}
   for _, ply in ipairs(player.GetAll()) do
      if ply.slibIsSpawn then
         table.insert(players, ply)
      end
   end
   return players
end