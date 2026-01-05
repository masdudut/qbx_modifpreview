-- client/mechanic_install.lua (FINAL)
print('[qbx_modifpreview] client mechanic_install.lua loading...')

local function getClosestVehicle(maxDist)
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local veh = GetClosestVehicle(p.x, p.y, p.z, maxDist or 6.0, 0, 71)
  if veh ~= 0 and DoesEntityExist(veh) then return veh end
  return nil
end

local function faceEntity(ped, ent)
  local p = GetEntityCoords(ped)
  local e = GetEntityCoords(ent)
  local heading = GetHeadingFromVector_2d(e.x - p.x, e.y - p.y)
  SetEntityHeading(ped, heading)
end

local function moveToWorkPos(veh, modType)
  local ped = PlayerPedId()
  local off = vec3(-1.0, 0.8, 0.0) -- default side

  if modType == 'paint' then
    off = vec3(-1.1, 0.4, 0.0)
  elseif modType == 'wheels' then
    off = vec3(-1.0, 1.2, 0.0)
  elseif modType == 'body_front' then
    off = vec3(0.0, 2.2, 0.0)
  elseif modType == 'body_rear' then
    off = vec3(0.0, -2.4, 0.0)
  elseif modType == 'body_roof' then
    off = vec3(0.0, 0.2, 0.0)
  end

  local target = GetOffsetFromEntityInWorldCoords(veh, off.x, off.y, off.z)
  TaskGoStraightToCoord(ped, target.x, target.y, target.z, 1.0, 6000, GetEntityHeading(veh), 0.5)

  local timeout = GetGameTimer() + 6000
  while GetGameTimer() < timeout do
    local pp = GetEntityCoords(ped)
    if #(pp - target) < 0.8 then break end
    Wait(50)
  end

  faceEntity(ped, veh)
end

local function playInstallProgress(labelText)
  local dur = math.random(3000, 10000)

  -- scenario mekanik aman dan umum
  TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_VEHICLE_MECHANIC', 0, true)

  local ok = lib.progressCircle({
    duration = dur,
    label = labelText or 'Installing...',
    position = 'bottom',
    useWhileDead = false,
    canCancel = true,
    disable = { move = true, car = true, combat = true }
  })

  ClearPedTasks(PlayerPedId())
  return ok
end

local function applyModToVehicle(veh, mod)
  if not veh or not DoesEntityExist(veh) then return false end
  if type(mod) ~= 'table' then return false end

  local t = mod.type
  local d = mod.data or {}

  SetVehicleModKit(veh, 0)

  if t == 'paint' then
    local cat = tostring(d.category or 'primary')
    local colorId = tonumber(d.colorId)
    if not colorId then return false end

    if cat == 'primary' or cat == 'secondary' then
      local p, s = GetVehicleColours(veh)
      if cat == 'primary' then SetVehicleColours(veh, colorId, s)
      else SetVehicleColours(veh, p, colorId) end
      return true
    elseif cat == 'pearl' then
      local pearl, wheel = GetVehicleExtraColours(veh)
      SetVehicleExtraColours(veh, colorId, wheel)
      return true
    elseif cat == 'wheel' then
      local pearl, wheel = GetVehicleExtraColours(veh)
      SetVehicleExtraColours(veh, pearl, colorId)
      return true
    elseif cat == 'interior' then
      SetVehicleInteriorColour(veh, colorId); return true
    elseif cat == 'dashboard' then
      SetVehicleDashboardColour(veh, colorId); return true
    end
    return false
  end

  if t == 'wheels' then
    local wt = tonumber(d.wheelType) or 0
    local wi = tonumber(d.wheelIndex) or -1
    SetVehicleWheelType(veh, wt)
    SetVehicleMod(veh, 23, wi, false)
    SetVehicleMod(veh, 24, wi, false)
    return true
  end

  if t == 'body' then
    local modType = tonumber(d.modType) or 0
    local idx = tonumber(d.index) or -1
    SetVehicleMod(veh, modType, idx, false)
    return true
  end

  if t == 'xenon' then
    local color = tonumber(d.color)
    if color == nil then return false end
    ToggleVehicleMod(veh, 22, true)
    if color == -1 then SetVehicleXenonLightsColor(veh, 255)
    else SetVehicleXenonLightsColor(veh, color) end
    return true
  end

  if t == 'tint' then
    SetVehicleWindowTint(veh, tonumber(d.tint) or 0)
    return true
  end

  if t == 'plate' then
    SetVehicleNumberPlateTextIndex(veh, tonumber(d.plate) or 0)
    return true
  end

  if t == 'horn' then
    SetVehicleMod(veh, 14, tonumber(d.horn) or -1, false)
    return true
  end

  return false
end

RegisterNetEvent('qbx_modifpreview:client:installOrderMod', function(slot, modIndex, mod)
  local isMech = lib.callback.await('qbx_modifpreview:server:isMechanic', false)
  if not isMech then
    lib.notify({ type='error', title='Install', description='Hanya mechanic.' })
    return
  end

  if not Workshop_IsInside() then
    lib.notify({ type='error', title='Install', description='Kamu harus berada di zona bengkel.' })
    return
  end

  local veh = nil
  local ped = PlayerPedId()

  if IsPedInAnyVehicle(ped, false) then
    veh = GetVehiclePedIsIn(ped, false)
  else
    veh = getClosestVehicle(7.0)
  end

  if not veh then
    lib.notify({ type='error', title='Install', description='Tidak ada kendaraan di dekatmu.' })
    return
  end

  -- pilih posisi kerja berdasarkan jenis
  local posType = mod.type
  if mod.type == 'body' then
    local mt = tonumber((mod.data or {}).modType or 0)
    if mt == 1 or mt == 2 then posType = 'body_front'
    elseif mt == 2 then posType = 'body_rear'
    elseif mt == 10 then posType = 'body_roof'
    end
  end

  moveToWorkPos(veh, posType)

  local ok = playInstallProgress(mod.label or 'Installing...')
  if not ok then
    lib.notify({ type='error', title='Install', description='Dibatalkan.' })
    return
  end

  local applied = applyModToVehicle(veh, mod)
  if not applied then
    lib.notify({ type='error', title='Install', description='Gagal apply mod (data tidak valid).' })
    return
  end

  TriggerServerEvent('qbx_modifpreview:server:markInstalled', tonumber(slot), tonumber(modIndex))
end)

print('[qbx_modifpreview] client mechanic_install.lua loaded OK')
