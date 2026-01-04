-- client/preview.lua (FINAL)
print('[qbx_modifpreview] client preview.lua loaded (FINAL)')

local Preview = {
  active = false,
  vehicle = nil,
  netId = nil,
  workshopId = nil,
  originalProps = nil,

  selected = {
    paints = { category='primary', type='Classic', value='stock' }, -- H1=category, H2=type(group), value=colorId
    wheels = { type=0, index=-1 },                                 -- wheels H1 only
    body   = { part='spoiler', index=-1 },                          -- body H1 only
    xenon  = -1,
    tint   = 0,
    plate  = 0,
    horn   = -1,
  }
}

function Preview_IsActive() return Preview.active end
function Preview_GetVehicle() return Preview.vehicle end
function Preview_GetSelected() return Preview.selected end

local function rollback()
  if Preview.vehicle and Preview.originalProps then
    lib.setVehicleProperties(Preview.vehicle, Preview.originalProps)
  end
end

local function applyPaint()
  local veh = Preview.vehicle
  if not veh then return end

  local cat = Preview.selected.paints.category
  local value = Preview.selected.paints.value
  if value == 'stock' or value == nil then return end

  local idx = tonumber(value)
  if not idx then return end

  local p, s = GetVehicleColours(veh)
  if cat == 'primary' then
    SetVehicleColours(veh, idx, s)
  elseif cat == 'secondary' then
    SetVehicleColours(veh, p, idx)
  elseif cat == 'pearl' then
    local pearl, wheel = GetVehicleExtraColours(veh)
    SetVehicleExtraColours(veh, idx, wheel)
  elseif cat == 'wheel' then
    local pearl, wheel = GetVehicleExtraColours(veh)
    SetVehicleExtraColours(veh, pearl, idx)
  elseif cat == 'interior' then
    SetVehicleInteriorColour(veh, idx)
  elseif cat == 'dashboard' then
    SetVehicleDashboardColour(veh, idx)
  end
end

local function applyWheels()
  local veh = Preview.vehicle
  if not veh then return end
  SetVehicleModKit(veh, 0)

  local wt = tonumber(Preview.selected.wheels.type) or 0
  local wi = tonumber(Preview.selected.wheels.index) or -1

  SetVehicleWheelType(veh, wt)
  SetVehicleMod(veh, 23, wi, false)
  SetVehicleMod(veh, 24, wi, false)
end

local function applyBody()
  local veh = Preview.vehicle
  if not veh then return end
  SetVehicleModKit(veh, 0)

  local partKey = Preview.selected.body.part
  local idx = tonumber(Preview.selected.body.index) or -1

  for _, p in ipairs(ModMap.bodyParts or {}) do
    if p.key == partKey then
      SetVehicleMod(veh, p.modType, idx, false)
      return
    end
  end
end

local function applyExtras()
  local veh = Preview.vehicle
  if not veh then return end

  if Preview.selected.tint ~= nil then
    SetVehicleWindowTint(veh, tonumber(Preview.selected.tint) or 0)
  end

  if Preview.selected.plate ~= nil then
    SetVehicleNumberPlateTextIndex(veh, tonumber(Preview.selected.plate) or 0)
  end

  if Preview.selected.horn ~= nil then
    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, 14, tonumber(Preview.selected.horn) or -1, false)
  end
end

local function applyXenon()
  local veh = Preview.vehicle
  if not veh then return end

  local id = tonumber(Preview.selected.xenon)
  if id == nil then return end

  SetVehicleModKit(veh, 0)
  ToggleVehicleMod(veh, 22, true)

  if id == -1 then
    SetVehicleXenonLightsColor(veh, 255)
  else
    SetVehicleXenonLightsColor(veh, id)
  end
end

local function applyAll()
  if not Preview.active then return end
  applyPaint()
  applyWheels()
  applyBody()
  applyExtras()
  applyXenon()
end

-- IMPORTANT: wheel type bisa ditolak -> sync ke actual
local function setWheelTypeSynced(wType)
  local veh = Preview.vehicle
  if not veh then return end
  SetVehicleModKit(veh, 0)

  wType = tonumber(wType) or 0
  SetVehicleWheelType(veh, wType)

  Wait(0)
  local actual = GetVehicleWheelType(veh)
  Preview.selected.wheels.type = actual

  -- reset index after type change
  Preview.selected.wheels.index = -1
  SetVehicleMod(veh, 23, -1, false)
  SetVehicleMod(veh, 24, -1, false)
end

RegisterNetEvent('qbx_modifpreview:client:startPreview', function(netId, workshopId)
  local veh = NetToVeh(netId)
  if veh == 0 or not DoesEntityExist(veh) then
    lib.notify({type='error', title='Modif', description='Vehicle netId tidak valid.'})
    return
  end

  Preview.active = true
  Preview.vehicle = veh
  Preview.netId = netId
  Preview.workshopId = workshopId
  Preview.originalProps = lib.getVehicleProperties(veh)

  -- Start camera locked (default)
  if Camera_StartMenu then
    Camera_StartMenu(veh)
  end

  TriggerEvent('qbx_modifpreview:nui:open')
end)

RegisterNetEvent('qbx_modifpreview:client:cancel', function()
  if not Preview.active then return end
  rollback()

  Preview.active = false
  Preview.vehicle = nil
  Preview.netId = nil
  Preview.workshopId = nil
  Preview.originalProps = nil

  TriggerEvent('qbx_modifpreview:nui:close')
  if Camera_Stop then Camera_Stop() end
end)

RegisterNetEvent('qbx_modifpreview:client:confirm', function()
  if not Preview.active then return end
  rollback()

  local plate = GetVehicleNumberPlateText(Preview.vehicle)
  TriggerServerEvent('qbx_modifpreview:server:createOrder', Preview.selected, plate, Preview.workshopId)

  Preview.active = false
  Preview.vehicle = nil
  Preview.netId = nil
  Preview.workshopId = nil
  Preview.originalProps = nil

  TriggerEvent('qbx_modifpreview:nui:close')
  if Camera_Stop then Camera_Stop() end
end)

RegisterNetEvent('qbx_modifpreview:client:set', function(k, v)
  if not Preview.active then return end

  if k == 'paint_category' then Preview.selected.paints.category = tostring(v) end
  if k == 'paint_group' then Preview.selected.paints.type = tostring(v) end
  if k == 'paint_color' then Preview.selected.paints.value = v end

  if k == 'wheel_type' then
    setWheelTypeSynced(v)
    applyAll()
    return
  end
  if k == 'wheel_index' then Preview.selected.wheels.index = tonumber(v) or -1 end

  if k == 'body_part' then
    Preview.selected.body.part = tostring(v)
    Preview.selected.body.index = -1
  end
  if k == 'body_index' then Preview.selected.body.index = tonumber(v) or -1 end

  if k == 'xenon' then Preview.selected.xenon = tonumber(v) or -1 end
  if k == 'tint' then Preview.selected.tint = tonumber(v) or 0 end
  if k == 'plate' then Preview.selected.plate = tonumber(v) or 0 end
  if k == 'horn' then Preview.selected.horn = tonumber(v) or -1 end

  applyAll()
end)
