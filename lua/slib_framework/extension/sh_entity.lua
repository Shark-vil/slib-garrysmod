local IsValid = IsValid

function slib.IsAlive(ent)
	if not ent or not IsValid(ent) then return false end
	local isNPC = (ent and ent.IsNPC and ent:IsNPC()) or false
	local health = (ent and ent.Health and ent:Health()) or 0

	if health <= 0 then return false end
	if SERVER and isNPC and (not ent or not ent.IsCurrentSchedule or ent:IsCurrentSchedule(SCHED_DIE)) then
		return false
	end
	return true
end