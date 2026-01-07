-- client/order_menu.lua (FINAL)
print('[qbx_modifpreview] client order_menu.lua loading...')

local function buildContext(slot, meta)
  local title = 'Modif List'
  local plate = meta.plate or '-'
  local shop = meta.workshopId or '-'
  local created = meta.createdAt and tostring(meta.createdAt) or '-'

  local opts = {}

  opts[#opts+1] = {
    title = ('Plate: %s'):format(plate),
    description = ('Workshop: %s • %s'):format(shop, created),
    disabled = true,
  }

  opts[#opts+1] = { title = '— Mods (klik untuk install) —', disabled = true }

  for i, m in ipairs(meta.mods or {}) do
    local installed = m.installed == true
    opts[#opts+1] = {
      title = installed and ('~c~%s'):format(m.label or ('Mod #'..i)) or (m.label or ('Mod #'..i)),
      description = installed and 'Sudah terpasang' or 'Klik untuk install (butuh partkit)',
      icon = installed and 'check' or 'wrench',
      disabled = installed,
      onSelect = function()
        TriggerEvent('qbx_modifpreview:client:installOrderMod', slot, i, m, meta)
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
