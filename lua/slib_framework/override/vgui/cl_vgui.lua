local sgui = slib.Components.GUI
--

function sgui.Construct(PANEL)
	if PANEL.sgui_init then return end

	sgui.SystemParentListener(PANEL)
	sgui.SystemParentExtension(PANEL)
	sgui.SystemParentDefaultListeners(PANEL)

	PANEL.sgui_init = true
end

local function Initialize()
	local original_vgui_Create = vgui.Create
	local original_vgui_CreateFromTable = vgui.CreateFromTable
	local original_vgui_CreateX = vgui.CreateX

	function vgui.Create(...)
		local PANEL = original_vgui_Create(...)
		if PANEL then sgui.Construct(PANEL) end
		return PANEL
	end

	function vgui.CreateFromTable(...)
		local PANEL = original_vgui_CreateFromTable(...)
		if PANEL then sgui.Construct(PANEL) end
		return PANEL
	end

	function vgui.CreateX(...)
		local PANEL = original_vgui_CreateX(...)
		if PANEL then sgui.Construct(PANEL) end
		return PANEL
	end

	hook.Remove('PreGamemodeLoaded', 'SguiInitializeVguiExtension')
end
hook.Add('PreGamemodeLoaded', 'SguiInitializeVguiExtension', Initialize)