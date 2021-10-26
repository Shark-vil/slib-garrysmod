local math_pi = math.pi
--
local meta = FindMetaTable('Player')

function meta:slibNotify(text, notify_type, length, sound)
	text = text or ''
	notify_type = notify_type or NOTIFY_GENERIC
	length = length or 3

	if SERVER then
		snet.Invoke('slib_player_notify', self, text, notify_type, length, sound)
		return
	end

	notification.AddLegacy(text, notify_type, length)

	if sound then
		surface.PlaySound(sound)
	end
end

function meta:snetIsReady()
	return self.snet_ready or false
end

function meta:slibGetActiveTool(tool_name, ignore_gmod_tool_active)
	ignore_gmod_tool_active = ignore_gmod_tool_active or false

	if not ignore_gmod_tool_active then
		local wep = LocalPlayer():GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= 'gmod_tool' then return nil end
	end

	local tool = self:GetTool()
	if not tool or not tool.GetMode or tool:GetMode() ~= tool_name then return nil end

	return tool
end

function meta:slibIsViewVector(pos, radius)
	radius = radius or 90
	local DirectionAngle = math_pi / radius
	local EntityDifference = pos - self:EyePos()
	local EntityDifferenceDot = self:GetAimVector():Dot(EntityDifference) / EntityDifference:Length()

	return EntityDifferenceDot > DirectionAngle
end

function meta:slibLanguage(data)
	return slib.language(data, self:slibGetLanguage())
end

function meta:slibGetLanguage()
	return self:slibGetVar('slib_client_language', 'english')
end