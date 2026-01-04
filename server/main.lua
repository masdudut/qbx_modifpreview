RegisterNetEvent('qbx_modifpreview:server:createOrder', function(selected, plate, workshopId)
  local src = source
  if type(selected) ~= 'table' then return end

  local mods = {}

  -- Paint
  if selected.paint and selected.paint.colorId and selected.paint.colorId ~= 'stock' then
    mods[#mods+1] = {
      type = 'paint',
      label = ('Paint %s'):format(selected.paint.category),
      desc  = ('%s • %s'):format(selected.paint.group or '-', tostring(selected.paint.colorId)),
      which = selected.paint.category,
      color = tonumber(selected.paint.colorId),
      installed = false
    }
  end

  -- Wheels
  if selected.wheels then
    mods[#mods+1] = {
      type='wheelType',
      label='Wheel Type',
      desc=tostring(selected.wheels.wheelType),
      wheelType=tonumber(selected.wheels.wheelType) or 0,
      installed=false
    }
    mods[#mods+1] = {
      type='wheelIndex',
      label='Wheel Index',
      desc=tostring(selected.wheels.wheelIndex),
      index=tonumber(selected.wheels.wheelIndex) or -1,
      installed=false
    }
  end

  -- Body
  if selected.body and selected.body.part and selected.body.index and tonumber(selected.body.index) and tonumber(selected.body.index) >= 0 then
    for _, p in ipairs(ModMap.bodyParts) do
      if p.key == selected.body.part then
        mods[#mods+1] = {
          type='body',
          label=p.label,
          desc=('Index %s'):format(selected.body.index),
          modType=p.modType,
          index=tonumber(selected.body.index) or -1,
          installed=false
        }
        break
      end
    end
  end

  -- Xenon
  if selected.xenon ~= nil and tonumber(selected.xenon) ~= nil then
    mods[#mods+1] = {
      type='xenon',
      label='Xenon Color',
      desc=tostring(selected.xenon),
      xenon=tonumber(selected.xenon) or -1,
      installed=false
    }
  end

  -- Tyre Smoke
  if type(selected.tyreSmoke) == 'table' then
    mods[#mods+1] = {
      type='tyresmoke',
      label='Tyre Smoke',
      desc=selected.tyreSmoke.label or 'Custom',
      r=selected.tyreSmoke.r, g=selected.tyreSmoke.g, b=selected.tyreSmoke.b,
      installed=false
    }
  end

  -- Tint / Plate / Horn
  mods[#mods+1] = { type='tint', label='Window Tint', desc=tostring(selected.tint or 0), tint=tonumber(selected.tint) or 0, installed=false }
  mods[#mods+1] = { type='plate', label='Plate Style', desc=tostring(selected.plate or 0), plate=tonumber(selected.plate) or 0, installed=false }
  mods[#mods+1] = { type='horn', label='Horn', desc=tostring(selected.horn or -1), horn=tonumber(selected.horn) or -1, installed=false }

  local meta = {
    plate = plate or '-',
    workshopId = workshopId or '-',
    mods = mods
  }

  local ok, err = Inv_AddOrderItem(src, Config.OrderItemName, meta)
  if not ok then
    TriggerClientEvent('ox_lib:notify', src, {type='error', title='Modif', description=('Gagal membuat Modif List: %s'):format(err or 'unknown')})
    return
  end

  TriggerClientEvent('ox_lib:notify', src, {type='success', title='Modif', description='Modif List dibuat & masuk inventory.'})
end)
