local n_sync_entity_vars = slib.GetNetworkString('Entity', 'SlibVarSyncForClient')

snet.RegisterEntityCallback(n_sync_entity_vars, function (ply, ent, name, value)   
   ent:slibSetVar(name, value)
end)