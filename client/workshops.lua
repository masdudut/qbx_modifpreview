-- client/workshops.lua (FINAL)
print('[qbx_modifpreview] client workshops.lua loading...')

local currentWorkshopId = nil

local function isInsideBox(p, c, size, heading)
  local rel = p - c
  if heading and heading ~= 0.0 then
    local h = math.rad(-heading)
    local x = rel.x * math.cos(h) - rel.y * math.sin(h)
    local y = rel.x * math.sin(h) + rel.y * math.cos(h)
    rel = vec3(x, y, rel.z)
  end
  return math.abs(rel.x) <= (size.x / 2.0) and math.abs(rel.y) <= (size.y / 2.0) and math.abs(rel.z) <= (size.z / 2.0)
end

CreateThread(function()
  while true do
    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local found = nil

    for _, w in ipairs(Config.Workshops or {}) do
      if isInsideBox(p, w.coords, w.size, w.rotation or 0.0) then
        found = w.id
        break
      end
    end

    currentWorkshopId = found
    Wait(500)
  end
end)

function Workshop_GetCurrentId()
  return currentWorkshopId
end

function Workshop_IsInside()
  return currentWorkshopId ~= nil
end

print('[qbx_modifpreview] client workshops.lua loaded OK')
