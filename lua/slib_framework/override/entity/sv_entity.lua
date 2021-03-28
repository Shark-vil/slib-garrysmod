hook.Add("SlibPlayerFirstSpawn", "Slib_SyncExistsNetworkVariable", function(ply)
   for _, ent in ipairs(ents.GetAll()) do
      if ent.slibVariables ~= nil and #ent.slibVariables ~= 0 then
         for key, value in pairs(ent.slibVariables) do
            if value ~= nil then
               snet.EntityInvoke('slib_entity_variable_set', ply, ent, key, value)
            end
         end
      end
   end
end)