-- server/main.lua (FINAL)
print('[qbx_modifpreview] server main.lua loading...')

local function buildModsFromSelected(selected)
  local mods = {}
  selected = selected or {}

  -- PAINTS (hanya jika value bukan stock)
  if selected.paints and selected.paints.value and selected.paints.value ~= 'stock' then
    local colorId = tonumber(selected.paints.value)
    if colorId then
      local cat = tostring(selected.paints.category or 'primary')
      mods[#mods+1] = {
        type = 'paint',
        label = ('Paint: %s'):format(cat),
        data = { category = cat, colorId = colorId },
        installed = false,
      }
    end
  end

  -- WHEELS (hanya jika index dipilih)
  if selected.wheels and (tonumber(selected.wheels.index) or -1) ~= -1 then
    mods[#mods+1] = {
      type = 'wheels',
      label = 'Wheels',
      data = {
        wheelType  = tonumber(selected.wheels.type) or 0,
        wheelIndex = tonumber(selected.wheels.index) or -1,
      },
      installed = false,
    }
  end

  -- BODY (hanya jika index dipilih)
  if selected.body and (tonumber(selected.body.index) or -1) ~= -1 then
    local part = tostring(selected.body.part or 'spoiler')
    local modType = nil
    for _, p in ipairs(ModMap.bodyParts or {}) do
      if p.key == part then modType = tonumber(p.modType) break end
    end
    if modType then
      mods[#mods+1] = {
        type = 'body',
        label = ('Body: %s'):format(part),
        data = { part = part, modType = modType, index = tonumber(selected.body.index) or -1 },
        installed = false,
      }
    end
  end

  -- XENON
  if selected.xenon ~= nil and tonumber(selected.xenon) and tonumber(selected.xenon) ~= -1 then
    mods[#mods+1] = {
      type = 'xenon',
      label = 'Xenon',
      data = { color = tonumber(selected.xenon) },
      installed = false,
    }
  end

  -- TINT
  if selected.tint ~= nil and tonumber(selected.tint) and tonumber(selected.tint) ~= 0 then
    mods[#mods+1] = {
      type = 'tint',
      label = 'Window Tint',
      data = { tint = tonumber(selected.tint) },
      installed = false,
    }
  end

  -- PLATE
  if selected.plate ~= nil and tonumber(selected.plate) and tonumber(selected.plate) ~= 0 then
    mods[#mods+1] = {
      type = 'plate',
      label = 'Plate Style',
      data = { plate = tonumber(selected.plate) },
      installed = false,
    }
  end

  -- HORN
  if selected.horn ~= nil and tonumber(selected.horn) and tonumber(selected.horn) ~= -1 then
    mods[#mods+1] = {
      type = 'horn',
      label = 'Horn',
      data = { horn = tonumber(selected.horn) },
      installed = false,
    }
  end

  return mods
end

RegisterNetEvent('qbx_modifpreview:server:createOrder', function(selected, plate, workshopId)
  local src = source
  local itemName = Config.OrderItemName or 'mod_list_cosmetic'

  local mods = buildModsFromSelected(selected)
  if #mods == 0 then
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Modif', description='Tidak ada mod dipilih.' })
    return
  end

  local meta = {
    plate = tostring(plate or ''),
    workshopId = tostring(workshopId or ''),
    createdAt = os.time(),
    mods = mods,
  }

  local ok, err = Inv_AddItem(src, itemName, 1, meta)
  if ok then
    TriggerClientEvent('ox_lib:notify', src, { type='success', title='Modif', description='Modif List dibuat & masuk inventory.' })
  else
    TriggerClientEvent('ox_lib:notify', src, { type='error', title='Modif', description=('Gagal membuat Modif List: %s'):format(err or 'unknown') })
  end
end)

print('[qbx_modifpreview] server main.lua loaded OK')
