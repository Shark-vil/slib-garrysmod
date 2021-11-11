snet.RegisterCallback('slib_animator_destroyed', function(_, ent)
	slib.Animator.ClearInactive(ent)
end).Validator(SNET_ENTITY_VALIDATOR)

snet.Callback('slib_animator_create_clientside_model', function(ply, entity, animator, name, time)
	if not IsValid(entity) or not IsValid(animator) then return end

	local position = animator:GetPos()
	local rotation = animator:GetAngles()
	local animation_model = ClientsideModel(entity:GetModel(), RENDERGROUP_OPAQUE)
	animation_model:SetPos(position)
	animation_model:SetAngles(rotation)
	animation_model:SetOwner(animator)
	animation_model:SetParent(animator)
	animation_model:AddEffects(EF_BONEMERGE)
	animation_model:SetNoDraw(true)
	-- animation_model:DrawShadow(true)

	for _, bodygroup in ipairs(entity:GetBodyGroups()) do
		local id = bodygroup.id
		animation_model:SetBodygroup(id, entity:GetBodygroup(id))
	end

	animation_model:SetSkin(entity:GetSkin())

	local weapon_model
	local weapon = entity:GetActiveWeapon()
	local r_hand = animator:LookupBone('ValveBiped.Bip01_R_Hand')
	if IsValid(weapon) and r_hand then
		local b_pos, b_ang = animator:GetBonePosition(r_hand)
		weapon_model = ClientsideModel(weapon:GetModel(), RENDERGROUP_OPAQUE)
		if IsValid(weapon_model) then
			weapon_model:SetPos(b_pos)
			weapon_model:SetAngles(b_ang)
			weapon_model:SetOwner(animator)
			weapon_model:SetParent(animator)
			weapon_model:SetNoDraw(true)
		end
	end

	table.insert(slib.Storage.ActiveAnimations, {
		animator = animator,
		model = animation_model,
		weapon_model = weapon_model,
		r_hand_bone_index = r_hand,
		weapon = weapon,
		entity = entity,
		material = entity:GetMaterial(),
		name = name,
		time = time,
		is_played = false,
		is_player = entity:IsPlayer(),
		is_npc = entity:IsNPC(),
		is_next_bot = entity:IsNextBot(),
	})
end).Validator(SNET_ENTITY_VALIDATOR)

snet.Callback('slib_animator_play', function(ply, _animator)
	if not IsValid(_animator) then return end

	for i = 1, #slib.Storage.ActiveAnimations do
		local value = slib.Storage.ActiveAnimations[i]
		if value.animator == _animator then
			local entity = value.entity
			local model = value.model
			local weapon_model = value.weapon_model
			local animator = value.animator
			local material = value.material
			local weapon = value.weapon

			model:SetNoDraw(false)
			entity:SetMaterial('invisible')
			animator:ResetSequence(value.name)
			animator:SetNoDraw(true)
			if IsValid(weapon) then
				weapon:SetNoDraw(true)
			end

			value.is_played = true

			timer.Create('animator_' .. slib.UUID(), value.time, 1, function()
				if IsValid(weapon_model) then weapon_model:Remove() end
				if IsValid(model) then model:Remove() end
				if IsValid(entity) then entity:SetMaterial(material) end
				if IsValid(weapon) then weapon:SetNoDraw(false) end
			end)

			break
		end
	end
end).Validator(SNET_ENTITY_VALIDATOR)