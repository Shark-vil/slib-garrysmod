function slib.IsAlive(ent)
   if not ent or not IsValid(ent) then return false end
   if IsValid(ent) then
      local isNPC = (ent and ent.IsNPC) and ent:IsNPC() or false
      local health = (ent and ent.Health) and ent:Health() or 0

      if health <= 0 then return false end
      if isNPC and (not ent or not ent.IsCurrentSchedule or ent:IsCurrentSchedule(SCHED_DIE)) then
         return false
      end
   end
   return true
end