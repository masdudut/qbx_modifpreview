-- client/camera.lua (FINAL)
print('[qbx_modifpreview] client camera.lua loading...')

local Cam = {
  active = false,
  cam = nil,
  veh = nil,

  -- orbit params (persist per session)
  heading = nil,
  pitch = nil,
  dist = nil,

  orbitMode = false,
}

-- Persist last camera state (per preview session)
local LastState = {
  heading = 210.0,
  pitch = -12.0,
  dist = 4.2
}

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function ensureCam()
  if Cam.cam and DoesCamExist(Cam.cam) then return end
  Cam.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
end

local function destroyCam()
  if Cam.cam and DoesCamExist(Cam.cam) then
    DestroyCam(Cam.cam, false)
  end
  Cam.cam = nil
end

local function getVehTarget(veh)
  local min, max = GetModelDimensions(GetEntityModel(veh))
  local centerZ = (min.z + max.z) * 0.5
  return GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, centerZ + 0.35)
end

local function computeCamPos(veh, headingDeg, pitchDeg, dist)
  local lookAt = getVehTarget(veh)

  local h = math.rad(headingDeg)
  local p = math.rad(pitchDeg)

  local x = lookAt.x + math.cos(h) * dist * math.cos(p)
  local y = lookAt.y + math.sin(h) * dist * math.cos(p)
  local z = lookAt.z + math.sin(p) * dist + 0.45

  return vector3(x, y, z), lookAt
end

local function preventGroundClip(pos, lookAt)
  local found, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 50.0, 0)
  if found then
    local minAbove = 0.35
    if pos.z < gz + minAbove then
      pos = vector3(pos.x, pos.y, gz + minAbove)
    end
  end

  -- jangan turun terlalu jauh dari target
  if pos.z < lookAt.z - 0.85 then
    pos = vector3(pos.x, pos.y, lookAt.z - 0.85)
  end

  return pos
end

local function applyCamTick()
  if not Cam.active or not Cam.veh or not DoesEntityExist(Cam.veh) then return end
  ensureCam()

  Cam.pitch = clamp(Cam.pitch, -32.0, 10.0)
  Cam.dist  = clamp(Cam.dist,  2.0,  8.5)

  local pos, lookAt = computeCamPos(Cam.veh, Cam.heading, Cam.pitch, Cam.dist)
  pos = preventGroundClip(pos, lookAt)

  SetCamCoord(Cam.cam, pos.x, pos.y, pos.z)
  PointCamAtCoord(Cam.cam, lookAt.x, lookAt.y, lookAt.z)
  SetCamFov(Cam.cam, 60.0)
end

local function setOrbitMode(on)
  Cam.orbitMode = on == true

  -- orbit ON: UI focus off, supaya mouse bisa drag orbit
  TriggerEvent('qbx_modifpreview:nui:setFocus', not Cam.orbitMode)
end

-- set start position yang jelas: kamera di belakang mobil (menghadap mobil)
local function initDefaultFromVehicle(veh)
  -- kalau ada last state, pakai itu
  Cam.heading = LastState.heading
  Cam.pitch   = LastState.pitch
  Cam.dist    = LastState.dist

  -- kalau belum pernah, set relatif ke heading mobil biar natural
  if not Cam.heading then
    local vehHeading = GetEntityHeading(veh)
    Cam.heading = vehHeading + 180.0
    Cam.pitch = -12.0
    Cam.dist = 4.2
  end
end

function Camera_StartMenu(veh)
  if not veh or veh == 0 or not DoesEntityExist(veh) then return end

  Cam.active = true
  Cam.veh = veh

  ensureCam()

  initDefaultFromVehicle(veh)
  applyCamTick()

  SetCamActive(Cam.cam, true)
  RenderScriptCams(true, true, 200, true, true)

  -- default: lock (orbit off)
  setOrbitMode(false)

  CreateThread(function()
    while Cam.active do
      if not Cam.veh or not DoesEntityExist(Cam.veh) then break end

      applyCamTick()

      if Cam.orbitMode then
        DisableAllControlActions(0)

        local dx = GetDisabledControlNormal(0, 1)
        local dy = GetDisabledControlNormal(0, 2)

        Cam.heading = Cam.heading + (dx * -220.0)
        Cam.pitch   = Cam.pitch   + (dy * -120.0)

        if IsDisabledControlPressed(0, 241) then Cam.dist = Cam.dist - 0.08 end
        if IsDisabledControlPressed(0, 242) then Cam.dist = Cam.dist + 0.08 end

        -- backspace keluar orbit
        if IsDisabledControlJustPressed(0, 177) then
          setOrbitMode(false)
        end
      end

      Wait(0)
    end

    setOrbitMode(false)
  end)
end

function Camera_Stop()
  if Cam.heading then LastState.heading = Cam.heading end
  if Cam.pitch then   LastState.pitch   = Cam.pitch end
  if Cam.dist then    LastState.dist    = Cam.dist end

  Cam.active = false
  Cam.orbitMode = false
  Cam.veh = nil

  RenderScriptCams(false, true, 200, true, true)
  destroyCam()

  TriggerEvent('qbx_modifpreview:nui:setFocus', false)
end

function Camera_ToggleOrbit()
  if not Cam.active then return end
  setOrbitMode(not Cam.orbitMode)
end

RegisterNetEvent('qbx_modifpreview:client:camera', function()
  Camera_ToggleOrbit()
end)

print('[qbx_modifpreview] client camera.lua loaded OK')
