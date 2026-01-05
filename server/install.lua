-- server/install.lua
-- Mechanic minta install 1 mod dari mod_list (order item).
-- Server validasi: job, slot item, metadata, modIndex
-- Lalu server kirim 1 item mod ke client mechanic untuk di-apply.

local function getPlayer(src)
  return exports.qbx_core:GetPlayer(src)
end

local function isMechanic(src)
  local player = getPlayer(src)
  if not player then return false end

  local job = player.PlayerData and player.PlayerData.job
  local name = job and job.name
  if not name then return false end

  if not Config.AllowedMechanicJobs then
    return name == 'mechanic'
  end

  return Config.AllowedMechanicJobs[name] == true
end

RegisterNetEvent('qbx_modifpreview:server:requestInstallFromOrder', function(slot, targetNetId, modIndex)
  local src = source

  if not isMechanic(src) then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Hanya mechanic yang bisa install mod list.'})
    return
  end

  slot = tonumber(slot)
  targetNetId = tonumber(targetNetId)
  modIndex = tonumber(modIndex)

  if not slot or not targetNetId or not modIndex then return end

  local itemName = Config.OrderItemName
  local item = Inv_GetSlot(src, slot)
  if not item or item.name ~= itemName then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Item tidak valid / slot berubah.'})
    return
  end

  local meta = item.metadata
  if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Metadata mod list tidak ditemukan.'})
    return
  end

  local m = meta.mods[modIndex]
  if type(m) ~= 'table' then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Install', description='Mod index tidak valid.'})
    return
  end

  if m.installed then
    TriggerClientEvent('ox_lib:notify', src, {type='inform', title='Install', description='Mod ini sudah terpasang.'})
    return
  end

  -- kirim hanya 1 mod yang dipilih ke client mechanic untuk di-apply
  TriggerClientEvent('qbx_modifpreview:client:installFromOrderApproved', src, slot, targetNetId, modIndex, m)
end)
