local snet = slib.Components.Network
local sgui = slib.Components.GUI
local isentity = isentity
local unpack = unpack
local table = table
local SERVER = SERVER
local CLIENT = CLIENT
--

sgui.routes_storage = sgui.routes_storage or {}

if CLIENT then
	function sgui.RouteRegister(adr, func)
		if not isstring(adr) or not isfunction(func) then return end
		sgui.routes_storage[adr] = func
	end
end

function sgui.route(adr, ...)
	if SERVER then
		local args = { ... }
		local first_arg = args[1]
		if not first_arg or not isentity(first_arg) or not first_arg:IsPlayer() then return end
		table.remove(args, 1)
		snet.Invoke('sgui_route_open_by_server', first_arg, unpack(args))
		return
	end

	if not sgui.routes_storage[adr] then return end
	return sgui.routes_storage[adr](...)
end

if CLIENT then
	snet.Callback('sgui_route_open_by_server', function(_, adr, ...)
		sgui.route(adr, ...)
	end)
end