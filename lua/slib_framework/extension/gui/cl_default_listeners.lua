local sgui = slib.Components.GUI
local isfunction = isfunction
--

function sgui.SystemParentDefaultListeners(PANEL)
	PANEL:AddListener('Think', function(self)
		if not self then return end
		if not self.OnChangeHovered or not isfunction(self.OnChangeHovered) then return end

		local is_hovered = self:IsHovered()

		if self.sgui_OldHovered == nil then self.sgui_OldHovered = is_hovered end

		if self.sgui_OldHovered ~= is_hovered then
			self.OnChangeHovered(self, self.sgui_OldHovered, not self.sgui_OldHovered)
			self.sgui_OldHovered = is_hovered
		end
	end)

	PANEL:AddListener('DoClick', function(self)
		if not self then return end
		if not self.sgui_sound_click or not isstring(self.sgui_sound_click) then return end
		surface.PlaySound(self.sgui_sound_click)
	end)

	PANEL:AddListener('OnChangeHovered', function(self, _, is_hovered)
		if not self then return end
		if not self.sgui_sound_switch_hovered or not isstring(self.sgui_sound_switch_hovered) then return end
		if not is_hovered then return end
		surface.PlaySound(self.sgui_sound_switch_hovered)
	end)

	PANEL:AddListener('OnDepressed', function(self)
		if not self then return end
		self.sgui_is_pressed = true
	end)

	PANEL:AddListener('OnReleased', function(self)
		if not self then return end
		self.sgui_is_pressed = false
	end)
end