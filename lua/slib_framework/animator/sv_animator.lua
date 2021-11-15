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

	return active_animation and active_animation.name == name
end

function slib.Animator.Play(name, sequence, entity, settings)
	if not name or not IsValid(entity) then return end

	local animation_data = slib.Animator.GetAnimation(name)
	if not animation_data then return end

	settings = settings or {}

	slib.Animator.Stop(entity)

	timer.Stop('SlibraryAnimatorGarbage')

	local animator = ents.Create('prop_dynamic')
	animator:SetModel(animation_data.model)
	-- Invisible Material - https://steamcommunity.com/workshop/filedetails/?id=576040807
	animator:SetMaterial('invisible')
	animator:SetPos(entity:GetPos())
	animator:SetAngles(entity:GetAngles())
	if not settings.not_parent then
		animator:SetParent(entity)
	end
	if not settings.collision then
		animator:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end
	animator:slibSetVar('sequence', sequence)
	animator:Spawn()

	local sequence_id, sequence_duration = animator:LookupSequence(sequence)
	if sequence_id == -1 then
		animator:Remove()
		return
	end

	entity.slib_animator = animator

	if settings.compare_bones then
		for i = 0, animator:GetBoneCount() - 1 do
			local bonename = animator:GetBoneName(i)
			if not entity:LookupBone(bonename) then
				animator:Remove()
				return false
			end
		end
	end

	animator:slibSetVar('animation_time', sequence_duration)

	local anim_info = {
		animator = animator,
		entity = entity,
		name = name,
		sequence = sequence,
		time = sequence_duration,
		is_played = false,
		is_player = entity:IsPlayer(),
		is_npc = entity:IsNPC(),
		is_next_bot = entity:IsNextBot(),
		settings = settings,
	}

	table.insert(slib.Storage.ActiveAnimations, anim_info)
	hook.Run('Slib_PrePlayAnimation', anim_info)
	timer.Start('SlibraryAnimatorGarbage')

	snet.Request('slib_animator_create_clientside_model', entity, animator, name, sequence_id, sequence_duration)
		.Complete(function()
			animator:slibCreateTimer('animator_' .. animator:EntIndex(), sequence_duration + .1, 1, function()
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
			end
		end).InvokeAll()

		return anim_info
end