hook.Add('PostPlayerDraw', 'SlibAnimatorUpgradeBones', function()
	local ply = LocalPlayer()
	if ply.slib_animator_lock_post_player_draw then return end

	for i = 1, #slib.Storage.ActiveAnimations do
		local value = slib.Storage.ActiveAnimations[i]
		if not value.is_played then continue end

		local model = value.model
		local entity = value.entity
		local weapon_model = value.weapon_model
		local animator = value.animator

		if not IsValid(model) or not IsValid(animator) or not IsValid(entity) then continue end

		if IsValid(weapon_model) then
			local b_pos, b_ang = animator:GetBonePosition(value.r_hand_bone_index)
			weapon_model:SetRenderAngles(b_ang)
			weapon_model:SetRenderOrigin(b_pos)
			weapon_model:SetupBones()
			weapon_model:DrawModel()
			weapon_model:SetRenderOrigin()
			weapon_model:SetRenderAngles()
		end
	end
end)