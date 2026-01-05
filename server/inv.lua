-- server/inv.lua
-- Wrapper kecil untuk kompatibilitas beberapa versi ox_inventory

local Ox = exports.ox_inventory

function Inv_AddItem(src, name, count, metadata)
  return Ox:AddItem(src, name, count or 1, metadata)
end

function Inv_GetSlot(src, slot)
  return Ox:GetSlot(src, slot)
end

function Inv_RemoveItem(src, name, count, metadata, slot)
  return Ox:RemoveItem(src, name, count or 1, metadata, slot)
end

function Inv_CountItem(src, name)
  return Ox:GetItemCount(src, name)
end

-- Set metadata: coba beberapa export (beda versi)
function Inv_SetSlotMetadata(src, slot, meta)
  if Ox.SetMetadata then
    local ok = Ox:SetMetadata(src, slot, meta)
    if ok then return true end
  end
  if Ox.SetSlotMetadata then
    local ok = Ox:SetSlotMetadata(src, slot, meta)
    if ok then return true end
  end
  if Ox.SetItemMetadata then
    local ok = Ox:SetItemMetadata(src, slot, meta)
    if ok then return true end
  end
  return false
end
