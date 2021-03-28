local meta = FindMetaTable('Entity')

function meta:slibSetVar(name, value)
   if isfunction(value) then return end

   self.slibVariables = self.slibVariables or {}
   self.slibVariablesChangeCallback = self.slibVariablesChangeCallback or {}
   self.slibVariablesSetCallback = self.slibVariablesSetCallback or {}

   local old_value = self.slibVariables[name]
   local new_value = value

   if old_value and old_value ~= new_value then
      if self.slibVariablesChangeCallback[name] then
         for _, func in ipairs(self.slibVariablesChangeCallback[name]) do
            func(old_value, new_value)
         end
      end
   end

   self.slibVariables[name] = new_value

   if self.slibVariablesSetCallback[name] then
      for _, func in ipairs(self.slibVariablesSetCallback[name]) do
         func(old_value, new_value)
      end
   end

   if SERVER then
      snet.EntityInvokeAll('slib_entityvars_sync_for_clients', self, name, value)
   end
end

function meta:slibGetVar(name, fallback)
   if self.slibVariables == nil or self.slibVariables[name] == nil then
      return fallback or false
   end
   return self.slibVariables[name]
end

function meta:slibAddSetVarCallback(name, func)
   if not isfunction(func) then return end

   self.slibVariablesSetCallback = self.slibVariablesSetCallback or {}
   self.slibVariablesSetCallback[name] = self.slibVariablesSetCallback[name] or {}

   table.insert(self.slibVariablesSetCallback[name], func)
end

function meta:slibAddChangeVarCallback(name, func)
   if not isfunction(func) then return end

   self.slibVariablesChangeCallback = self.slibVariablesChangeCallback or {}
   self.slibVariablesChangeCallback[name] = self.slibVariablesChangeCallback[name] or {}

   table.insert(self.slibVariablesChangeCallback[name], func)
end