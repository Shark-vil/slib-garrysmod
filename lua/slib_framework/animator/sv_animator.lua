function slib.Animator.Play(name, entity, compare_bones)
	compare_bones = compare_bones or false

	if not name then return false end

	local animation_data = slib.Animator.GetAnimation(name)
	if not animation_data or not IsValid(entity) then return false end

	local animator = ents.Create('prop_dynamic')
	animator:SetModel(animation_data.model)
	-- Invisible Material - https://steamcommunity.com/workshop/filedetails/?id=576040807
	animator:SetMaterial('invisible')
	animator:SetPos(entity:GetPos())
	animator:SetAngles(entity:GetAngles())
	if not entity:IsPlayer() then
		animator:SetParent(entity)
	end
	animator:slibSetVar('sequence', animation_data.sequence)
	animator:Spawn()

	entity:slibSetVar('slib_associated_with_animator', true)

	if compare_bones then
		for i = 0, animator:GetBoneCount() - 1 do
			local bonename = animator:GetBoneName(i)
			if not entity:LookupBone(bonename) then
				animator:Remove()
				return false
			end
		end
	end

	local animation_time = animator:SequenceDuration(name)
	animator:slibSetVar('animation_time', animation_time)

	table.insert(slib.Storage.ActiveAnimations, {
		animator = animator,
		entity = entity,
		name = name,
		time = animation_time,
		is_played = false,
		is_player = entity:IsPlayer(),
		is_npc = entity:IsNPC(),
		is_next_bot = entity:IsNextBot(),
	})

	snet.Request('slib_animator_create_clientside_model', entity, animator, name, animation_time)
		.Complete(function()
			entity:slibCreateTimer('animator_' .. animator:EntIndex(), animation_time + .5, 1, function()
				if entity:slibGetVar('slib_associated_with_animator') then
					entity:slibSetVar('slib_associated_with_animator', false)
				end

				if IsValid(animator) then animator:Remove() end

				local index, _ = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
					return v.entity == entity
				end)

				if index ~= -1 then
					table.remove(slib.Storage.ActiveAnimations, index)
				end
			end)

			local _, active_animation = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
				return v.animator == animator
			end)

			if active_animation and IsValid(animator) then
				active_animation.is_played = true
				snet.InvokeAll('slib_animator_play', animator)
			end
		end).InvokeAll()
end