hook.Add("SlibPlayerFirstSpawn", "Slib_SyncExistsNetworkVariable", function(ply)
   for _, ent in ipairs(ents.GetAll()) do
      if ent.slibVariables ~= nil and #ent.slibVariables ~= 0 then
         for key, value in pairs(ent.slibVariables) do
            snet.EntityInvoke('slib_entityvars_sync_for_clients', ply, ent, key, value)
         end
      end
   end
end)