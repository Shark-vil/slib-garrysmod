snet.RegisterCallback('slib_entity_variable_set', function (_, ent, key, value)
   ent:slibSetVar(key, value)
end)

snet.RegisterCallback('slib_entity_variable_del', function (_, ent, key)
   ent:slibSetVar(key, nil)
end)