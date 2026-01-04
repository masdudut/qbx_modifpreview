print('[qbx_modifpreview] client order_menu.lua loaded')

local current = nil -- { slot=int, meta=table }

local function notify(t, d, ty)
  lib.notify({ title=t, description=d, type=ty or 'inform' })
end

local function vehFromPlayer()
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh ~= 0 then return veh end
  return lib.getClosestVehicle(GetEntityCoords(ped), 4.0, false)
end

local function applyOne(veh, m)
  if not veh or veh == 0 then return false end
  if type(m) ~= 'table' then return false end

  if m.type == 'paint' then
    local p,s = GetVehicleColours(veh)
    if m.which == 'primary' then SetVehicleColours(veh, m.color, s) end
    if m.which == 'secondary' then SetVehicleColours(veh, p, m.color) end
    return true
  end

  if m.type == 'wheelType' then
    SetVehicleModKit(veh, 0)
    SetVehicleWheelType(veh, tonumber(m.wheelType) or 0)
    return true
  end

  if m.type == 'wheelIndex' then
    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, 23, tonumber(m.index) or -1, false)
    SetVehicleMod(veh, 24, tonumber(m.index) or -1, false)
    return true
  end

  if m.type == 'body' then
    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, tonumber(m.modType) or 0, tonumber(m.index) or -1, false)
    return true
  end

  if m.type == 'tint' then
    SetVehicleWindowTint(veh, tonumber(m.tint) or 0)
    return true
  end

  if m.type == 'plate' then
    SetVehicleNumberPlateTextIndex(veh, tonumber(m.plate) or 0)
    return true
  end

  if m.type == 'horn' then
    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, 14, tonumber(m.horn) or -1, false)
    return true
  end

  if m.type == 'xenon' then
    SetVehicleModKit(veh, 0)
    ToggleVehicleMod(veh, 22, true)
    local id = tonumber(m.xenon) or -1
    if id == -1 then SetVehicleXenonLightsColor(veh, 255) else SetVehicleXenonLightsColor(veh, id) end
    return true
  end

  if m.type == 'tyresmoke' then
    SetVehicleModKit(veh, 0)
    ToggleVehicleMod(veh, 20, true)
    SetVehicleTyreSmokeColor(veh, tonumber(m.r) or 255, tonumber(m.g) or 255, tonumber(m.b) or 255)
    return true
  end

  return false
end

local function openMenu()
  if not current or type(current.meta) ~= 'table' then return end
  local meta = current.meta
  local opts = {}

  opts[#opts+1] = {
    title = ('Plate: %s'):format(meta.plate or '-'),
    description = ('Workshop: %s'):format(meta.workshopId or '-'),
    disabled = true
  }

  opts[#opts+1] = { title='— Mods (klik untuk install) —', disabled=true }

  for i, m in ipairs(meta.mods or {}) do
    local title = m.label or (m.type or 'mod')
    local desc = m.desc or ''
    if m.installed then
      title = '✓ ' .. title
      desc = (desc ~= '' and (desc .. ' • ') or '') .. 'Installed'
    end

    opts[#opts+1] = {
      title = title,
      description = desc,
      disabled = m.installed == true,
      onSelect = function()
        local veh = vehFromPlayer()
        if not veh or veh == 0 then
          notify('Install', 'Kendaraan tidak ditemukan dekat.', 'error')
          return
        end
        if applyOne(veh, m) then
          TriggerServerEvent('qbx_modifpreview:server:markInstalled', current.slot, i)
        else
          notify('Install', 'Gagal apply mod (type belum dimapping).', 'error')
        end
      end
    }
  end

  opts[#opts+1] = { title='— Actions —', disabled=true }
  opts[#opts+1] = {
    title='Delete Modif List',
    description=('Hapus item %s ini.'):format(Config.OrderItemName),
    onSelect = function()
      TriggerServerEvent('qbx_modifpreview:server:deleteOrder', current.slot)
    end
  }

  lib.registerContext({
    id = 'qbx_modifpreview_order',
    title = 'Modif List',
    options = opts
  })
  lib.showContext('qbx_modifpreview_order')
end

RegisterNetEvent('qbx_modifpreview:client:openOrderMenu', function(slot, meta)
  current = { slot = slot, meta = meta }
  openMenu()
end)
