local sgui = slib.Components.GUI
--

function sgui.Construct(PANEL)
	if PANEL.sgui_init then return end

	sgui.SystemParentListener(PANEL)
	sgui.SystemParentExtension(PANEL)
	sgui.SystemParentDefaultListeners(PANEL)

	PANEL.sgui_init = true
end

function sgui.Create(...)
	local PANEL = vgui.Create(...)
	if PANEL then sgui.Construct(PANEL) end
	return PANEL
end

function sgui.CreateFromTable(...)
	local PANEL = vgui.CreateFromTable(...)
	if PANEL then sgui.Construct(PANEL) end
	return PANEL
end

function sgui.CreateX(...)
	local PANEL = vgui.CreateX(...)
	if PANEL then sgui.Construct(PANEL) end
	return PANEL
end