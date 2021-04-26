local function ExecuteListener(panel, action_name, ...)
	local listeners = panel.sgui_listeners[action_name]
	for _, f in ipairs(listeners) do
		f(...)
	end
end

function sgui.SystemParentListener(PANEL)
	PANEL.sgui_listeners_enabled = {}
	PANEL.sgui_listeners = {}

	function PANEL:AddListener(action_name, func)
		self.sgui_listeners[action_name] = self.sgui_listeners[action_name] or {}

		table.insert(self.sgui_listeners[action_name], func)

		if not self.sgui_listeners_enabled[action_name] then
			self[action_name] = function(...)
				ExecuteListener(self, action_name, ...)
			end
			self.sgui_listeners_enabled[action_name] = true
		end
	end

	function PANEL:ClearListeners(action_name)
		if not self.sgui_listeners_enabled[action_name] then return end
		self.sgui_listeners_enabled[action_name] = false
		self.sgui_listeners = {}
		self[action_name] = nil
	end
end