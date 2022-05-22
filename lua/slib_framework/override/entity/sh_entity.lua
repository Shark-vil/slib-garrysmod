local snet = slib.Components.Network
local SERVER = SERVER
local table = table
local timer = timer
local istable = istable
local ipairs = ipairs
local isfunction = isfunction
local isentity = isentity
local IsValid = IsValid
local isbool = isbool
local LocalPlayer = LocalPlayer
local player_GetAll = player.GetAll
local util_TraceLine = util.TraceLine
local math_pi = math.pi
--
local meta = FindMetaTable('Entity')
local list_door_classes = {'func_door', 'func_door_rotating', 'prop_door_rotating'}

function meta:slibSetLocalVar(key, value)
	self.slibLocalVariables = self.slibLocalVariables or {}
	self.slibLocalVariables[key] = value
	return self.slibLocalVariables[key]
end

function meta:slibGetLocalVar(key, fallback, assign_a_fallback)
	if not self.slibLocalVariables or self.slibLocalVariables[key] == nil then
		if assign_a_fallback and fallback ~= nil then
			return self:slibSetVar(key, fallback)
		end
		return fallback
	end
	return self.slibLocalVariables[key]
end

function meta:slibSetVar(key, value, unreliable)
	if not snet.ValueIsValid(value) then return end

	self.slibVariables = self.slibVariables or {}
	self.slibVariablesChangeCallback = self.slibVariablesChangeCallback or {}
	self.slibVariablesSetCallback = self.slibVariablesSetCallback or {}
	self.slibVariablesInstanceCallback = self.slibVariablesInstanceCallback or {}

	if not self or not istable(self.slibVariables) then return end

	local old_value = self.slibVariables[key]
	local new_value = value

	if old_value ~= nil and old_value == new_value then return end

	if old_value ~= nil and old_value ~= new_value and self.slibVariablesChangeCallback[key] ~= nil then
		for _, func in ipairs(self.slibVariablesChangeCallback[key]) do
			func(old_value, new_value)
		end
	end

	if self.slibVariables[key] == nil and self.slibVariablesInstanceCallback[key] then
		for _, func in ipairs(self.slibVariablesInstanceCallback[key]) do
			func(new_value)
		end
	end

	self.slibVariables[key] = new_value

	if self.slibVariablesSetCallback[key] then
		for _, func in ipairs(self.slibVariablesSetCallback[key]) do
			func(old_value, new_value)
		end
	end

	if SERVER then
		unreliable = unreliable or false

		if new_value == nil then
			snet.Request('slib_entity_variable_del', self, key).InvokeAll(unreliable)
		else
			snet.Request('slib_entity_variable_set', self, key, value).InvokeAll(unreliable)
		end
	end

	return self.slibVariables[key]
end

function meta:slibGetVar(key, fallback, assign_a_fallback)
	if not self.slibVariables or self.slibVariables[key] == nil then
		if assign_a_fallback and fallback ~= nil then
			return self:slibSetVar(key, fallback)
		end
		return fallback
	end
	return self.slibVariables[key]
end

function meta:slibOnInstanceVarCallback(key, func)
	if not isfunction(func) then return end
	self.slibVariablesInstanceCallback = self.slibVariablesInstanceCallback or {}
	self.slibVariablesInstanceCallback[key] = self.slibVariablesInstanceCallback[key] or {}
	table.insert(self.slibVariablesInstanceCallback[key], func)
end

function meta:slibAddSetVarCallback(key, func)
	if not isfunction(func) then return end
	self.slibVariablesSetCallback = self.slibVariablesSetCallback or {}
	self.slibVariablesSetCallback[key] = self.slibVariablesSetCallback[key] or {}
	table.insert(self.slibVariablesSetCallback[key], func)
end

function meta:slibAddChangeVarCallback(key, func)
	if not isfunction(func) then return end
	self.slibVariablesChangeCallback = self.slibVariablesChangeCallback or {}
	self.slibVariablesChangeCallback[key] = self.slibVariablesChangeCallback[key] or {}
	table.insert(self.slibVariablesChangeCallback[key], func)
end

function meta:slibCreateTimer(timer_name, delay, repetitions, func)
	timer_name = 'SLIB_ENTITY_TIMER_' .. util.CRC(self:EntIndex() .. timer_name)

	timer.Create(timer_name, delay, repetitions, function()
		if not IsValid(self) then
			timer.Remove(timer_name)
			return
		end

		func(self)
	end)
end

function meta:slibExistsTimer(timer_name)
	timer_name = 'SLIB_ENTITY_TIMER_' .. util.CRC(self:EntIndex() .. timer_name)
	return timer.Exists(timer_name)
end

function meta:slibRemoveTimer(timer_name)
	timer_name = 'SLIB_ENTITY_TIMER_' .. util.CRC(self:EntIndex() .. timer_name)

	if timer.Exists(timer_name) then
		timer.Remove(timer_name)
	end
end

function meta:slibIsDoor()
	return table.HasValueBySeq(list_door_classes, self:GetClass())
end

function meta:slibDoorIsLocked()
	if not self:slibIsDoor() then return true end

	local result = self:GetInternalVariable('m_bLocked')
	if isbool(result) then return result end

	return true
end

function meta:slibSinglePlayerWatching(ply)
	if IsValid(ply) then
		return ply:slibIsViewVector(position)
	end
	return false
end

function meta:slibPlayersWatching()
	local players = player_GetAll()
	for i = 1, #players do
		local ply = players[i]
		if IsValid(ply) and ply:slibIsViewVector(position) then return true end
	end
	return false
