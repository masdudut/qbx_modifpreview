print('[qbx_modifpreview] client workshops.lua loaded')

local currentWorkshopId = nil
local zones = {}

function Workshop_GetCurrentId()
  return currentWorkshopId
end

local function setWorkshop(id)
  currentWorkshopId = id
end

CreateThread(function()
  for _, w in ipairs(Config.Workshops) do
    zones[w.id] = lib.zones.box({
      coords = w.coords,
      size = w.size,
      rotation = w.rotation or 0.0,
      debug = false,
      onEnter = function()
        setWorkshop(w.id)
      end,
      onExit = function()
        if currentWorkshopId == w.id then
          setWorkshop(nil)
        end
      end
    })
  end
end)
