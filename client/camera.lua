-- client/camera.lua
-- Camera handling for qbx_modifpreview:
-- - When NUI is focused: block gameplay camera look (mouse won't move gameplay camera)
-- - When user clicks the camera button: enter ORBIT mode around the vehicle the player is currently in
--   * Starts from current gameplay camera position (no teleport)
--   * Hold LMB + drag to orbit (yaw/pitch)
--   * Mouse wheel to zoom
--   * Smooth + inertia
--   * Raycast collision to prevent clipping into walls/objects
-- - Backspace exits orbit and returns focus to NUI

local menuOpen = false
local orbitActive = false

local cam = nil
local orbitVeh = 0

-- Orbit parameters (degrees/meters)
local heading = 0.0
local pitch = 15.0
local radius = 4.0

-- Inertia (deg/frame-ish, scaled)
local velHeading = 0.0
local velPitch = 0.0

-- Tuning
local PITCH_MIN = -35.0
local PITCH_MAX = 75.0
local RADIUS_MIN = 1.8
local RADIUS_MAX = 12.0

local DRAG_SENS_YAW = -260.0
local DRAG_SENS_PITCH = -180.0

local INERTIA_DECAY = 0.88      -- closer to 1 = longer glide
local INPUT_SMOOTH = 0.35       -- 0..1 how quickly velocity follows mouse while dragging
local COLLISION_PUSH = 0.22

-- Mouse wheel (zoom)
local ZOOM_STEP = 0.6
local ZOOM_SMOOTH = 0.35
local targetRadius = nil

-- Focus point height clamp (vehicle body center-ish)
local FOCUS_UP_MIN = 0.6
local FOCUS_UP_MAX = 1.35

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function setNuiFocus(state)
  SetNuiFocus(state, state)
  SetNuiFocusKeepInput(false)
end

local function destroyCam()
  if cam then
    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)
    cam = nil
  end
end

local function getCurrentVehicle()
  local ped = PlayerPedId()
  local v = GetVehiclePedIsIn(ped, false)
  if v ~= 0 and DoesEntityExist(v) then return v end
  return 0
end

local function getVehicleFocus(veh)
  local c = GetEntityCoords(veh)

  local focusZ = 0.9
  local ok, minDim, maxDim = pcall(function()
    return GetModelDimensions(GetEntityModel(veh))
  end)
  if ok and minDim and maxDim then
    focusZ = (maxDim.z - minDim.z) * 0.45
    focusZ = clamp(focusZ, FOCUS_UP_MIN, FOCUS_UP_MAX)
  end

  return vector3(c.x, c.y, c.z + focusZ)
end

local function initFromGameplayCam(focus)
  -- Use current gameplay cam so we don't "jump" anywhere.
  local gc = GetGameplayCamCoord()

  local dx = gc.x - focus.x
  local dy = gc.y - focus.y
  local dz = gc.z - focus.z

  local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
  if dist < 0.2 then
    dist = 4.0
    dx, dy, dz = 0.0, dist, 0.0
  end

  radius = clamp(dist, RADIUS_MIN, RADIUS_MAX)
  targetRadius = radius

  -- Heading: from focus to camera in XY plane
  heading = (math.deg(math.atan2(dx, dy)) + 360.0) % 360.0

  -- Pitch: elevation
  pitch = math.deg(math.asin(clamp(dz / radius, -0.999, 0.999)))
  pitch = clamp(pitch, PITCH_MIN, PITCH_MAX)

  velHeading = 0.0
  velPitch = 0.0
end

local function computeDesiredCam(focus)
  local h = math.rad(heading)
  local p = math.rad(pitch)

  local planar = radius * math.cos(p)
  local offX = planar * math.sin(h)
  local offY = planar * math.cos(h)
  local offZ = radius * math.sin(p)

  return vector3(focus.x + offX, focus.y + offY, focus.z + offZ)
end

local function applyCollision(focus, desired, ignoreEnt)
  -- Raycast from focus to desired camera point, pull camera closer if something blocks.
  -- Using correct FiveM return signature for GetShapeTestResult.
  local flags = -1 -- everything
  local ray = StartShapeTestRay(focus.x, focus.y, focus.z, desired.x, desired.y, desired.z, flags, ignoreEnt or 0, 7)
  local _, hit, endCoords, surfaceNormal, _entityHit = GetShapeTestResult(ray)

  if hit == 1 and endCoords and surfaceNormal then
    local nx = surfaceNormal.x or 0.0
    local ny = surfaceNormal.y or 0.0
    local nz = surfaceNormal.z or 0.0
    return vector3(
      endCoords.x + nx * COLLISION_PUSH,
      endCoords.y + ny * COLLISION_PUSH,
      endCoords.z + nz * COLLISION_PUSH
    )
  end

  return desired
end

