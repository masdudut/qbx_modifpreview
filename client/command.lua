print('[qbx_modifpreview] client command.lua loaded')

local function mustWorkshop()
  local wid = Workshop_GetCurrentId and Workshop_GetCurrentId()
  if not wid then
    lib.notify({type='error', title='Modif', description='Harus di area bengkel.'})
    return nil
  end
  return wid
end

RegisterCommand(Config.Command or 'modif', function()
  local wid = mustWorkshop()
  if not wid then return end

  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then
    lib.notify({type='error', title='Modif', description='Harus di dalam kendaraan.'})
    return
  end

  if Config.RequireDriver and GetPedInVehicleSeat(veh, -1) ~= ped then
    lib.notify({type='error', title='Modif', description='Kamu harus jadi driver.'})
    return
  end

  local netId = VehToNet(veh)
  TriggerEvent('qbx_modifpreview:client:startPreview', netId, wid)
end, false)

RegisterCommand(Config.ConfirmCommand or 'modifconfirm', function()
  TriggerEvent('qbx_modifpreview:client:confirm')
end, false)
