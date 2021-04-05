local meta = FindMetaTable('Entity')
local list_door_classes = {
   "func_door",
   "func_door_rotating",
   "prop_door_rotating",
}

function meta:slibSetVar(key, value)
   if not snet.ValueIsValid(value) then return end

   self.slibVariables = self.slibVariables or {}
   self.slibVariablesChangeCallback = self.slibVariablesChangeCallback or {}
   self.slibVariablesSetCallback = self.slibVariablesSetCallback or {}

   local old_value = self.slibVariables[key]
   local new_value = value

   if old_value ~= nil and old_value == new_value then return end

   if old_value ~= nil and old_value ~= new_value then
      if self.slibVariablesChangeCallback[key] then
         for _, func in ipairs(self.slibVariablesChangeCallback[key]) do
            func(old_value, new_value)
         end
      end
   end

   self.slibVariables[key] = new_value

   if self.slibVariablesSetCallback[key] then
      for _, func in ipairs(self.slibVariablesSetCallback[key]) do
         func(old_value, new_value)
      end
   end

   if SERVER then
      if new_value == nil then
         snet.Create('slib_entity_variable_del', self, key).SetLifeTime(1.5).InvokeAll()
      else
         snet.Create('slib_entity_variable_set', self, key, value).SetLifeTime(1.5).InvokeAll()
      end
   end
end

function meta:slibGetVar(key, fallback)
   if self.slibVariables == nil or self.slibVariables[key] == nil then
      return fallback or false
   end
   return self.slibVariables[key]
end

function meta:slibAddSetVarCallback(key, func)
   if not isfunction(func) then return end

   self.slibVariablesSetCallback = self.slibVariablesSetCallback or {}
   self.slibVariablesSetCallback[key] = self.slibVariablesSetCallback[key] or {}

   table.insert(self.slibVariablesSetCallback[key], func)
end

function meta:slibAddChangeVarCallback(key, func)
   if not isfunction(func) then return end

   self.slibVariablesChangeCallback = self.slibVariablesChangeCallback or {}
   self.slibVariablesChangeCallback[key] = self.slibVariablesChangeCallback[key] or {}

   table.insert(self.slibVariablesChangeCallback[key], func)
end

function meta:slibCreateTimer(timer_name, delay, repetitions, func)
   local timer_name = 'SLIB_ENTITY_TIMER_' .. util.CRC(self:EntIndex() .. timer_name)
   timer.Create(timer_name, delay, repetitions, function()
      if not IsValid(self) then timer.Remove(timer_name) return end
      func(self)
   end)
end

function meta:slibRemoveTimer(timer_name, func)
   local timer_name = 'SLIB_ENTITY_TIMER_' .. util.CRC(self:EntIndex() .. timer_name)
   if timer.Exists(timer_name) then timer.Remove(timer_name) end
end

function meta:slibIsDoor()
   return table.IHasValue(list_door_classes, self:GetClass())
end

if SERVER then
   function snet.ClientRPC(ent, function_name, ...)
      local ent = ent
      if not isentity(ent) and ent.Weapon then
         ent = ent.Weapon
      end

      if not ent or not IsValid(ent) then return end

      local ply
      local owner = ent:GetOwner()
      if IsValid(owner) and owner:IsPlayer() then ply = owner end

      if ply and ent:GetClass() == 'gmod_tool' then
         local tool = ply:GetTool()
         local isExistServerFunction = (tool[function_name] ~= nil and isfunction(tool[function_name]))

         snet.Invoke('snet_entity_tool_call_client_rpc', ply, ent, isExistServerFunction, tool:GetMode(), function_name, ...)
      else
         local isExistServerFunction = (ent[function_name] ~= nil and isfunction(ent[function_name]))

         if ply then
            snet.Invoke('snet_entity_call_client_rpc', ply, ent, isExistServerFunction, function_name, ...)
         else
            snet.InvokeAll('snet_entity_call_client_rpc', ent, isExistServerFunction, function_name, ...)
         end
      end
   end

   function meta:slibClientRPC(function_name, ...)
      snet.ClientRPC(self, function_name, ...)
   end
else
   function snet.ServerRPC(ent, function_name, ...)
      local ent = ent
      if not isentity(ent) and ent.Weapon then
         ent = ent.Weapon
      end

      if not ent or not IsValid(ent) then return end

      local owner = ent:GetOwner()
      if IsValid(owner) and owner:IsPlayer() and owner ~= LocalPlayer() then return end

      if ent:GetClass() == 'gmod_tool' then
         local tool = LocalPlayer():GetTool()
         snet.InvokeServer('snet_entity_tool_call_server_rpc', ent, tool:GetMode(), function_name, ...)
      else
         snet.InvokeServer('snet_entity_call_server_rpc', ent, function_name, ...)
      end
   end

   function meta:slibServerRPC(function_name, ...)
      snet.ServerRPC(self, function_name, ...)
   end
end