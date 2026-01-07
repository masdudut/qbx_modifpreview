-- server/usable.lua (FINAL)
print('[qbx_modifpreview] server usable.lua loading...')

local inv = exports.ox_inventory

local function getPlayer(src)
  return exports.qbx_core:GetPlayer(src)
end

local function isMechanic(src)
  local player = getPlayer(src)
  if not player then return false end
  local job = player.PlayerData and player.PlayerData.job
  local jobName = job and job.name
  if not jobName then return false end

  if Config.AllowedMechanicJobs then
    return Config.AllowedMechanicJobs[jobName] == true
  end
  return jobName == 'mechanic'
end

local function dumpMeta(meta)
  local ok, s = pcall(json.encode, meta, { indent = true })
  if ok then return s end
  return tostring(meta)
end

lib.callback.register('qbx_modifpreview:server:getOrderFromSlot', function(src, slot)
  slot = tonumber(slot)
  if not slot then return nil, 'Slot tidak valid.' end

  local itemName = Config.OrderItemName or 'mod_list_cosmetic'
  local item = inv:GetSlot(src, slot)
  if not item or item.name ~= itemName then
    return nil, 'Item tidak valid pada slot itu.'
  end

  local meta = item.metadata
  if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then
    return nil, 'Metadata mod list tidak ditemukan.'
  end

  if Config.OnlyMechanicCanOpenList == true and not isMechanic(src) then
    return nil, 'Hanya mechanic yang bisa membuka Modif List.'
  end

  -- PRINT METADATA (buat cek debug)
  print(('[qbx_modifpreview] getOrderFromSlot src=%s slot=%s item=%s meta=%s'):format(src, slot, itemName, dumpMeta(meta)))

  return meta, nil
end)

-- dipakai mechanic_install.lua
lib.callback.register('qbx_modifpreview:server:isMechanic', function(src)
  return isMechanic(src)
end)

print('[qbx_modifpreview] server usable.lua loaded OK')
