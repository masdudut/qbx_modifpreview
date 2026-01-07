-- server/install.lua (FINAL)
print('[qbx_modifpreview] server install.lua loading...')

-- Broadcast 3D text to all clients.
-- Clients will only render it if they are within "radius" from coords.
RegisterNetEvent('qbx_modifpreview:server:broadcast3DText', function(coords, text, durationMs, radius)
  if type(coords) ~= 'table' or coords.x == nil or coords.y == nil or coords.z == nil then return end
  text = tostring(text or '')
  durationMs = tonumber(durationMs) or 6000
  radius = tonumber(radius) or 18.0

  TriggerClientEvent('qbx_modifpreview:client:show3DText', -1, coords, text, durationMs, radius)
end)

print('[qbx_modifpreview] server install.lua loaded OK')
