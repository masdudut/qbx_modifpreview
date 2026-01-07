-- client/use_modlist.lua (FINAL)
print('[qbx_modifpreview] client use_modlist.lua loading...')

RegisterNetEvent('qbx_modifpreview:client:useModifList', function(item)
  if not item or not item.slot then
    lib.notify({ type='error', title='Modif List', description='Slot item tidak terbaca.' })
    return
  end

  local slot = tonumber(item.slot)
  local meta, err = lib.callback.await('qbx_modifpreview:server:getOrderFromSlot', false, slot)
  if not meta then
    lib.notify({ type='error', title='Modif List', description = err or 'Metadata tidak ditemukan.' })
    return
  end

  TriggerEvent('qbx_modifpreview:client:openOrderMenu', slot, meta)
end)

print('[qbx_modifpreview] client use_modlist.lua loaded OK')
