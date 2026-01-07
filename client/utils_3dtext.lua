-- client/utils_3dtext.lua
-- 3D Text ala /me (NO BACKGROUND, radius, font bagus)

local activeTexts = {}

-- === PUBLIC API ===
function Show3DText(id, coords, text, durationMs, radius)
  activeTexts[id] = {
    coords = coords,
    text = text,
    expire = GetGameTimer() + (durationMs or 3000),
    radius = radius or 12.0
  }
end

-- === DRAW LOOP ===
CreateThread(function()
  while true do
    local sleep = 1000
    local now = GetGameTimer()
    local camCoords = GetGameplayCamCoord()

    for id, t in pairs(activeTexts) do
      if now > t.expire then
        activeTexts[id] = nil
      else
        local dist = #(camCoords - t.coords)
        if dist <= t.radius then
          DrawText3D(t.coords, t.text)
          sleep = 0
        end
      end
    end

    Wait(sleep)
  end
end)

-- === CORE DRAW FUNCTION ===
function DrawText3D(coords, text)
  local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
  if not onScreen then return end

  local camCoords = GetGameplayCamCoord()
  local dist = #(camCoords - coords)

  local scale = (1 / dist) * 2
  local fov = (1 / GetGameplayCamFov()) * 100
  scale = scale * fov * 0.35

  SetTextScale(0.0, scale)
  SetTextFont(4) -- ✅ Chalet London (paling clean)
  SetTextProportional(true)
  SetTextColour(255, 255, 255, 230)
  SetTextCentre(true)

  -- outline + shadow TANPA background
  SetTextOutline()
  SetTextDropShadow(1, 0, 0, 0, 200)

  BeginTextCommandDisplayText('STRING')
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(x, y)
end
