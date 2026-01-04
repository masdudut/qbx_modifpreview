print('[qbx_modifpreview] client camera.lua loaded (FINAL - orbit backspace fix)')

local Cam = {
  active = false,
  orbit = false,
  cam = nil,
  veh = nil,
  target = vec3(0,0,0),

  yaw = 0.0,
  pitch = 0.0,
  dist = 3.2,

  minPitch = -25.0,
  maxPitch =  25.0,
  minDist  =  2.0,
  maxDist  =  6.0,

  lastUpdate = 0,
}

-- =========================
-- CONFIG (ubah jika perlu)
-- =========================
local PAD = 0

-- Back / Cancel (umumnya BACKSPACE)
local CONTROL_BACKSPACE = 177

-- Nama event/action UI (kalau di script kamu beda, ubah di sini)
local UI_EVENT_OPEN_MENU = 'qbx_modifpreview:client:openMenu'
local UI_NUI_ACTION_OPEN_MENU = 'openMenu'

-- =========================

local function deg2rad(d) return d * 0.017453292519943295 end

local function getVehCenter(veh)
  local c = GetEntityCoords(veh)
  local minDim, maxDim = GetModelDimensions(GetEntityModel(veh))
  local z = c.z + (maxDim.z * 0.55)
  return vec3(c.x, c.y, z)
end

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function raycastCam(target, desired)
  local hit = 0
  local endCoords = desired
  local surfaceNormal = vec3(0,0,1)

  local ray = StartShapeTestRay(
    target.x, target.y, target.z,
    desired.x, desired.y, desired.z,
    -1, Cam.veh or 0, 7
  )
  local _, h, eC, nrm, _ent = GetShapeTestResult(ray)
  hit = h
  if hit == 1 then
    endCoords = vec3(eC.x, eC.y, eC.z)
    surfaceNormal = vec3(nrm.x, nrm.y, nrm.z)
    -- dorong sedikit keluar biar nggak nempel
    endCoords = endCoords + surfaceNormal * 0.25
  end
  return endCoords
end

local function groundClamp(pos)
  local ok, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 5.0, 0)
  if ok then
    local minZ = gz + 0.35
    if pos.z < minZ then
      return vec3(pos.x, pos.y, minZ)
    end
  end
  return pos
end

local function computeCamPos()
  local t = Cam.target
  local yawR = deg2rad(Cam.yaw)
  local pitchR = deg2rad(Cam.pitch)

  local x = t.x + (math.cos(yawR) * math.cos(pitchR)) * Cam.dist
  local y = t.y + (math.sin(yawR) * math.cos(pitchR)) * Cam.dist
  local z = t.z + (math.sin(pitchR)) * Cam.dist

  local desired = vec3(x,y,z)
  desired = raycastCam(t, desired)
  desired = groundClamp(desired)

  return desired
end

local function applyCam()
  if not Cam.active or not DoesEntityExist(Cam.veh) then return end
  Cam.target = getVehCenter(Cam.veh)

  local pos = computeCamPos()
  SetCamCoord(Cam.cam, pos.x, pos.y, pos.z)
  PointCamAtCoord(Cam.cam, Cam.target.x, Cam.target.y, Cam.target.z)
end

-- keluar orbit: kamera tetap aktif & posisi terakhir tetap nahan
local function ExitOrbitToMenu()
  if not Cam.active then return end

  -- STOP orbit saja, JANGAN destroy cam, JANGAN RenderScriptCams(false)
  Cam.orbit = false

  -- Buka kembali menu UI (aman kalau tidak ada listener)
  SetNuiFocus(true, true)
  SendNUIMessage({ action = UI_NUI_ACTION_OPEN_MENU })
  TriggerEvent(UI_EVENT_OPEN_MENU)
end

function Camera_StartMenu(veh)
  if not veh or not DoesEntityExist(veh) then return end

  Cam.veh = veh
  Cam.target = getVehCenter(veh)

  -- start yaw dari heading kendaraan biar “jelas arah”
  -- NOTE: ini akan reset kalau StartMenu dipanggil lagi.
  -- Agar kamera "nahan posisi terakhir" saat balik menu dari orbit,
  -- pastikan flow UI kamu TIDAK memanggil Camera_StartMenu ulang ketika ExitOrbitToMenu().
  Cam.yaw = GetEntityHeading(veh) + 180.0
  Cam.pitch = 8.0
  Cam.dist = 3.2

  if Cam.cam and DoesCamExist(Cam.cam) then
    DestroyCam(Cam.cam, false)
  end

  Cam.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  Cam.active = true
  Cam.orbit = false

  applyCam()
  RenderScriptCams(true, true, 250, true, true)

  -- saat menu kebuka, camera lock (tidak orbit sampai klik tombol)
  -- fokus NUI tetap dipegang oleh nui.lua
end

function Camera_Stop()
  Cam.orbit = false
  Cam.active = false

  if Cam.cam and DoesCamExist(Cam.cam) then
    RenderScriptCams(false, true, 250, true, true)
    DestroyCam(Cam.cam, false)
  end

  Cam.cam = nil
  Cam.veh = nil
end

function Camera_ToggleOrbit()
  if not Cam.active then return end
  Cam.orbit = not Cam.orbit

  -- kalau masuk orbit, biasanya UI ditutup & fokus dimatiin oleh nui.lua
  -- tapi kalau ternyata tidak, kamu bisa pakai ini:
  -- if Cam.orbit then SetNuiFocus(false, false) end
end

-- orbit loop
CreateThread(function()
  while true do
    if not Cam.active or not Cam.orbit then
      Wait(150)
    else
      Wait(0)

      -- Disable control yang mengganggu orbit
      DisableControlAction(PAD, 1, true)   -- look left/right
      DisableControlAction(PAD, 2, true)   -- look up/down
      DisableControlAction(PAD, 24, true)  -- attack
      DisableControlAction(PAD, 25, true)  -- aim
      DisableControlAction(PAD, 106, true) -- vehicle mouse control

      -- PENTING: Backspace harus tetap kebaca meskipun beberapa control di-disable.
      -- Kadang tombol jadi "disabled", jadi cek dua-duanya biar aman.
      EnableControlAction(PAD, CONTROL_BACKSPACE, true)

      if IsControlJustPressed(PAD, CONTROL_BACKSPACE) or IsDisabledControlJustPressed(PAD, CONTROL_BACKSPACE) then
        ExitOrbitToMenu()
        goto continue
      end

      local dx = GetDisabledControlNormal(PAD, 1)
      local dy = GetDisabledControlNormal(PAD, 2)

      -- sens
      Cam.yaw = Cam.yaw + (dx * 140.0)
      Cam.pitch = clamp(Cam.pitch + (-dy * 90.0), Cam.minPitch, Cam.maxPitch)

      -- zoom
      if IsDisabledControlPressed(PAD, 16) then -- mouse wheel up
        Cam.dist = clamp(Cam.dist - 0.08, Cam.minDist, Cam.maxDist)
      elseif IsDisabledControlPressed(PAD, 17) then -- mouse wheel down
        Cam.dist = clamp(Cam.dist + 0.08, Cam.minDist, Cam.maxDist)
      end

      applyCam()

      ::continue::
    end
  end
end)
