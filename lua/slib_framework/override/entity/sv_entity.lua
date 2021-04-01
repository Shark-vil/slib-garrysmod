hook.Add("SlibPlayerFirstSpawn", "Slib_SyncExistsNetworkVariable", function(ply)
   for _, ent in ipairs(ents.GetAll()) do
      if ent.slibVariables ~= nil and #ent.slibVariables ~= 0 then
         for key, value in pairs(ent.slibVariables) do
            if value ~= nil then
               snet.Create('slib_entity_variable_set').SetData(ent, key, value).Invoke(ply)
            end
         end
      end
   end
end)