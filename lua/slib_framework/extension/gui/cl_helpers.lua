local sgui = sgui
local surface = surface
local render = render
local Material = Material
local Color = Color
--
local m_blur_material = Material('pp/blurscreen')
local m_blur_color = Color(255, 255, 255)
local m_blur_key = '$blur'

function sgui.DrawBlurBackground(panel, amount, passages)
	local x, y = panel:LocalToScreen(0, 0)
	local screen_width, screen_height = ScrW(), ScrH()

	amount = amount or 0

	surface.SetDrawColor(m_blur_color)
	surface.SetMaterial(m_blur_material)

	for i = 1, passages do
		m_blur_material:SetFloat(m_blur_key, (i / 3) * amount)
		m_blur_material:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, screen_width, screen_height)
	end
end