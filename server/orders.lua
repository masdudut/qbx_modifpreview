-- server/orders.lua (FINAL)
print('[qbx_modifpreview] server orders.lua loading...')

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

local function setSlotMetadata(src, slot, meta)
  local ok = false

  if exports.ox_inventory and exports.ox_inventory.SetMetadata then
    ok = exports.ox_inventory:SetMetadata(src, slot, meta) == true
    if ok then return true end
  end

  if exports.ox_inventory and exports.ox_inventory.SetSlotMetadata then
    ok = exports.ox_inventory:SetSlotMetadata(src, slot, meta) == true
    if ok then return true end
  end

  if exports.ox_inventory and exports.ox_inventory.SetItemMetadata then
    ok = exports.ox_inventory:SetItemMetadata(src, slot, meta) == true
    if ok then return true end
  end

  return false
end

RegisterNetEvent('qbx_modifpreview:server:deleteOrder', function(slot)
  local src = source

  if not isMechanic(src) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Order', description='Kamu bukan mechanic.' })
    return
  end

  slot = tonumber(slot)
  if not slot then return end

  local itemName = Config.OrderItemName or 'mod_list_cosmetic'
  local item = inv:GetSlot(src, slot)
  if not item or item.name ~= itemName then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Order', description='Item tidak valid / slot berubah.' })
    return
  end

  inv:RemoveItem(src, itemName, 1, nil, slot)
  TriggerClientEvent('ox_lib:notify', src, { type='success', title='Order', description='Modif List dihapus.' })
end)

RegisterNetEvent('qbx_modifpreview:server:markInstalled', function(slot, modIndex)
  local src = source

  if not isMechanic(src) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Kamu bukan mechanic.' })
    return
  end

  slot = tonumber(slot)
  modIndex = tonumber(modIndex)
  if not slot or not modIndex then return end

  local itemName = Config.OrderItemName or 'mod_list_cosmetic'
  local item = inv:GetSlot(src, slot)
  if not item or item.name ~= itemName then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Item tidak valid / slot berubah.' })
    return
  end

  local meta = item.metadata
  if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Metadata order tidak ditemukan.' })
    return
  end

  local m = meta.mods[modIndex]
  if type(m) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Mod index tidak valid.' })
    return
  end

  if m.installed == true then
    TriggerClientEvent('ox_lib:notify', src, { type='inform', title='Install', description='Mod ini sudah terpasang.' })
    return
  end

  m.installed = true

  local ok = setSlotMetadata(src, slot, meta)
  if not ok then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Gagal update metadata (SetMetadata tidak tersedia).' })
    return
  end

  TriggerClientEvent('qbx_modifpreview:client:orderMetaUpdated', src, slot, meta)
  TriggerClientEvent('ox_lib:notify', src, { type='success', title='Install', description='Mod ditandai terpasang.' })
end)

print('[qbx_modifpreview] server orders.lua loaded OK')

RegisterNetEvent('qbx_modifpreview:server:useModListSlot', function(slot)
  local src = source
  slot = tonumber(slot)
  if not slot then return end

  local itemName = Config.OrderItemName or 'mod_list_cosmetic'
  local full = exports.ox_inventory:GetSlot(src, slot)

  if not full or full.name ~= itemName then return end
  local meta = full.metadata
  if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then return end

  TriggerClientEvent('qbx_modifpreview:client:openOrderMenu', src, slot, meta)
end)
