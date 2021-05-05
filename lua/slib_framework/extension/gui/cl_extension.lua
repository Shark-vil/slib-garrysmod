function sgui.SystemParentExtension(PANEL)
	PANEL.sgui_is_pressed = false

	function PANEL:IsPressedPanel()
		return self.sgui_is_pressed
	end
end