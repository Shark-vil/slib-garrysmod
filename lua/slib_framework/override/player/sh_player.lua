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