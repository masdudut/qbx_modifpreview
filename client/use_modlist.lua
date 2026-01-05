-- client/use_modlist.lua
print('[qbx_modifpreview] client use_modlist.lua loading...')

RegisterNetEvent('qbx_modifpreview:client:useModifList', function(item)
  local slot = item and item.slot
  print('[qbx_modifpreview] useModifList fired slot=', slot)

  if not slot then
    lib.notify({ type='error', title='Order', description='Item slot tidak terbaca.' })
    return
  end

  local meta, err = lib.callback.await('qbx_modifpreview:server:getOrderFromSlot', false, slot)
  if not meta then
    lib.notify({ type='error', title='Order', description=err or 'Gagal mengambil metadata.' })
    return
  end

  -- buka menu list kamu (order_menu.lua sudah handle ini)
  TriggerEvent('qbx_modifpreview:client:openOrderMenu', slot, meta)
end)

print('[qbx_modifpreview] client use_modlist.lua loaded OK')