local function enterOrbit()
  if orbitActive then return end

  orbitVeh = getCurrentVehicle()
  if orbitVeh == 0 then
    -- Must be in a vehicle; keep menu as-is.
    return
  end

  local focus = getVehicleFocus(orbitVeh)

  -- IMPORTANT: init BEFORE removing NUI focus, so we capture the "correct" gameplay cam.
  initFromGameplayCam(focus)
  local gc = GetGameplayCamCoord()
  local gr = GetGameplayCamRot(2)
  local gfov = GetGameplayCamFov()

  -- Now allow mouse control (no NUI focus)
  setNuiFocus(false)

  cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
  SetCamCoord(cam, gc.x, gc.y, gc.z)
  SetCamRot(cam, gr.x, 0.0, gr.z, 2)
  SetCamFov(cam, gfov)

  RenderScriptCams(true, true, 200, true, true)
  orbitActive = true
end

local function exitOrbit()
  if not orbitActive then return end
  orbitActive = false
  orbitVeh = 0
  targetRadius = nil
  destroyCam()

  if menuOpen then
    setNuiFocus(true)
  else
    setNuiFocus(false)
  end
end

-- NUI button -> enter orbit (do not toggle off by clicking again; exit only via Backspace)
RegisterNetEvent('qbx_modifpreview:client:cameraToggle', function()
  if orbitActive then return end
  enterOrbit()
end)

RegisterNetEvent('qbx_modifpreview:client:cameraBack', function()
  exitOrbit()
end)

RegisterNetEvent('qbx_modifpreview:client:menuState', function(state)
  menuOpen = state and true or false
  if menuOpen then
    setNuiFocus(true)
  else
    setNuiFocus(false)
    exitOrbit()
  end
end)

CreateThread(function()
  while true do
    local nuiFocused = IsNuiFocused()

    -- Lock gameplay look whenever NUI is focused or orbit is active
    if nuiFocused or orbitActive then
      DisableControlAction(0, 1, true)  -- LookLeftRight
      DisableControlAction(0, 2, true)  -- LookUpDown

      -- Block attack etc while in UI/cam mode
      DisableControlAction(0, 24, true)
      DisableControlAction(0, 25, true)
      DisableControlAction(0, 37, true)
      DisableControlAction(0, 44, true)
      DisableControlAction(0, 140, true)
      DisableControlAction(0, 141, true)
      DisableControlAction(0, 142, true)

      if orbitActive and cam then
        -- Ensure we still have a vehicle (pivot = current vehicle)
        local v = getCurrentVehicle()
        if v == 0 then
          exitOrbit()
          Wait(0)
          goto continue
        end
        orbitVeh = v

        local focus = getVehicleFocus(orbitVeh)

        -- Zoom with wheel
        if IsDisabledControlJustPressed(0, 241) then -- wheel up
          targetRadius = clamp((targetRadius or radius) - ZOOM_STEP, RADIUS_MIN, RADIUS_MAX)
        elseif IsDisabledControlJustPressed(0, 242) then -- wheel down
          targetRadius = clamp((targetRadius or radius) + ZOOM_STEP, RADIUS_MIN, RADIUS_MAX)
        end
        if targetRadius then
          radius = radius + (targetRadius - radius) * ZOOM_SMOOTH
        end

        -- Drag to orbit (LMB hold)
        local dragging = IsDisabledControlPressed(0, 24) -- LMB (attack)
        if dragging then
          local dx = GetDisabledControlNormal(0, 1)
          local dy = GetDisabledControlNormal(0, 2)
          if dy == 0.0 then
            dy = GetControlNormal(0, 2)
          end

          local inputH = dx * DRAG_SENS_YAW
          local inputP = (-dy) * math.abs(DRAG_SENS_PITCH)  -- drag up = look up

          -- Smoothly move velocities toward input (gives "premium" feel)
          velHeading = velHeading + (inputH - velHeading) * INPUT_SMOOTH
          velPitch   = velPitch   + (inputP - velPitch)   * INPUT_SMOOTH
        else
          -- Inertia decay when not dragging
          velHeading = velHeading * INERTIA_DECAY
          velPitch   = velPitch   * INERTIA_DECAY

          if math.abs(velHeading) < 0.001 then velHeading = 0.0 end
          if math.abs(velPitch) < 0.001 then velPitch = 0.0 end
        end

        heading = (heading + velHeading) % 360.0
        pitch = clamp(pitch + velPitch, PITCH_MIN, PITCH_MAX)

        local desired = computeDesiredCam(focus)
        desired = applyCollision(focus, desired, orbitVeh)

        SetCamCoord(cam, desired.x, desired.y, desired.z)
        PointCamAtCoord(cam, focus.x, focus.y, focus.z)

        -- Exit with Backspace
        if IsControlJustPressed(0, 177) then
          exitOrbit()
        end
      end

      ::continue::
      Wait(0)
    else
      Wait(250)
    end
  end
end)

print('[qbx_modifpreview] camera.lua (orbit+zoom+smoothing+collision) loaded')
