print('[qbx_modifpreview] client order_menu.lua loading...')

local function fmtTime(ts)
  -- Di client FiveM, library `os` bisa nil → jangan dipakai.
  -- Kalau ts angka unix seconds/ms, tampilkan saja apa adanya.
  if ts == nil then return '-' end
  if type(ts) == 'number' then
    -- coba deteksi ms vs seconds (kalau ms, kecilkan)
    if ts > 2000000000 then
      -- kemungkinan ms
      ts = math.floor(ts / 1000)
    end
    return ('%d'):format(ts)
  end
  return tostring(ts)
end

local function buildContext(slot, meta)
  local title = 'Modif List'
  local plate = meta.plate or '-'
  local shop = meta.workshopId or '-'
  local created = fmtTime(meta.createdAt)

  local opts = {}

  opts[#opts+1] = {
    title = ('Plate: %s'):format(plate),
    description = ('Workshop: %s • Created: %s'):format(shop, created),
    disabled = true,
  }

  opts[#opts+1] = { title = '— Mods (klik untuk install) —', disabled = true }

  for i, m in ipairs(meta.mods or {}) do
    local installed = m.installed == true
    local label = m.label or ('Mod #' .. i)

    opts[#opts+1] = {
      title = installed and ('~c~%s'):format(label) or label,
      description = installed and 'Sudah terpasang' or 'Klik untuk install (butuh partkit)',
      icon = installed and 'check' or 'wrench',
      disabled = installed,
      onSelect = function()
        TriggerEvent('qbx_modifpreview:client:installOrderMod', slot, i, m)
      end
    }
  end

  opts[#opts+1] = { title = '— Actions —', disabled = true }

  opts[#opts+1] = {
    title = 'Delete Modif List',
    description = 'Hapus item mod_list_cosmetic ini.',
    icon = 'trash',
    onSelect = function()
      TriggerServerEvent('qbx_modifpreview:server:deleteOrder', slot)
    end
  }

  return {
    id = 'qbx_modifpreview_order',
    title = title,
    options = opts,
  }
end

RegisterNetEvent('qbx_modifpreview:client:openOrderMenu', function(slot, meta)
  if type(meta) ~= 'table' then
    lib.notify({ type='error', title='Order', description='Metadata tidak valid.' })
    return
  end

  local ctx = buildContext(slot, meta)
  lib.registerContext(ctx)
  lib.showContext(ctx.id)
end)

print('[qbx_modifpreview] client order_menu.lua loaded OK')
