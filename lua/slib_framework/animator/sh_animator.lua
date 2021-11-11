function slib.Animator.RegisterAnimation(name, sequence, model)
	slib.Storage.Animations[name] = {
		model = Model(model),
		sequence = sequence
	}
end

function slib.Animator.GetAnimation(name)
	return slib.Storage.Animations[name]
end

function slib.Animator.ClearInactive(ent)
	for i = #slib.Storage.ActiveAnimations, 1, -1 do
		local value = slib.Storage.ActiveAnimations[i]
		local model = value.model
		local weapon_model = value.weapon_model
		local entity = value.entity
		local animator = value.animator
		local material = value.material
		local weapon = value.weapon

		if (ent and ent == entity) or not slib.IsAlive(entity) then
			if CLIENT and IsValid(weapon_model) then weapon_model:Remove() end
			if CLIENT and IsValid(model) then model:Remove() end
			if CLIENT and IsValid(entity) then entity:SetMaterial(material) end
			if CLIENT and IsValid(weapon) then weapon:SetNoDraw(false) end
			if SERVER and IsValid(animator) then animator:Remove() end

			if SERVER and IsValid(entity) and entity:slibGetVar('slib_associated_with_animator') then
				entity:slibSetVar('slib_associated_with_animator', false)
			end

			table.remove(slib.Storage.ActiveAnimations, i)
		end
	end
end