end

function meta:slibAutoDestroy(time)
	self:slibCreateTimer('_system_timer_slib_auto_destroy_entity_', time, 1, function()
		self:Remove()
	end)
end

function meta:slibFadeRemove(minus)
	if self.slibIsFadeRemove then return end
	self.slibIsFadeRemove = true

	minus = minus or 1

	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:slibCreateTimer('_system_entity_fade_remove_', 0.01, 0, function()
		local color = self:GetColor()
		if color.a - minus >= 0 then
			local newColor = ColorAlpha(color, color.a - minus)
			self:SetColor(newColor)
			if self.GetActiveWeapon then
				local weapon = self:GetActiveWeapon()
				if IsValid(weapon) then
					weapon:SetColor(newColor)
				end
			end
		else
			self:Remove()
		end
	end)
end

function meta:slibAddHook(hook_type, hook_name, func)
	hook_name = 'slib_system_entity_' .. hook_type .. '_' .. hook_name .. '_' .. tostring(self:EntIndex())
	hook.Add(hook_type, hook_name, function(...)
		if not IsValid(self) then
			hook.Remove(hook_type, hook_name)
			return
		end
		func(...)
	end)
end

function meta:slibRemoveHook(hook_type, hook_name)
	hook_name = 'slib_system_entity_' .. hook_type .. '_' .. hook_name .. '_' .. tostring(self:EntIndex())
	hook.Remove(hook_type, hook_name)
end

function meta:slibIsSingleCall()
	local delay = self:slibGetLocalVar('slib_is_single_call_delay', 0)
	self:slibSetLocalVar('slib_is_single_call_delay', RealTime() + 0.1)
	return delay < RealTime()
end

function snet.ClientRPC(_ent, function_name, ...)
	if not SERVER then return end

	local ent = _ent

	if not isentity(ent) and ent.Weapon then
		ent = ent.Weapon
	end

	if not ent or not IsValid(ent) then return end
	local ply
	local owner = ent:GetOwner()

	if IsValid(owner) and owner:IsPlayer() then
		ply = owner
	end

	if ply and ent:GetClass() == 'gmod_tool' then
		local tool = ply:GetTool()
		snet.Invoke('snet_entity_tool_call_client_rpc', ply, ent, tool:GetMode(), function_name, ...)
	else
		if ply then
			snet.Invoke('snet_entity_call_client_rpc', ply, ent, function_name, ...)
		else
			snet.InvokeAll('snet_entity_call_client_rpc', ent, function_name, ...)
		end
	end
end

function meta:slibClientRPC(function_name, ...)
	snet.ClientRPC(self, function_name, ...)
end

function meta:slibPredictedClientRPC(function_name, ...)
	if not IsFirstTimePredicted() then return end
	snet.ClientRPC(self, function_name, ...)
end

function meta:slibMoveTowardsPosition(target_vector, max_distance_delta)
	local new_vector = slib.MoveTowardsVector(self:GetPos(), target_vector, max_distance_delta)
	self:SetPos(new_vector)
end

function meta:slibMoveTowardsAngles(target_angle, max_distance_delta)
	local new_angle = slib.MoveTowardsVector(self:GetAngles(), target_angle, max_distance_delta)
	self:SetAngles(new_angle)
end

function meta:slibIsViewVector(pos, radius)
	local view_entity

	if self.GetViewEntity then
		view_entity = self:GetViewEntity()
	else
		view_entity = self
	end

	if not view_entity.EyePos or not view_entity.GetAimVector then return true end
	radius = radius or 90

	local DirectionAngle = math_pi / radius
	local EntityDifference = pos - view_entity:EyePos()
	local EntityDifferenceDot = view_entity:GetAimVector():Dot(EntityDifference) / EntityDifference:Length()

	return EntityDifferenceDot > DirectionAngle
end

function meta:slibIsTraceEntity(target, distance, check_view_vector)
	if not IsValid(target) then return false end

	distance = distance or 1000

	local target_pos = target:LocalToWorld(target:OBBCenter())
	local eye_pos

	if self.EyePos then
		eye_pos = self:EyePos()
	else
		local obb_center = self:OBBCenter()
		obb_center.z = self:OBBMaxs().z
		eye_pos = self:LocalToWorld(obb_center)
	end

	if check_view_vector and not self:slibIsViewVector(target_pos) then return false end

	local tr = util_TraceLine({
		start = eye_pos,
		endpos = target_pos,
		filter = function(ent)
			if ent ~= self then return true end
		end
	})

	return tr.Hit and tr.Entity == target
end

function snet.ServerRPC(_ent, function_name, ...)
	if not CLIENT then return end

	local ent = _ent

	if not isentity(ent) and ent.Weapon then
		ent = ent.Weapon
	end

	if not ent or not IsValid(ent) then return end

	local owner = ent:GetOwner()
	if IsValid(owner) and owner:IsPlayer() and owner ~= LocalPlayer() then return end

	if ent:GetClass() == 'gmod_tool' then
		local tool = LocalPlayer():GetTool()
		snet.InvokeServer('snet_entity_tool_call_server_rpc', ent, tool:GetMode(), function_name, ...)
	else
		snet.InvokeServer('snet_entity_call_server_rpc', ent, function_name, ...)
	end
end

function meta:slibServerRPC(function_name, ...)
	snet.ServerRPC(self, function_name, ...)
end

function meta:slibPredictedServerRPC(function_name, ...)
	if not IsFirstTimePredicted() then return end
	snet.ServerRPC(self, function_name, ...)
end