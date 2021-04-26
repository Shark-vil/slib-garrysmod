function sgui.Construct(PANEL)
	sgui.SystemParentListener(PANEL)
	sgui.SystemParentExtension(PANEL)
	sgui.SystemParentDefaultListeners(PANEL)
end

local function Initialize()
	local original_vgui_create = vgui.Create

	function vgui.Create(classname, parent, name)
		local PANEL = original_vgui_create(classname, parent, name)
		if PANEL then sgui.Construct(PANEL) end
		return PANEL
	end

	hook.Remove('PreGamemodeLoaded', 'SguiInitializeVguiExtension')
end
hook.Add('PreGamemodeLoaded', 'SguiInitializeVguiExtension', Initialize)