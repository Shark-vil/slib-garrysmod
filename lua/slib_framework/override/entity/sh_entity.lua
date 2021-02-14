local meta = FindMetaTable('Entity')
meta.slibVariables = {}

function meta:slibSetVar(name, value)
   if isfunction(value) then return end

   self.slibVariables[name] = value

   if SERVER then
      local n_sync_entity_vars = slib.GetNetworkString('Entity', 'SlibVarSyncForClient')
      snet.EntityInvokeAll(n_sync_entity_vars, self, name, value)
   end
end

function meta:slibGetVar(name)
   return self.slibVariables[name]
end
