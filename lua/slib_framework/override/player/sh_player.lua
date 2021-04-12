local meta = FindMetaTable('Player')

function meta:slibNotify(text, type, length, sound)
   text = text or ''
   type = type or NOTIFY_GENERIC
   length = length or 3

   if SERVER then
      snet.Invoke('slib_player_notify', self, text, type, length, sound)
      return
   end

   notification.AddLegacy(text, type, length)
   if sound then surface.PlaySound(sound) end
end

function meta:snetIsReady()
   return self.slibIsSpawn or false
end

function meta:slibGetActiveTool(tool_name, ignore_gmod_tool_active)
   local ignore_gmod_tool_active = ignore_gmod_tool_active or false

   if not ignore_gmod_tool_active then
      local wep = LocalPlayer():GetActiveWeapon()
      if not IsValid(wep) or wep:GetClass() ~= 'gmod_tool' then return nil end
   end

	local tool = self:GetTool()
	if not tool or not tool.GetMode or tool:GetMode() ~= tool_name then return nil end

	return tool
end