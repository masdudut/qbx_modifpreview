-- server/usable.lua (FINAL)
print('[qbx_modifpreview] server usable.lua loading...')

local inv = exports.ox_inventory

CreateThread(function()
  local itemName = Config.OrderItemName or 'mod_list_cosmetic'

  if not inv or not inv.RegisterUsableItem then
    print('[qbx_modifpreview] ERROR: ox_inventory export RegisterUsableItem not found')
    return
  end

  inv:RegisterUsableItem(itemName, function(source, item)
    if not item or not item.slot then
      TriggerClientEvent('ox_lib:notify', source, { type='error', title='Order', description='Slot item tidak terbaca.' })
      return
    end

    local full = inv:GetSlot(source, item.slot)
    if not full or full.name ~= itemName then
      TriggerClientEvent('ox_lib:notify', source, { type='error', title='Order', description='Item tidak valid pada slot ini.' })
      return
    end

    local meta = full.metadata
    if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then
      TriggerClientEvent('ox_lib:notify', source, { type='error', title='Order', description='Metadata mod list tidak ditemukan.' })
      return
    end

    TriggerClientEvent('qbx_modifpreview:client:openOrderMenu', source, item.slot, meta)
  end)

  print(('[qbx_modifpreview] usable registered for item: %s'):format(itemName))
end)

print('[qbx_modifpreview] server usable.lua loaded OK')

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
