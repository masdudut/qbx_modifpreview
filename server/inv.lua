-- server/inv.lua (FINAL)
print('[qbx_modifpreview] server inv.lua loading...')

local inv = exports.ox_inventory

-- pcall wrapper supaya tidak error "No such export ..."
local function tryCall(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return true, res end
  return false, nil
end

function Inv_GetSlot(src, slot)
  if not src or not slot then return nil end
  local ok, item = tryCall(inv.GetSlot, inv, src, slot)
  if ok then return item end
  -- fallback (beberapa versi pakai :GetSlot)
  ok, item = tryCall(inv.GetSlot, src, slot)
  if ok then return item end
  return nil
end

function Inv_AddItem(src, itemName, count, metadata)
  if not src or not itemName then return false, 'bad_args' end
  count = tonumber(count) or 1

  local ok, res = tryCall(inv.AddItem, inv, src, itemName, count, metadata)
  if ok then
    if res == true or res then return true end
    return false, 'add_failed'
  end

  ok, res = tryCall(inv.AddItem, src, itemName, count, metadata)
  if ok then
    if res == true or res then return true end
    return false, 'add_failed'
  end

  return false, 'add_export_missing'
end

-- Update metadata slot: coba beberapa export yang umum.
function Inv_SetMetadata(src, slot, metadata)
  if not src or not slot then return false end

  local candidates = {
    function() return inv:SetMetadata(src, slot, metadata) end,
    function() return inv:SetSlotMetadata(src, slot, metadata) end,
    function() return inv:SetItemMetadata(src, slot, metadata) end,
    function() return inv:SetMetadata(src, slot, metadata, true) end, -- beberapa build butuh flag
  }

  for _, f in ipairs(candidates) do
    local ok, res = pcall(f)
    if ok and (res == true or res == nil or res) then
      return true
    end
  end

  return false
end

print('[qbx_modifpreview] server inv.lua loaded OK')
