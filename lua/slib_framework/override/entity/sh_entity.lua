local meta = FindMetaTable('Entity')

function meta:slibSetVar(name, value)
   if isfunction(value) then return end

   self.slibVariables = self.slibVariables or {}
   self.slibVariables[name] = value

   if SERVER then
      local n_sync_entity_vars = slib.GetNetworkString('Entity', 'SlibVarSyncForClient')
      snet.EntityInvokeAll(n_sync_entity_vars, self, name, value)
   end
end

function meta:slibGetVar(name, fallback)
   if self.slibVariables == nil or self.slibVariables[name] == nil then
      return fallback or false
   end
   return self.slibVariables[name]
end
