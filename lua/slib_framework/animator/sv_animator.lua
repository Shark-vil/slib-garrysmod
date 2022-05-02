function slib.Animator.Stop(entity)
	local _, active_animation = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
		return IsValid(v.animator) and v.entity == entity
	end)

	if active_animation then
		if isfunction(active_animation.OnStop) then active_animation.OnStop(entity) end
		active_animation.animator:Remove()
		snet.InvokeAll('slib_animator_destroyed', active_animation)
		slib.Animator.ClearInactive()
	end
end

function slib.Animator.Play(name, sequence, entity, settings, data)
	if not name or not IsValid(entity) then return false end

	local animation_data = slib.Animator.GetAnimation(name)
	if util.IsValidModel(name) then
		animation_data = {
			name = name,
			model = name,
		}
	elseif not animation_data then
		return false
	end

	settings = settings or {}
	data = data or {}

	slib.Animator.Stop(entity)

	timer.Stop('SlibraryAnimatorGarbage')

	local animator = ents.Create('prop_dynamic')
	animator:SetModel(animation_data.model)
	-- Invisible Material - https://steamcommunity.com/workshop/filedetails/?id=576040807
	animator:SetMaterial('invisible')
	animator:SetPos(entity:GetPos())
	animator:SetAngles(entity:GetAngles())
	animator:SetModelScale(entity:GetModelScale())
	if settings.move_towards then
		animator:slibCreateTimer('lerp_movement', .1, 0, function()
			if not IsValid(entity) then return end
			animator:slibMoveTowardsPosition(entity:GetPos(), 1000 * slib.deltaTime)
			animator:slibMoveTowardsAngles(entity:GetAngles(), 1000 * slib.deltaTime)
		end)
	elseif not settings.not_parent then
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
		return false
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

	sequence_duration = isnumber(settings.time) and settings.time or sequence_duration
	animator:slibSetVar('animation_time', sequence_duration)

	local anim_info = {
		animator = animator,
		entity = entity,
		name = name,
		sequence = sequence,
		sequence_id = sequence_id,
		time = sequence_duration,
		stop_time = CurTime() + sequence_duration,
		is_played = false,
		is_player = entity:IsPlayer(),
		is_npc = entity:IsNPC(),
		is_next_bot = entity:IsNextBot(),
		settings = settings,
		data = data,
	}

	table.insert(slib.Storage.ActiveAnimations, anim_info)
	hook.Run('Slib_PrePlayAnimation', anim_info)
	timer.Start('SlibraryAnimatorGarbage')

	snet.Request('slib_animator_create_clientside_model', anim_info)
		.Complete(function()
			local timer_name = 'animator_' .. animator:EntIndex()
			local timer_duration = sequence_duration + .1

			animator:slibCreateTimer(timer_name, timer_duration, 1, function()
				if settings.loop then
					anim_info.stop_time = CurTime() + sequence_duration
				else
					local index, _ = table.WhereFindBySeq(slib.Storage.ActiveAnimations, function(_, v)
						return v.entity == entity
					end)

					if index ~= -1 then
						table.remove(slib.Storage.ActiveAnimations, index)
					end

					animator:Remove()
				end
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