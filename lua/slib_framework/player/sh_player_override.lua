local meta = FindMetaTable('Player')
local variables = {}

function meta:slibSetVar(name, value)
   if isfunction(value) then return end

   variables[name] = value

   if SERVER then
      net.Start(slib.GetNetworkString('Player', 'SlibVarSyncForClient'))
      net.WriteString(name)
      net.WriteType(value)
      net.Send(self)
   end
end

function meta:slibGetVar(name)
   return variables[name]
end
