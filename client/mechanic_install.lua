-- client/mechanic_install.lua (FINAL)
print('[qbx_modifpreview] client mechanic_install.lua loading...')

local function normPlate(s)
  s = tostring(s or ''):upper()
  s = s:gsub('%s+', '')
  return s
end

local function getClosestVehicle(maxDist)
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local veh = GetClosestVehicle(p.x, p.y, p.z, maxDist or 6.0, 0, 71)
  if veh ~= 0 and DoesEntityExist(veh) then return veh end
  return nil
end

-- ===== 3D TEXT (no background) =====
local activeMe = nil

local function drawText3D(x, y, z, text)
  SetDrawOrigin(x, y, z, 0)
  SetTextScale(0.38, 0.38)
  SetTextFont(4) -- font bagus & clean
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextCentre(1)
  SetTextOutline()
  BeginTextCommandDisplayText('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(0.0, 0.0)
  ClearDrawOrigin()
end

CreateThread(function()
  while true do
    if activeMe and activeMe.untilTs and GetGameTimer() < activeMe.untilTs then
      Wait(0)
      local ped = activeMe.ped or PlayerPedId()
      local pos = GetEntityCoords(ped)
      if #(GetEntityCoords(PlayerPedId()) - pos) <= (activeMe.radius or 20.0) then
        drawText3D(pos.x, pos.y, pos.z + 1.0, activeMe.text or '')
      end
    else
      activeMe = nil
      Wait(200)
    end
  end
end)

local function startMeText(text, durationMs, radius)
  activeMe = {
    ped = PlayerPedId(),
    text = text,
    untilTs = GetGameTimer() + (durationMs or 4000),
    radius = radius or 20.0,
  }
end

-- ===== Paint spray anim + prop + sound =====
local function loadModel(hash)
  if not HasModelLoaded(hash) then
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
  end
  return HasModelLoaded(hash)
end

local function attachSprayCan(ped)
  local model = joaat('prop_cs_spray_can')
  if not loadModel(model) then return nil end

  local obj = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
  local bone = GetPedBoneIndex(ped, 57005) -- R hand
  AttachEntityToEntity(obj, ped, bone, 0.10, 0.02, -0.02, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
  return obj
end

local function loadAnimDict(dict)
  if not HasAnimDictLoaded(dict) then
    RequestAnimDict(dict)
    local t = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
  end
  return HasAnimDictLoaded(dict)
end


-- ===== Anim control (runs alongside progress) =====
local paintAnimState = { active = false, prop = nil, dict = nil, exitAnim = nil, ped = nil, fx = nil, fxAsset = nil, fxName = nil }
local mechAnimState = { active = false }

local function startPaintAnim(durationMs)
  local ped = PlayerPedId()
  local dict = 'switch@franklin@lamar_tagging_wall'
  local enterAnim = 'lamar_tagging_wall_enter_lamar'
  local loopAnim  = 'lamar_tagging_wall_loop_lamar'
  local exitAnim  = 'lamar_tagging_wall_exit_lamar'

  -- reset state
  paintAnimState.active = false
  paintAnimState.prop = nil
  paintAnimState.dict = dict
  paintAnimState.exitAnim = exitAnim
  paintAnimState.ped = ped

  if not loadAnimDict(dict) then return end

  -- prop spray can
  paintAnimState.prop = attachSprayCan(ped)

  -- enter then loop (timing dibuat lebih natural)
  TaskPlayAnim(ped, dict, enterAnim, 4.0, 4.0, 900, 49, 0, false, false, false)
  Wait(450)
  TaskPlayAnim(ped, dict, loopAnim, 4.0, 4.0, -1, 49, 0, false, false, false)


  -- particle FX spray (visual semprot)
  paintAnimState.fxAsset = 'core'
  paintAnimState.fxName  = 'ent_sht_water' -- mist-like spray; safe native FX
  RequestNamedPtfxAsset(paintAnimState.fxAsset)
  local tfx = GetGameTimer() + 3000
  while not HasNamedPtfxAssetLoaded(paintAnimState.fxAsset) and GetGameTimer() < tfx do
    Wait(0)
  end
  if HasNamedPtfxAssetLoaded(paintAnimState.fxAsset) and paintAnimState.prop and DoesEntityExist(paintAnimState.prop) then
    UseParticleFxAssetNextCall(paintAnimState.fxAsset)
    paintAnimState.fx = StartNetworkedParticleFxLoopedOnEntity(
      paintAnimState.fxName,
      paintAnimState.prop,
      0.12, 0.0, 0.02,   -- offset near nozzle
      0.0, 0.0, 0.0,
      0.7,               -- scale
      false, false, false
    )
  end

  PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

  paintAnimState.active = true

  -- auto stop after duration (fallback safety)
  CreateThread(function()
    Wait(durationMs or 0)
    if paintAnimState.active then
      stopPaintAnim()
    end
  end)
end

local function stopPaintAnim()
  if not paintAnimState.active then return end
  paintAnimState.active = false

  local ped = paintAnimState.ped or PlayerPedId()
  local dict = paintAnimState.dict
  local exitAnim = paintAnimState.exitAnim

  -- stop spray FX first
  if paintAnimState.fx then
    StopParticleFxLooped(paintAnimState.fx, false)
    paintAnimState.fx = nil
  end

  -- play exit anim (lebih rapi), lalu cleanup
  if dict and exitAnim then
    if not HasAnimDictLoaded(dict) then
      RequestAnimDict(dict)
      local t = GetGameTimer() + 2000
      while not HasAnimDictLoaded(dict) and GetGameTimer() < t do
        Wait(0)
      end
    end

    if HasAnimDictLoaded(dict) then
      TaskPlayAnim(ped, dict, exitAnim, 4.0, 4.0, 700, 49, 0, false, false, false)
      Wait(550)
    end
  end

  ClearPedTasks(ped)

  if paintAnimState.prop and DoesEntityExist(paintAnimState.prop) then
    DeleteEntity(paintAnimState.prop)
  end

  paintAnimState.prop = nil
  paintAnimState.dict = nil
  paintAnimState.exitAnim = nil
  paintAnimState.ped = nil
end

local function startMechanicAnim(durationMs)
  local ped = PlayerPedId()
  local dict = 'mini@repair'
  local clip = 'fixing_a_ped'
  mechAnimState.active = true

  if loadAnimDict(dict) then
    TaskPlayAnim(ped, dict, clip, 4.0, 4.0, -1, 49, 0, false, false, false)
  end

  PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
  CreateThread(function()
    Wait(durationMs or 0)
    if mechAnimState.active then
      ClearPedTasks(ped)
      mechAnimState.active = false
    end
  end)
end

local function stopMechanicAnim()
  if not mechAnimState.active then return end
  mechAnimState.active = false
  ClearPedTasks(PlayerPedId())
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
      SetVehicleExtraColours(veh, colorId, wheel); return true
    elseif cat == 'wheel' then
      local pearl, wheel = GetVehicleExtraColours(veh)
      SetVehicleExtraColours(veh, pearl, colorId); return true
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
    SetVehicleWindowTint(veh, tonumber(d.tint) or 0); return true
  end

  if t == 'plate' then
    SetVehicleNumberPlateTextIndex(veh, tonumber(d.plate) or 0); return true
  end

  if t == 'horn' then
    SetVehicleMod(veh, 14, tonumber(d.horn) or -1, false); return true
  end

  return false
end

-- klik install dari menu
RegisterNetEvent('qbx_modifpreview:client:installOrderMod', function(slot, modIndex, mod, meta)
  local isMech = lib.callback.await('qbx_modifpreview:server:isMechanic', false)
  if not isMech then
    lib.notify({ type='error', title='Install', description='Hanya mechanic.' })
    return
  end

  if not Workshop_IsInside() then
    lib.notify({ type='error', title='Install', description='Kamu harus berada di zona bengkel.' })
    return
  end

  local ped = PlayerPedId()
  local veh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or getClosestVehicle(7.0)
  if not veh then
    lib.notify({ type='error', title='Install', description='Tidak ada kendaraan di dekatmu.' })
    return
  end

  local vehPlate = GetVehicleNumberPlateText(veh)
  local wantPlate = meta and meta.plate or ''
  if normPlate(vehPlate) ~= normPlate(wantPlate) then
    lib.notify({ type='error', title='Install', description='List ini bukan untuk kendaraan ini (plate tidak cocok).' })
    return
  end

  local netId = NetworkGetNetworkIdFromEntity(veh)

  -- SERVER gate: partkit + plate check ulang
  TriggerServerEvent('qbx_modifpreview:server:requestInstall', tonumber(slot), tonumber(modIndex), netId, vehPlate)
end)

-- server approved -> lakukan anim + progress + apply + markInstalled
RegisterNetEvent('qbx_modifpreview:client:installApproved', function(slot, modIndex, targetNetId, mod)
  local veh = NetToVeh(targetNetId)
  if veh == 0 or not DoesEntityExist(veh) then
    lib.notify({ type='error', title='Install', description='Kendaraan target tidak ditemukan.' })
    return
  end

  local dur = math.random(3000, 10000)
  local label = mod.label or 'Installing...'

  if mod.type == 'paint' then
    startMeText('Sedang mengecat kendaraan', dur, 20.0)
  elseif mod.type == 'body' then
    startMeText('Sedang memasang part body', dur, 20.0)
  else
    startMeText('Sedang melakukan pemasangan modif', dur, 20.0)
  end

    -- start anim bersamaan dengan progress + 3dtext (simultan)
  if mod.type == 'paint' then
    startPaintAnim(dur)
  else
    startMechanicAnim(dur)
  end

  local ok = lib.progressCircle({
    duration = dur,
    label = label,
    position = 'bottom',
    useWhileDead = false,
    canCancel = true,
    disable = { move = true, car = true, combat = true }
  })

  -- stop anim apapun hasilnya (biar tidak nyangkut)
  if mod.type == 'paint' then
    stopPaintAnim()
  else
    stopMechanicAnim()
  end

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