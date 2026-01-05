-- server/main.lua (FINAL)
print('[qbx_modifpreview] server main.lua loading...')

local inv = exports.ox_inventory

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

local function findBodyPart(partKey)
  for _, p in ipairs(ModMap.bodyParts or {}) do
    if p.key == partKey then return p end
  end
  return nil
end

local function getWheelTypeLabel(id)
  for _, w in ipairs(ModMap.wheels or {}) do
    if tonumber(w.id) == tonumber(id) then return w.label end
  end
  return ('WheelType %s'):format(tostring(id))
end

local function getPaintLabel(groupId, colorId)
  groupId = tostring(groupId or '')
  colorId = tonumber(colorId)
  local list = Paints and Paints.list and Paints.list[groupId]
  if type(list) ~= 'table' or not colorId then return tostring(colorId or '') end
  for _, c in ipairs(list) do
    if tonumber(c.id) == colorId then return c.label end
  end
  return tostring(colorId)
end

local function buildModsFromSelection(sel)
  local mods = {}

  sel = sel or {}

  -- ===== PAINTS =====
  if sel.paints and sel.paints.value and sel.paints.value ~= 'stock' then
    local cat = tostring(sel.paints.category or 'primary')
    local groupId = tostring(sel.paints.type or 'Classic')
    local colorId = tonumber(sel.paints.value)

    if colorId then
      local catLabelMap = {
        primary   = 'Primary Paint',
        secondary = 'Secondary Paint',
        pearl     = 'Pearl Color',
        wheel     = 'Wheel Color',
        interior  = 'Interior Color',
        dashboard = 'Dashboard Color',
      }
      local catLabel = catLabelMap[cat] or ('Paint (%s)'):format(cat)
      local colorLabel = getPaintLabel(groupId, colorId)

      mods[#mods+1] = {
        type = 'paint',
        label = catLabel,
        description = ('%s • %s'):format(groupId, colorLabel),
        data = { category = cat, group = groupId, colorId = colorId },
        installed = false,
      }
    end
  end

  -- ===== WHEELS (hanya kalau index dipilih) =====
  if sel.wheels and sel.wheels.index ~= nil then
    local wi = tonumber(sel.wheels.index)
    local wt = tonumber(sel.wheels.type) or 0
    if wi and wi >= 0 then
      mods[#mods+1] = {
        type = 'wheels',
        label = 'Wheels',
        description = ('%s • Index %d'):format(getWheelTypeLabel(wt), wi),
        data = { wheelType = wt, wheelIndex = wi },
        installed = false,
      }
    end
  end

  -- ===== BODY (More) =====
  if sel.body and sel.body.index ~= nil then
    local idx = tonumber(sel.body.index)
    local partKey = tostring(sel.body.part or 'spoiler')
    if idx and idx >= 0 then
      local part = findBodyPart(partKey)
      local label = part and part.label or ('Body (%s)'):format(partKey)
      local modType = part and part.modType or 0

      mods[#mods+1] = {
        type = 'body',
        label = label,
        description = ('Index %d'):format(idx),
        data = { part = partKey, modType = modType, index = idx },
        installed = false,
      }
    end
  end

  -- ===== XENON =====
  if sel.xenon ~= nil then
    local x = tonumber(sel.xenon)
    if x and x ~= -1 then
      local xLabel = nil
      for _, it in ipairs(ModMap.xenon or {}) do
        if tonumber(it.id) == x then xLabel = it.label break end
      end

      mods[#mods+1] = {
        type = 'xenon',
        label = 'Xenon',
        description = xLabel or ('Color %d'):format(x),
        data = { color = x },
        installed = false,
      }
    end
  end

  -- ===== TINT ===== (anggap stock = 0)
  if sel.tint ~= nil then
    local t = tonumber(sel.tint)
    if t and t ~= 0 then
      local tLabel = nil
      for _, it in ipairs(ModMap.windowTints or {}) do
        if tonumber(it.id) == t then tLabel = it.label break end
      end

      mods[#mods+1] = {
        type = 'tint',
        label = 'Window Tint',
        description = tLabel or ('Tint %d'):format(t),
        data = { tint = t },
        installed = false,
      }
    end
  end

  -- ===== PLATE ===== (anggap stock = 0)
  if sel.plate ~= nil then
    local p = tonumber(sel.plate)
    if p and p ~= 0 then
      local pLabel = nil
      for _, it in ipairs(ModMap.plateIndexes or {}) do
        if tonumber(it.id) == p then pLabel = it.label break end
      end

      mods[#mods+1] = {
        type = 'plate',
        label = 'Plate Style',
        description = pLabel or ('Plate %d'):format(p),
        data = { plate = p },
        installed = false,
      }
    end
  end

  -- ===== HORN ===== (stock biasanya -1)
  if sel.horn ~= nil then
    local h = tonumber(sel.horn)
    if h and h >= 0 then
      local hLabel = nil
      for _, it in ipairs(ModMap.horns or {}) do
        if tonumber(it.id) == h then hLabel = it.label break end
      end

      mods[#mods+1] = {
        type = 'horn',
        label = 'Horn',
        description = hLabel or ('Horn %d'):format(h),
        data = { horn = h },
        installed = false,
      }
    end
  end

  return mods
end

RegisterNetEvent('qbx_modifpreview:server:createOrder', function(selection, plate, workshopId)
  local src = source

  -- ini customer yang confirm (boleh non-mechanic)
  local itemName = Config.OrderItemName or 'mod_list_cosmetic'

  local mods = buildModsFromSelection(selection)
  if #mods <= 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Modif', description='Tidak ada mod yang dipilih.' })
    return
  end

  local meta = {
    plate = tostring(plate or ''),
    workshopId = tostring(workshopId or ''),
    createdAt = os.time(),
    mods = mods,
  }

  -- add item
  local ok = inv:AddItem(src, itemName, 1, meta)
  if not ok then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Modif', description='Gagal membuat item mod list.' })
    return
  end

  TriggerClientEvent('ox_lib:notify', src, { type='success', title='Modif', description='Modif list berhasil dibuat.' })
end)

lib.callback.register('qbx_modifpreview:server:isMechanic', function(src)
  return isMechanic(src)
end)

print('[qbx_modifpreview] server main.lua loaded OK')
