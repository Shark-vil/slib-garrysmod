snet.RegisterCallback('slib_entityvars_sync_for_clients', function (_, ent, name, value)
   ent:slibSetVar(name, value)
end)