util.AddNetworkString(slib.GetNetworkString('Entity', 'SlibVarSyncForClient'))

hook.Add("SlibPlayerFirstSpawn", "Slib_SyncExistsNetworkVariable", function(ply)
   for _, ent in ipairs(ents.GetAll()) do
      if ent.slibVariables ~= nil and #ent.slibVariables ~= 0 then
         for key, value in pairs(ent.slibVariables) do
            local n_sync_entity_vars = slib.GetNetworkString('Entity', 'SlibVarSyncForClient')
            snet.EntityInvoke(n_sync_entity_vars, ply, ent, key, value)
         end
      end
   end
end)