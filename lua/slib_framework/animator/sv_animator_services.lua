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

		if not value.is_player or not IsValid(entity) or entity ~= ply then continue end

		for k = 1, #movement_keys do
			if mv:KeyDown(movement_keys[k]) then
				ply:Freeze(true)
				timer.Simple(.5, function() ply:Freeze(false) end)
				return true
			end
		end
	end
end)

local function GetAnimationInfo(ent)
	for i = #slib.Storage.ActiveAnimations, 1, -1 do
		local value = slib.Storage.ActiveAnimations[i]
		if value.entity == ent then return value end
	end
end

local function DestroyAnimatorAction(ent)
	if not GetAnimationInfo(ent) then return end
	snet.InvokeAll('slib_animator_destroyed', ent)
	slib.Animator.ClearInactive()
end
hook.Add('EntityRemoved', 'SlibAnimatorRemoveIfEntityDestroyed', DestroyAnimatorAction)
hook.Add('OnNPCKilled', 'SlibAnimatorRemoveIfEntityDestroyed', DestroyAnimatorAction)
hook.Add('EntityTakeDamage', 'SlibAnimatorRemoveIfEntityTakeDamage', function(ent)
	local anim = GetAnimationInfo(ent)
	if not anim or not IsValid(anim.animator) then return end
	anim.animator:Remove()
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
			if not value.not_prent then
				animator:SetAngles(Angle(-entity:EyeAngles().x, entity:GetAngles().y, 0))
			end
		elseif value.is_npc then
			entity:SetNPCState(NPC_STATE_SCRIPT)
			entity:SetSchedule(SCHED_SLEEP)
		end
	end
end)