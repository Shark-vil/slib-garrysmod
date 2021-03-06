snet.Callback('slib_entity_variable_set', function (_, ent, key, value)
   ent:slibSetVar(key, value)
end).Validator(SNET_ENTITY_VALIDATOR).Register()

snet.Callback('slib_entity_variable_del', function (_, ent, key)
   ent:slibSetVar(key, nil)
end).Validator(SNET_ENTITY_VALIDATOR).Register()

snet.RegisterCallback('snet_entity_tool_call_client_rpc',
function(ply, ent, isExistServerFunction, tool_mode, func_name, ...)
   if not ent or not IsValid(ent) or ent:GetClass() ~= 'gmod_tool' then return end

   local tool = ply:GetTool()
   if tool:GetMode() ~= tool_mode then return end
   
   local func = tool[func_name]
   if not func then return end
   if not game.SinglePlayer() and isExistServerFunction then return end

   func(tool, ...)
end)

snet.Callback('snet_entity_call_client_rpc',
function(ply, ent, isExistServerFunction, func_name, ...)
   if not ent or not IsValid(ent) then return end

   local func = ent[func_name]
   if not func then return end
   if not game.SinglePlayer() and isExistServerFunction then return end

   func(ent, ...)
end).Validator(SNET_ENTITY_VALIDATOR).Register()