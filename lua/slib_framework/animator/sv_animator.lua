function slib.Animator.Stop(entity)
	local _, active_animation = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
		return IsValid(v.animator) and v.entity == entity
	end)

	if active_animation then
		active_animation.animator:Remove()
		snet.InvokeAll('slib_animator_destroyed', entity)
		slib.Animator.ClearInactive()
	end
end

function slib.Animator.IsPlay(name, entity)
	local _, active_animation = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
		return IsValid(v.animator) and v.entity == entity
	end)

	return active_animation.name == name
end

function slib.Animator.Play(name, entity, compare_bones, not_prent)
	compare_bones = compare_bones or false

	if not name then return end

	local animation_data = slib.Animator.GetAnimation(name)
	if not animation_data or not IsValid(entity) then return end

	slib.Animator.Stop(entity)

	timer.Stop('SlibraryAnimatorGarbage')

	local animator = ents.Create('prop_dynamic')
	animator:SetModel(animation_data.model)
	-- Invisible Material - https://steamcommunity.com/workshop/filedetails/?id=576040807
	animator:SetMaterial('invisible')
	animator:SetPos(entity:GetPos())
	animator:SetAngles(entity:GetAngles())
	if not not_prent then
		animator:SetParent(entity)
	end
	animator:SetCollisionGroup(COLLISION_GROUP_WORLD)
	animator:slibSetVar('sequence', animation_data.sequence)
	animator:Spawn()

	entity.slib_animator = animator

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

	local anim_info = {
		animator = animator,
		entity = entity,
		name = name,
		time = animation_time,
		not_prent = not_prent,
		is_played = false,
		is_player = entity:IsPlayer(),
		is_npc = entity:IsNPC(),
		is_next_bot = entity:IsNextBot(),
	}

	table.insert(slib.Storage.ActiveAnimations, anim_info)

	timer.Start('SlibraryAnimatorGarbage')

	snet.Request('slib_animator_create_clientside_model', entity, animator, name, animation_time)
		.Complete(function()
			animator:slibCreateTimer('animator_' .. animator:EntIndex(), animation_time + .5, 1, function()
				local index, _ = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
					return v.entity == entity
				end)

				if index ~= -1 then
					table.remove(slib.Storage.ActiveAnimations, index)
				end

				animator:Remove()
			end)

			local _, active_animation = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
				return v.animator == animator
			end)

			if active_animation and IsValid(animator) then
				active_animation.is_played = true
				snet.InvokeAll('slib_animator_play', animator)
				hook.Run('Slib_PlayAnimation', anim_info)
				-- animator:ResetSequence(anim_info.name)
			end
		end).InvokeAll()

		return anim_info
end