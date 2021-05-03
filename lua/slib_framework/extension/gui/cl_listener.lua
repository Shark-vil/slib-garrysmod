local function ExecuteListener(panel, action_name, ...)
	local listeners = panel.sgui_listeners[action_name]
	for i = 1, #listeners do listeners[i](...) end
end

function sgui.SystemParentListener(PANEL)
	PANEL.sgui_listeners_enabled = {}
	PANEL.sgui_listeners = {}

	function PANEL:AddListener(action_name, func)
		if type(func) ~= 'function' or type(action_name) ~= 'string' then return end

		self.sgui_listeners[action_name] = self.sgui_listeners[action_name] or {}

		if not self.sgui_listeners_enabled[action_name] then
			local original_action = self[action_name]
			if type(original_action) == 'function' then
				table.insert(self.sgui_listeners[action_name], original_action)
			end

			self[action_name] = function(...)
				ExecuteListener(self, action_name, ...)
			end

			self.sgui_listeners_enabled[action_name] = true
		end

		table.insert(self.sgui_listeners[action_name], func)
	end

	function PANEL:ClearListeners(action_name)
		if not self.sgui_listeners_enabled[action_name] then return end
		self.sgui_listeners_enabled[action_name] = false
		self.sgui_listeners = {}
		self[action_name] = nil
	end
end