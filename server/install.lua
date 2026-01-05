-- server/install.lua
-- partkit consumption (1 partkit per 1 install)

local function getPlayer(src)
  return exports.qbx_core:GetPlayer(src)
end

local function isMechanic(src)
  local player = getPlayer(src)
  if not player then return false end
  local job = player.PlayerData and player.PlayerData.job
  local jobName = job and job.name
  if not jobName then return false end
  if Config.AllowedMechanicJobs then
    return Config.AllowedMechanicJobs[jobName] == true
  end
  return jobName == 'mechanic'
end

lib.callback.register('qbx_modifpreview:server:consumepartkit', function(src)
  if not isMechanic(src) then return false end

  local kit = Config.partkitItemName or 'partkit'
  local count = Inv_CountItem(src, kit)
  if (count or 0) < 1 then return false end

  local removed = Inv_RemoveItem(src, kit, 1)
  return removed == true
end)
