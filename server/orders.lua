local function getPlayer(src)
  return exports.qbx_core:GetPlayer(src)
end

local function isMechanic(src)
  local player = getPlayer(src)
  if not player then return false end
  local job = player.PlayerData and player.PlayerData.job
  local name = job and job.name
  if not name then return false end
  return Config.AllowedMechanicJobs and Config.AllowedMechanicJobs[name] == true
end

lib.callback.register('qbx_modifpreview:server:isMechanic', function(src)
  return isMechanic(src)
end)

RegisterNetEvent('qbx_modifpreview:server:deleteOrder', function(slot)
  local src = source
  if not isMechanic(src) then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Order', description='Kamu bukan mechanic.'})
    return
  end

  slot = tonumber(slot)
  if not slot then return end

  local itemName = Config.OrderItemName
  local item = Inv_GetSlot(src, slot)
  if not item or item.name ~= itemName then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Order', description='Item tidak valid / slot berubah.'})
    return
  end

  Inv_RemoveItem(src, itemName, 1, slot)
  TriggerClientEvent('ox_lib:notify', src, {type='success', title='Order', description='Modif List dihapus.'})
end)

RegisterNetEvent('qbx_modifpreview:server:markInstalled', function(slot, modIndex)
  local src = source
  if not isMechanic(src) then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Kamu bukan mechanic.'})
    return
  end

  slot = tonumber(slot)
  modIndex = tonumber(modIndex)
  if not slot or not modIndex then return end

  local itemName = Config.OrderItemName
  local item = Inv_GetSlot(src, slot)
  if not item or item.name ~= itemName then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Item tidak valid / slot berubah.'})
    return
  end

  local meta = item.metadata
  if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Metadata order tidak ditemukan.'})
    return
  end

  local m = meta.mods[modIndex]
  if type(m) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Mod index tidak valid.'})
    return
  end

  if m.installed then
    TriggerClientEvent('ox_lib:notify', src, {type='inform', title='Install', description='Sudah terpasang.'})
    return
  end

  m.installed = true
  local ok = Inv_SetMetadata(src, slot, meta)
  if not ok then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Gagal update metadata.'})
    return
  end

  TriggerClientEvent('ox_lib:notify', src, {type='success', title='Install', description='Ditandai terpasang.'})
end)
