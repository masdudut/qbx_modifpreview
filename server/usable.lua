-- server/usable.lua (FINAL - callback mode + debug print)
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

local function dprint(...)
  print(('[qbx_modifpreview][usable] %s'):format(table.concat({ ... }, ' ')))
end

-- Client call: ambil metadata order dari slot item yang dipakai
lib.callback.register('qbx_modifpreview:server:getOrderFromSlot', function(src, slot)
  slot = tonumber(slot)
  if not slot then
    dprint('getOrderFromSlot fail: slot invalid src=', src)
    return nil, 'Slot tidak valid.'
  end

  local itemName = Config.OrderItemName or 'mod_list_cosmetic'
  local item = inv:GetSlot(src, slot)

  if not item then
    dprint('getOrderFromSlot fail: GetSlot nil src=', src, 'slot=', slot)
    return nil, 'Item tidak ditemukan pada slot itu.'
  end

  if item.name ~= itemName then
    dprint('getOrderFromSlot fail: wrong item name src=', src, 'slot=', slot, 'name=', tostring(item.name))
    return nil, 'Item tidak valid pada slot itu.'
  end

  -- Optional restriction: hanya mechanic yg bisa buka
  if Config.OnlyMechanicCanOpenList == true and not isMechanic(src) then
    dprint('getOrderFromSlot blocked: not mechanic src=', src)
    return nil, 'Hanya mechanic yang bisa membuka Modif List.'
  end

  local meta = item.metadata
  if type(meta) ~= 'table' then
    dprint('getOrderFromSlot fail: metadata not table src=', src, 'slot=', slot, 'metaType=', type(meta))
    return nil, 'Metadata item kosong / tidak valid.'
  end

  if type(meta.mods) ~= 'table' then
    dprint('getOrderFromSlot fail: meta.mods missing src=', src, 'slot=', slot, 'meta=', json.encode(meta))
    return nil, 'Metadata mod list tidak ditemukan.'
  end

  -- DEBUG PRINT (ini yang kamu minta)
  dprint('getOrderFromSlot OK src=', src, 'slot=', slot, 'plate=', tostring(meta.plate), 'mods=', tostring(#meta.mods))
  dprint('META JSON:', json.encode(meta))

  return meta, nil
end)

print('[qbx_modifpreview] server usable.lua loaded (callback mode + debug)')
