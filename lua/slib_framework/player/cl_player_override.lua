net.Receive(slib.GetNetworkString('Player', 'SlibVarSyncForClient'), function()
   local name = net.ReadString()
   local value = net.ReadType()

   LocalPlayer():slibSetVar(name, value)
end)