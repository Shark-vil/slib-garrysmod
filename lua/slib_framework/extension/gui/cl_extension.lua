local sgui = sgui
local COLOR_FAILED = Color(255, 210, 60)
--

local function GetRootPanel(panel)
	local parentPanel = panel:GetParent()
	local subParentPanel

	if parentPanel then
		subParentPanel = GetRootPanel(parentPanel)
	end

	if subParentPanel and subParentPanel:GetClassName() ~= 'CGModBase' then
		return subParentPanel
	end

	return parentPanel
end

function sgui.SystemParentExtension(PANEL)
	PANEL.sgui_is_pressed = false
	PANEL.sgui_validators = {}
	PANEL.sgui_default_binded = {}

	local function IsValidatorFalied(panel, value)
		if not panel then return false end

		local validators = panel.sgui_validators
		if not validators then return false end

		for i = 1, #validators do
			local func = validators[i]
			if func(panel, value) == false then return true end
		end

		return false
	end

	local function IsFailedChangeValue(panel, value)
		if IsValidatorFalied(panel, value) then
			local NotifyPanel = vgui.Create('DNotify')
			NotifyPanel:SetPos(ScrW() - 270, ScrH() - 60)
			NotifyPanel:SetSize(240, 40)
			NotifyPanel:MakePopup()
			NotifyPanel:SetMouseInputEnabled(false)
			NotifyPanel:SetKeyboardInputEnabled(false)

			local bg = vgui.Create('DPanel', NotifyPanel)
			bg:Dock(FILL)
			bg:SetBackgroundColor(Color(64, 64, 64))

			local lbl = vgui.Create('DLabel', bg)
			lbl:SetPos(10, 10)
			lbl:Dock(FILL)
			lbl:DockMargin(10, 5, 10, 5)
			lbl:SetText('Editable field cannot have this value!')
			lbl:SetTextColor(COLOR_FAILED)
			lbl:SetFont('Trebuchet18')
			lbl:SetWrap(true)

			NotifyPanel:AddItem(bg)

			surface.PlaySound('common/warning.wav')
			return true
		end
	end

	function PANEL:IsPressedPanel()
		return self.sgui_is_pressed
	end

	function PANEL:AddValidator(func)
		if not func or not isfunction(func) then return end
		table.insert(self.sgui_validators, func)
	end

	function PANEL:Bind(key_name)
		if not self.SetValue then return end

		local rootpanel = GetRootPanel(self)
		if not rootpanel then return end

		local DataContext = rootpanel.DataContext
		if not DataContext or not DataContext[key_name] then return end

		self.sgui_default_binded[key_name] = self.sgui_default_binded[key_name] or DataContext[key_name]

		self:AddListener('OnValueChange', function(panel, value)
			if IsFailedChangeValue(panel, value) then
				DataContext[key_name] = self.sgui_default_binded[key_name]	
				return
			end

			DataContext[key_name] = value
		end)

		self:AddListener('OnValueChanged', function(panel, value)
			if IsFailedChangeValue(panel, value) then
				DataContext[key_name] = self.sgui_default_binded[key_name]
				return
			end

			DataContext[key_name] = value
		end)

		self:AddListener('OnChange', function(panel, value)
			if value == nil and panel.GetValue then
				value = panel:GetValue()

				if IsFailedChangeValue(panel, value) then
					DataContext[key_name] = self.sgui_default_binded[key_name]
					return
				end
			end

			DataContext[key_name] = value
		end)

		self:AddListener('OnSelect', function(panel, index, value, data)
			if IsFailedChangeValue(panel, value) then
				DataContext[key_name] = self.sgui_default_binded[key_name]
				return
			end

			if data == nil then
				DataContext[key_name] = value
			else
				DataContext[key_name] = data
			end
		end)

		self:SetValue( DataContext[key_name] )
	end
end