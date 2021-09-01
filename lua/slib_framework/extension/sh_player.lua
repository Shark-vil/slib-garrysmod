function slib.GetAllLoadedPlayers()
   return slib.LOADED_PLAYERS
end

function slib.PlayerIsNetReady(ply)
   if not ply or not ply.snet_ready then return false end
   return true
end