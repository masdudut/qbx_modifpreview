-- client/mechanic_install.lua (FINAL)
print('[qbx_modifpreview] client mechanic_install.lua loading...')

local SPRAY_PROP = `prop_cs_spray_can`
local sprayObj = nil
local spraySoundId = nil

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

local function getFrontWorkPos(veh)
  -- posisi kerja di depan mobil (dipakai semua tipe biar konsisten & tidak tenggelam)
  local pos = GetOffsetFromEntityInWorldCoords(veh, 0.0, 2.0, 0.0)
  local heading = GetEntityHeading(veh) + 180.0

  local _, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, 0)
  if gz then pos = vec3(pos.x, pos.y, gz) end

  return pos, heading
end

local function goToWorkPos(veh)
  local ped = PlayerPedId()
  local target, heading = getFrontWorkPos(veh)

  TaskGoStraightToCoord(ped, target.x, target.y, target.z, 1.0, 6000, heading, 0.2)

  local timeout = GetGameTimer() + 6000
  while GetGameTimer() < timeout do
    local pp = GetEntityCoords(ped)
    if #(pp - target) < 0.7 then break end
    Wait(50)
  end

  SetEntityCoordsNoOffset(ped, target.x, target.y, target.z, false, false, false)
  SetEntityHeading(ped, heading)
  faceEntity(ped, veh)
end

local function ensureSprayProp()
  if sprayObj and DoesEntityExist(sprayObj) then return end
  RequestModel(SPRAY_PROP)
  while not HasModelLoaded(SPRAY_PROP) do Wait(10) end

  local ped = PlayerPedId()
  sprayObj = CreateObject(SPRAY_PROP, 0.0, 0.0, 0.0, true, true, false)
  local bone = GetPedBoneIndex(ped, 57005) -- RH
  AttachEntityToEntity(sprayObj, ped, bone, 0.12, 0.02, -0.02, -80.0, 0.0, 0.0, true, true, false, true, 1, true)
  SetModelAsNoLongerNeeded(SPRAY_PROP)
end

local function clearSprayProp()
  if sprayObj and DoesEntityExist(sprayObj) then
    DeleteEntity(sprayObj)
  end
  sprayObj = nil
end

local function startSpraySound()
  -- built-in sound (kalau tidak ada di build kamu, tidak crash)
  pcall(function()
    spraySoundId = GetSoundId()
    PlaySoundFromEntity(spraySoundId, 'SPRAY', PlayerPedId(), 'CARWASH_SOUNDS', true, 0)
  end)
end

local function stopSpraySound()
  pcall(function()
    if spraySoundId then
      StopSound(spraySoundId)
      ReleaseSoundId(spraySoundId)
    end
  end)
  spraySoundId = nil
end

local function playInstallProgress(labelText, modType)
  local dur = math.random(3000, 10000)
  local ped = PlayerPedId()

  -- semua tipe pakai 1 anim mekanik depan mobil
  TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_VEHICLE_MECHANIC', 0, true)

  -- paint/xenon pakai spray prop (visual)
  local useSpray = (modType == 'paint' or modType == 'xenon')
  if useSpray then
    ensureSprayProp()
    startSpraySound()
  end

  local ok = lib.progressCircle({
    duration = dur,
    label = labelText or 'Installing...',
    position = 'bottom',
    useWhileDead = false,
    canCancel = true,
    disable = { move = true, car = true, combat = true }
  })

  stopSpraySound()
  clearSprayProp()
  ClearPedTasks(ped)

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

  if Workshop_IsInside and not Workshop_IsInside() then
    lib.notify({ type='error', title='Install', description='Kamu harus berada di zona bengkel.' })
    return
  end

  -- butuh partkit
  local okKit = lib.callback.await('qbx_modifpreview:server:consumepartkit', false)
  if not okKit then
    lib.notify({ type='error', title='Install', description='Butuh partkit untuk install 1 part.' })
    return
  end

  local ped = PlayerPedId()
  local veh = nil

  if IsPedInAnyVehicle(ped, false) then
    veh = GetVehiclePedIsIn(ped, false)
  else
    veh = getClosestVehicle(7.0)
  end

  if not veh then
    lib.notify({ type='error', title='Install', description='Tidak ada kendaraan di dekatmu.' })
    return
  end

  goToWorkPos(veh)

  local ok = playInstallProgress(mod.label or 'Installing...', mod.type)
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


-- client/use_modlist.lua (atau tempel di client/order_menu.lua)
RegisterNetEvent('qbx_modifpreview:client:useModifList', function(item)
  print('[qbx_modifpreview] useModifList fired', item and item.slot)

  if not item or not item.slot then
    lib.notify({ type='error', title='Modif', description='Item slot tidak terbaca.' })
    return
  end

  local meta, err = lib.callback.await('qbx_modifpreview:server:getOrderFromSlot', false, item.slot)
  if not meta then
    lib.notify({ type='error', title='Modif', description=err or 'Metadata tidak ditemukan.' })
    return
  end

  -- buka menu list (punyamu sudah ada event ini)
  TriggerEvent('qbx_modifpreview:client:openOrderMenu', item.slot, meta)
end)
