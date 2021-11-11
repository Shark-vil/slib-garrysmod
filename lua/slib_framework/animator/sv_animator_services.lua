local movement_keys = {
	IN_JUMP,
	IN_FORWARD,
	IN_BACK,
	IN_MOVELEFT,
	IN_MOVERIGHT,
	IN_WALK,
	IN_SPEED,
	IN_RUN
}

hook.Add('Move', 'SlibOverrideAnimatorPlayerMovement', function(ply, mv)
	for i = #slib.Storage.ActiveAnimations, 1, -1 do
		local value = slib.Storage.ActiveAnimations[i]
		local entity = value.entity

		if not value.is_player and entity ~= ply then continue end

		for k = 1, #movement_keys do
			if mv:KeyDown(movement_keys[k]) then return true end
		end
	end
end)

hook.Add('EntityRemoved', 'SlibAnimatorRemoveIfEntityDestroyed', function(ent)
	snet.InvokeAll('slib_animator_destroyed', ent)
	slib.Animator.ClearInactive()
end)

hook.Add('OnNPCKilled', 'SlibAnimatorRemoveIfEntityDestroyed', function(npc)
	snet.InvokeAll('slib_animator_destroyed', ent)
	slib.Animator.ClearInactive()
end)

hook.Add('Think', 'SlibAnimatorRotationFixed', function()
	for i = #slib.Storage.ActiveAnimations, 1, -1 do
		local value = slib.Storage.ActiveAnimations[i]
		local animator = value.animator
		local entity = value.entity

		if not IsValid(entity) or not IsValid(animator) then continue end

		if value.is_player then
			if IsValid(animator) and IsValid(entity) then
				local magnitude = slib.magnitude(entity:GetVelocity())
				animator:SetAngles(Angle(0, entity:GetAngles().y, 0))
				animator:SetPos(entity:GetPos() + entity:GetForward() * magnitude / 10)
			end
		elseif value.is_npc then
			entity:SetNPCState(NPC_STATE_SCRIPT)
			entity:SetSchedule(SCHED_SLEEP)
		end
	end
end)