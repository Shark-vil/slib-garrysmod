function slib.Animator.RegisterAnimation(name, sequence, model, act_id)
	local i, _ = table.WhereFindBySeq(slib.Storage.Animations, function(_, v) return v.name == name end)
	if i ~= -1 then table.remove(slib.Storage.Animations, i) end

	table.insert(slib.Storage.Animations, {
		name = name,
		model = Model(model),
		sequence = sequence,
		act_id = act_id,
	})
end

function slib.Animator.GetAnimation(name)
	local _, v = table.WhereFindBySeq(slib.Storage.Animations, function(_, v) return v.name == name end)
	return v
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
			value.is_played = false

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