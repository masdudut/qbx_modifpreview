local inv = exports.ox_inventory

function Inv_AddOrderItem(src, itemName, metadata)
  -- ox_inventory AddItem -> return boolean, reason?
  return inv:AddItem(src, itemName, 1, metadata)
end

function Inv_GetSlot(src, slot)
  return inv:GetSlot(src, slot)
end

function Inv_RemoveItem(src, itemName, count, slot)
  return inv:RemoveItem(src, itemName, count, nil, slot)
end

function Inv_SetMetadata(src, slot, meta)
  -- beda versi ox_inventory: coba beberapa export
  if inv.SetMetadata then
    return inv:SetMetadata(src, slot, meta)
  end
  if inv.SetSlotMetadata then
    return inv:SetSlotMetadata(src, slot, meta)
  end
  if inv.SetItemMetadata then
    return inv:SetItemMetadata(src, slot, meta)
  end
  return false
end
