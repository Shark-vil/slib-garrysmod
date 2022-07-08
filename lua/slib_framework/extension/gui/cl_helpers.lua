local sgui = slib.Components.GUI
local ScrW = ScrW
local ScrH = ScrH
local Material = Material
local Color = Color
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
local spawnmenu_AddContentType = spawnmenu.AddContentType
local original_DermaMenu = DermaMenu
--
local m_blur_material = Material('pp/blurscreen')
local m_blur_color = Color(255, 255, 255)
local m_blur_key = '$blur'

function sgui.DrawBlurBackground(panel, amount, passages)
	local x, y = panel:LocalToScreen(0, 0)
	local screen_width, screen_height = ScrW(), ScrH()

	amount = amount or 0

	surface_SetDrawColor(m_blur_color)
	surface_SetMaterial(m_blur_material)

	for i = 1, passages do
		m_blur_material:SetFloat(m_blur_key, (i / 3) * amount)
		m_blur_material:Recompute()

		render_UpdateScreenEffectTexture()
		surface_DrawTexturedRect(x * -1, y * -1, screen_width, screen_height)
	end
end

function spawnmenu.AddContentType(name, constructor)
	spawnmenu_AddContentType(name, function(container, obj)
		local new_icon = hook.Run('slib.PreSpawnmenuAddContentType', name, container, obj)
		if new_icon then return new_icon end

		local icon = constructor(container, obj)

		new_icon = hook.Run('slib.PostSpawnmenuAddContentType', name, icon, container, obj)
		if new_icon then return new_icon end

		return icon
	end)
end

function DermaMenu(keepOpen, parent)
	local debug_info = debug.getinfo(2, 'S')
	local caller_script_path = ''

	if debug_info and debug_info.short_src then
		caller_script_path = debug_info.short_src
	end

	local menu = original_DermaMenu(keepOpen, parent)

	hook.Run('slib.CreateDermaMenu', menu, keepOpen, parent, caller_script_path)

	return menu
end