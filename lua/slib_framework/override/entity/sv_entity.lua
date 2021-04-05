hook.Add("SlibPlayerFirstSpawn", "Slib_SyncExistsNetworkVariable", function(ply)
   for _, ent in ipairs(ents.GetAll()) do
      if ent.slibVariables ~= nil and #ent.slibVariables ~= 0 then
         for key, value in pairs(ent.slibVariables) do
            if value ~= nil then
               snet.Create('slib_entity_variable_set', ent, key, value).Invoke(ply)
            end
         end
      end
   end
end)

snet.RegisterCallback('snet_entity_tool_call_server_rpc', function(ply, ent, tool_mode, func_name, ...)
   if not ent or not IsValid(ent) or ent:GetClass() ~= 'gmod_tool' then return end

   local owner = ent:GetOwner()
   if IsValid(owner) and owner:IsPlayer() and owner ~= ply then
      return
   end

   local tool = ply:GetTool()
   if tool:GetMode() ~= tool_mode then return end
   
   local func = tool[func_name]
   if not func then return end
   func(tool, ...)
end)

snet.RegisterCallback('snet_entity_call_server_rpc', function(ply, ent, func_name, ...)
   if not ent or not IsValid(ent) then return end

   local owner = ent:GetOwner()
   if IsValid(owner) and owner:IsPlayer() and owner ~= ply then
      return
   end
   
   local func = ent[func_name]
   if not func then return end
   func(ent, ...)
end)