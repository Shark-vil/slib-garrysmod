local sgui = slib.Components.GUI
local AccessComponent = slib.Components.Access

sgui.routes_storage = sgui.routes_storage or {}

if CLIENT then
	function sgui.RouteRegister(adr, func, access)
		if not isstring(adr) or not isfunction(func) then return end
		sgui.routes_storage[adr] = function(...)
			if access and not AccessComponent.IsValid(LocalPlayer(), access) then return end
			func(...)
		end
	end

	function sgui.RouteRemove(adr)
		sgui.routes_storage[adr] = nil
	end
end

function sgui.route(adr, ...)
	if SERVER then
		local args = { ... }
		local ply = args[1]
		if not ply or not isentity(ply) or not ply:IsPlayer() then return end
		table.remove(args, 1)
		snet.Invoke('sgui_route_open_by_server', ply, adr, unpack(args))
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