-- client/order_menu.lua (FINAL)
print('[qbx_modifpreview] client order_menu.lua loading...')

local currentSlot, currentMeta

local function isInstalled(m) return m and m.installed == true end

RegisterNetEvent('qbx_modifpreview:client:openOrderMenu', function(slot, meta)
  currentSlot = tonumber(slot)
  currentMeta = meta

  local isMech = lib.callback.await('qbx_modifpreview:server:isMechanic', false)
  if not isMech then
    lib.notify({ type='error', title='Order', description='Hanya mechanic yang bisa install.' })
    return
  end

  if not Workshop_IsInside() then
    lib.notify({ type='error', title='Order', description='Kamu harus berada di zona bengkel.' })
    return
  end

  local opts = {}

  opts[#opts+1] = {
    title = ('Plate: %s'):format(meta.plate or '-'),
    description = ('Workshop: %s'):format(meta.workshopId or '-'),
    disabled = true
  }

  opts[#opts+1] = { title = '—', disabled = true }

  for i, m in ipairs(meta.mods or {}) do
    local installed = isInstalled(m)
    opts[#opts+1] = {
      title = installed and ('✅ %s'):format(m.label or ('Mod %d'):format(i)) or (m.label or ('Mod %d'):format(i)),
      description = installed and 'Installed' or (m.description or 'Click to install'),
      disabled = installed,
      onSelect = function()
        TriggerEvent('qbx_modifpreview:client:installOrderMod', currentSlot, i, m)
      end
    }
  end

  opts[#opts+1] = { title = '—', disabled = true }

  opts[#opts+1] = {
    title = '🗑 Delete Modif List',
    description = 'Hapus item mod_list dari inventory',
    onSelect = function()
      TriggerServerEvent('qbx_modifpreview:server:deleteOrder', currentSlot)
    end
  }

  lib.registerContext({
    id = 'qbx_modifpreview_order_menu',
    title = 'Modif List',
    options = opts
  })

  lib.showContext('qbx_modifpreview_order_menu')
end)

RegisterNetEvent('qbx_modifpreview:client:orderMetaUpdated', function(slot, meta)
  if tonumber(slot) ~= tonumber(currentSlot) then return end
  currentMeta = meta
  TriggerEvent('qbx_modifpreview:client:openOrderMenu', currentSlot, currentMeta)
end)

print('[qbx_modifpreview] client order_menu.lua loaded OK')

RegisterNetEvent('qbx_modifpreview:client:useModifList', function(item)
  -- item biasanya berisi: slot, metadata, name, count, dll
  if not item or not item.slot then
    lib.notify({ type = 'error', title = 'Order', description = 'Slot item tidak terbaca.' })
    return
  end

  -- kalau metadata ada, langsung buka UI (lebih cepat, tanpa server)
  if type(item.metadata) == 'table' and type(item.metadata.mods) == 'table' then
    TriggerEvent('qbx_modifpreview:client:openOrderMenu', item.slot, item.metadata)
    return
  end

  -- fallback: minta server ambil metadata slot yang benar
  TriggerServerEvent('qbx_modifpreview:server:useModListSlot', item.slot)
end)
