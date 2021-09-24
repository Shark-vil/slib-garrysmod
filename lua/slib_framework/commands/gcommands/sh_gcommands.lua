local Component = slib.Components.GlobalCommand
local AccessComponent = slib.Components.Access
local client_commands = {}
local server_commands = {}

if CLIENT then
	snet.RegisterCallback('slib_global_commands_client_rpc', function(_, ply, cmd, args)
		local func = client_commands[cmd]
		if not func or not isfunction(func) then return end
		func(ply, cmd, args)
	end)
else
	snet.Callback('slib_global_commands_server_rpc', function(net_player, ply, cmd, args)
		local func = server_commands[cmd]
		if not func or not isfunction(func) then return end
		func(ply, cmd, args)
		snet.InvokeIgnore('slib_global_commands_client_rpc', net_player, ply, cmd, args)
	end).Protect()
end

function Component.Create(_name, _autoComplete, _helpText, _flags, _access)
	local private = {}
	private.name = _name
	private.client_callback = nil
	private.server_callback = nil
	private.autoComplete = _autoComplete or nil
	private.helpText = _helpText or nil
	private.flags = _flags or 0
	private.access = _access and AccessComponent:Make( _access ) or _access

	local public = {}

	function public.OnServer(func)
		private.server_callback = func
		return public
	end

	function public.OnClient(func)
		private.client_callback = func
		return public
	end

	function public.OnShared(func)
		public.OnServer(func)
		public.OnClient(func)
		return public
	end

	function public.AutoComplete(autoComplete)
		private.autoComplete = autoComplete
		return public
	end

	function public.HelpText(text)
		private.helpText = text
		return public
	end

	function public.Flags(flags)
		private.flags = flags
		return public
	end

	function public.Access(access)
		private.access = access and AccessComponent:Make( access ) or access
		return public
	end

	function public.Register()
		local name = private.name
		local access = private.access
		local server_callback = private.server_callback
		local client_callback = private.client_callback
		local autoComplete = private.autoComplete
		local helpText = private.helpText
		local flags = private.flags

		concommand.Add(name, function(ply, cmd, args)
			if not AccessComponent.IsValid(ply, access) then return end

			local isReplicate

			if SERVER then
				if server_callback and isfunction(server_callback) then
					isReplicate = server_callback(ply, cmd, args)
				end

				if isReplicate == true then
					snet.InvokeAll('slib_global_commands_client_rpc', ply, cmd, args)
				end
			else
				if client_callback and isfunction(client_callback) then
					isReplicate = client_callback(ply, cmd, args)
				end

				if isReplicate == true then
					snet.InvokeServer('slib_global_commands_server_rpc', ply, cmd, args)
				end
			end
		end, autoComplete, helpText, flags)

		return public
	end

	return public
end