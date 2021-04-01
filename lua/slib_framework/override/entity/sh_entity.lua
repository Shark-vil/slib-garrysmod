local meta = FindMetaTable('Entity')
local list_door_classes = {
   "func_door",
   "func_door_rotating",
   "prop_door_rotating",
}

function meta:slibSetVar(key, value)
   if isfunction(value) then return end

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
         snet.Create('slib_entity_variable_del').SetData(self, key).InvokeAll()
      else
         snet.Create('slib_entity_variable_set').SetData(self, key, value).InvokeAll()
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