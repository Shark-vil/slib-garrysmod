snet.Callback('slib_entity_variable_set', function (_, ent, key, value)
   ent:slibSetVar(key, value)
end).Validator(SNET_ENTITY_VALIDATOR).Register()

snet.Callback('slib_entity_variable_del', function (_, ent, key)
   ent:slibSetVar(key, nil)
end).Validator(SNET_ENTITY_VALIDATOR).Register()