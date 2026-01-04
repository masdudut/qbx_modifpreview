-- server/usable.lua
CreateThread(function()
  local itemName = Config.OrderItemName or 'mod_list_cosmetic'

  if exports.qbx_core and exports.qbx_core.CreateUseableItem then
    exports.qbx_core:CreateUseableItem(itemName, function(source, item)
      if not item or not item.slot then
        TriggerClientEvent('ox_lib:notify', source, {type='error', title='Order', description='Slot item tidak terbaca.'})
        return
      end

      local full = Inv_GetSlot(source, item.slot)
      if not full or full.name ~= itemName then
        TriggerClientEvent('ox_lib:notify', source, {type='error', title='Order', description='Item tidak valid pada slot ini.'})
        return
      end

      local meta = full.metadata
      if type(meta) ~= 'table' or type(meta.mods) ~= 'table' then
        TriggerClientEvent('ox_lib:notify', source, {type='error', title='Order', description='Metadata mod list tidak ditemukan.'})
        return
      end

      TriggerClientEvent('qbx_modifpreview:client:openOrderMenu', source, item.slot, meta)
    end)

    print(('[qbx_modifpreview] usable registered via qbx_core for item: %s'):format(itemName))
  else
    print('[qbx_modifpreview] ERROR: qbx_core CreateUseableItem not found.')
  end
end)
