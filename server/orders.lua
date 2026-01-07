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

local function normPlate(s)
  s = tostring(s or ''):upper()
  s = s:gsub('%s+', '')
  return s
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

  local ok = Inv_SetMetadata(src, slot, meta)
  if not ok then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Gagal update metadata (ox_inventory export metadata tidak cocok).' })
    return
  end

  TriggerClientEvent('ox_lib:notify', src, { type='success', title='Install', description='Mod ditandai terpasang.' })
end)

-- request install: server gate PartKit + plate verify (plateTarget dikirim client)
RegisterNetEvent('qbx_modifpreview:server:requestInstall', function(slot, modIndex, targetNetId, plateTarget)
  local src = source

  if not isMechanic(src) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Hanya mechanic.' })
    return
  end

  slot = tonumber(slot)
  modIndex = tonumber(modIndex)
  targetNetId = tonumber(targetNetId) or 0
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

  -- PLATE CHECK (wajib cocok)
  if normPlate(meta.plate) ~= normPlate(plateTarget) then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='List ini bukan untuk kendaraan ini (plate tidak cocok).' })
    return
  end

  local m = meta.mods[modIndex]
  if type(m) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Mod index tidak valid.' })
    return
  end

  if m.installed == true then
    TriggerClientEvent('ox_lib:notify', src, { type='inform', title='Install', description='Sudah terpasang.' })
    return
  end

  -- PARTKIT
  local kitName = Config.PartKitItemName or 'partkit'
  local count = inv:Search(src, 'count', kitName) or 0
  if count < 1 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description=('Butuh %s untuk memasang 1 item.'):format(kitName) })
    return
  end

  local removed = inv:RemoveItem(src, kitName, 1)
  if not removed then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Install', description='Gagal memakai partkit (inventory?).' })
    return
  end

  TriggerClientEvent('qbx_modifpreview:client:installApproved', src, slot, modIndex, targetNetId, m)
end)

print('[qbx_modifpreview] server orders.lua loaded OK')
