hook.Add('Think', 'SlibAnimatorFlexController', function()
	for i = 1, #slib.Storage.ActiveAnimations do
		local value = slib.Storage.ActiveAnimations[i]
		if not value.is_played then continue end

		local model = value.model
		local entity = value.entity
		local animator = value.animator
		local weapon = value.weapon
		local weapon_model = value.weapon_model

		if not IsValid(model) or not IsValid(animator) or not IsValid(entity) then continue end

		-- for k = 0, model:GetFlexNum() - 1 do
		-- 	model:SetFlexWeight(i, entity:GetFlexWeight(k))
		-- 	model:SetFlexScale(i, entity:GetFlexScale(k))
		-- end

		local current_weapon = entity:GetActiveWeapon()
		if IsValid(current_weapon) and IsValid(weapon_model) and current_weapon ~= weapon then
			if IsValid(weapon) then weapon:SetNoDraw(false) end
			current_weapon:SetNoDraw(true)

			weapon_model:SetModel(current_weapon:GetModel())
			for _, bodygroup in ipairs(current_weapon:GetBodyGroups()) do
				local id = bodygroup.id
				weapon_model:SetBodygroup(id, current_weapon:GetBodygroup(id))
			end
			weapon_model:SetSkin(current_weapon:GetSkin())

			value.weapon = current_weapon
		end
	end
end)