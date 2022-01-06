local access = slib.Components.Access
local gcvars = slib.Components.GlobalCvar
local cvar_locker = {}

local function AddLockTime(cvar_name, time)
	cvar_locker[cvar_name] = cvar_locker[cvar_name] or 0
	cvar_locker[cvar_name] = CurTime() + time
end

local function IsLock(cvar_name)
	cvar_locker[cvar_name] = cvar_locker[cvar_name] or 0
	return cvar_locker[cvar_name] >= CurTime()
end

local function ChangeValue(cvar_name, value, lock_time)
	lock_time = lock_time or 0

	AddLockTime(cvar_name, lock_time + .2)

	timer.Create('slib_gcvars_change_value_timer_' .. cvar_name, .1, 1, function()
		RunConsoleCommand(cvar_name, value)
	end)
end

snet.RegisterCallback('slib_gcvars_register', function(_, cvars_table)
	-- slib.Storage.GlobalCvar = cvars_table

	for cvar_name, cvar_data in pairs(slib.Storage.GlobalCvar) do
		if not tobool(GetConVar(cvar_name)) then
			ErrorNoHalt('The global variable must be created on both the server and client!')
			continue
		else
			if cvars_table and cvars_table[cvar_name] then
				cvar_data.flag = cvars_table[cvar_name].flag or cvar_data.flag
				cvar_data.helptext = cvars_table[cvar_name].helptext or cvar_data.helptext
				cvar_data.value = cvars_table[cvar_name].value or cvar_data.value
			end

			RunConsoleCommand(cvar_name, cvar_data.value)
			MsgN('Successful cvar sync for client! CVAR [' .. cvar_name .. '] - ' .. cvar_data.value)
		end

		cvar_locker[cvar_name] = cvar_locker[cvar_name] or 0

		cvars.AddChangeCallback(cvar_name, function(convar_name, value_old, value_new)
			if value_old == value_new then return end
			if IsLock(cvar_name) then return end

			local ply = LocalPlayer()

			if not access.IsValid(ply, cvar_data.access) then
				ChangeValue(cvar_name, value_old, .3)

				local text = slib.language({
					['default'] = 'Insufficient rights to make changes',
					['russian'] = 'Недостаточно прав для внесения изменений'
				})

				notification.AddLegacy(text, NOTIFY_ERROR, 4)
				return
			end

			gcvars.Update(convar_name)
			snet.InvokeServer('slib_gcvars_change_from_server', convar_name, value_new)
		end, 'slib_gcvars_client_on_change_' .. cvar_name)
	end
end)

snet.RegisterCallback('slib_gcvars_change_from_client', function(_, cvar_name, value)
	ChangeValue(cvar_name, value, .3)
	-- slib.DebugLog('Server update cvar - ', cvar_name, ' (', value, ')')
end)