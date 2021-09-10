local snet = snet
local IsValid = IsValid
--

snet.RegisterCallback('snet_entity_tool_call_server_rpc', function(ply, ent, tool_mode, func_name, ...)
	if not ent or not IsValid(ent) or ent:GetClass() ~= 'gmod_tool' then return end

	local owner = ent:GetOwner()
	if IsValid(owner) and owner:IsPlayer() and owner ~= ply then return end

	local tool = ply:GetTool()
	if tool:GetMode() ~= tool_mode then return end

	local func = tool[func_name]
	if not func then return end

	func(tool, ...)
end)

snet.RegisterCallback('snet_entity_call_server_rpc', function(ply, ent, func_name, ...)
	if not ent or not IsValid(ent) then return end

	local owner = ent:GetOwner()
	if IsValid(owner) and owner:IsPlayer() and owner ~= ply then return end

	local func = ent[func_name]
	if not func then return end

	func(ent, ...)
end)