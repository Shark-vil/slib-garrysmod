local IsValid = IsValid
local ents_GetAll = ents.GetAll

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

function slib.FindInBox(min, max)
	local entities = ents_GetAll()
	local entities_In_box = {}
	local entities_count = 0

	for i = 1, #entities do
		local entity = entities[i]
		local entity_position = entity:LocalToWorld(entity:OBBCenter())
		if entity_position:WithinAABox(min, max) then
			entities_count = entities_count + 1
			entities_In_box[entities_count] = entity
		end
	end

	return entities_In_box, entities_count
end

function slib.FindInSphere(center, radius)
	local entities = ents_GetAll()
	local sqr_radius = radius * radius
	local entities_In_sphere = {}
	local entities_count = 0

	for i = 1, #entities do
		local entity = entities[i]
		local entity_position = entity:LocalToWorld(entity:OBBCenter())
		if entity_position:DistToSqr(center) <= sqr_radius then
			entities_count = entities_count + 1
			entities_In_sphere[entities_count] = entity
		end
	end

	return entities_In_sphere
end