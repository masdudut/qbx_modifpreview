-- client/nui.lua (FINAL)
print('[qbx_modifpreview] client nui.lua loaded (FINAL)')

local nuiOpen = false

local function setFocus(on)
  SetNuiFocus(on, on)
  SetNuiFocusKeepInput(on and true or false)
end

-- ===== Helpers: GTA label resolve =====
local function resolveGtaLabel(label)
  if not label or label == '' then return nil end
  local txt = GetLabelText(label)
  if not txt or txt == '' or txt == 'NULL' then return nil end
  return txt
end

local function getModName(veh, modType, idx)
  local label = GetModTextLabel(veh, modType, idx)
  local name = resolveGtaLabel(label)
  if name then return name end
  return ('Option %d'):format(idx + 1)
end

local function buildBodyIndexList(modType)
  local veh = Preview_GetVehicle()
  if not veh then return { {label='Stock', value=-1} } end
  SetVehicleModKit(veh, 0)

  local max = GetNumVehicleMods(veh, modType) or 0
  local out = { {label='Stock', value=-1} }
  for i=0, max-1 do
    out[#out+1] = { label = getModName(veh, modType, i), value = i }
  end
  return out
end

local function buildWheelIndexList()
  local veh = Preview_GetVehicle()
  if not veh then return { {label='Stock', value=-1} } end
  SetVehicleModKit(veh, 0)

  local max = GetNumVehicleMods(veh, 23) or 0
  local out = { {label='Stock', value=-1} }
  for i=0, max-1 do
    out[#out+1] = { label = getModName(veh, 23, i), value = i }
  end
  return out
end

local function openNui()
  if nuiOpen then return end
  nuiOpen = true
  setFocus(true)

  local sel = Preview_GetSelected() or {}

  local tabs = {
    { id='paints', label='Paints' },
    { id='wheels', label='Wheels' },
    { id='body',   label='Body (More)' },
    { id='xenon',  label='Xenon' },
    { id='tint',   label='Tint' },
    { id='plate',  label='Plate' },
    { id='horn',   label='Horn' },
  }

  local selected = {
    paints = {
      category = (sel.paints and sel.paints.category) or 'primary',
      type     = (sel.paints and sel.paints.type) or 'Classic',
      value    = (sel.paints and sel.paints.value) or 'stock',
    },
    wheels = {
      type  = (sel.wheels and sel.wheels.type) or 0,
      index = (sel.wheels and sel.wheels.index) or -1,
    },
    body = {
      part  = (sel.body and sel.body.part) or 'spoiler',
      index = (sel.body and sel.body.index) or -1,
    },
    xenon = sel.xenon or -1,
    tint  = sel.tint or 0,
    plate = sel.plate or 0,
    horn  = sel.horn or -1,
  }

  local headersByTab = {
    paints = {
      show = true,
      showH2 = true,
      h1Label = 'Paint Category',
      h1Items = {
        { label='Primary Color',   value='primary' },
        { label='Secondary Color', value='secondary' },
        { label='Pearl Color',     value='pearl' },
        { label='Wheel Color',     value='wheel' },
        { label='Interior Color',  value='interior' },
        { label='Dashboard Color', value='dashboard' },
      },
      h2Label = 'Paint Type',
      h2Items = (function()
        local arr = {}
        for _, g in ipairs(Paints.groups or {}) do
          arr[#arr+1] = { label = g.label, value = g.id }
        end
        return arr
      end)(),
    },

    wheels = {
      show = true,
      showH2 = false, -- OFF
      h1Label = 'Wheel Type',
      h1Items = (function()
        local arr = {}
        for _, w in ipairs(ModMap.wheels or {}) do
          arr[#arr+1] = { label = w.label, value = w.id }
        end
        return arr
      end)(),
    },

    body = {
      show = true,
      showH2 = false, -- OFF
      h1Label = 'Body Part',
      h1Items = (function()
        local arr = {}
        for _, p in ipairs(ModMap.bodyParts or {}) do
          arr[#arr+1] = { label = p.label, value = p.key }
        end
        return arr
      end)(),
    },

    xenon = { show=false },
    tint  = { show=false },
    plate = { show=false },
    horn  = { show=false },
  }

  local optionsByTab = {
    paints = { {label='Stock', value='stock'} }, -- dynamic
    wheels = buildWheelIndexList(),
    body   = { {label='Stock', value=-1} },      -- dynamic

    xenon  = (function()
      local arr = {}
      for _, x in ipairs(ModMap.xenon or {}) do arr[#arr+1] = { label=x.label, value=x.id } end
      return arr
    end)(),
    tint = (function()
      local arr = {}
      for _, t in ipairs(ModMap.windowTints or {}) do arr[#arr+1] = { label=t.label, value=t.id } end
      return arr
    end)(),
    plate = (function()
      local arr = {}
      for _, p in ipairs(ModMap.plateIndexes or {}) do arr[#arr+1] = { label=p.label, value=p.id } end
      return arr
    end)(),
    horn = (function()
      local arr = {}
      for _, h in ipairs(ModMap.horns or {}) do arr[#arr+1] = { label=h.label, value=h.id } end
      return arr
    end)(),
  }

  SendNUIMessage({
    action = 'open',
    tabs = tabs,
    headersByTab = headersByTab,
    optionsByTab = optionsByTab,
    selected = selected,
    currentTab = 'paints',
  })
end

local function closeNui()
  if not nuiOpen then return end
  nuiOpen = false
  setFocus(false)
  SendNUIMessage({ action='close' })
end

RegisterNetEvent('qbx_modifpreview:nui:open', openNui)
RegisterNetEvent('qbx_modifpreview:nui:close', closeNui)

-- camera.lua uses this
RegisterNetEvent('qbx_modifpreview:nui:setFocus', function(on)
  setFocus(on == true)
end)

RegisterNUICallback('cancel', function(_, cb)
  TriggerEvent('qbx_modifpreview:client:cancel')
  cb(true)
end)

RegisterNUICallback('confirm', function(_, cb)
  TriggerEvent('qbx_modifpreview:client:confirm')
  cb(true)
end)

-- ✅ camera button
RegisterNUICallback('camera', function(_, cb)
  TriggerEvent('qbx_modifpreview:client:camera')
  cb(true)
end)

RegisterNUICallback('setHeader', function(data, cb)
  local tab = data.tab
  local which = data.which
  local value = data.value

  if tab == 'paints' then
    if which == 'h1' then TriggerEvent('qbx_modifpreview:client:set', 'paint_category', value) end
    if which == 'h2' then TriggerEvent('qbx_modifpreview:client:set', 'paint_group', value) end
  elseif tab == 'wheels' then
    if which == 'h1' then TriggerEvent('qbx_modifpreview:client:set', 'wheel_type', tonumber(value) or 0) end
  elseif tab == 'body' then
    if which == 'h1' then TriggerEvent('qbx_modifpreview:client:set', 'body_part', value) end
  end

  cb(true)
end)

RegisterNUICallback('selectOption', function(data, cb)
  local tab = data.tab
  local value = data.value

  if tab == 'paints' then
    TriggerEvent('qbx_modifpreview:client:set', 'paint_color', value)
  elseif tab == 'wheels' then
    TriggerEvent('qbx_modifpreview:client:set', 'wheel_index', tonumber(value) or -1)
  elseif tab == 'body' then
    TriggerEvent('qbx_modifpreview:client:set', 'body_index', tonumber(value) or -1)
  elseif tab == 'xenon' then
    TriggerEvent('qbx_modifpreview:client:set', 'xenon', tonumber(value) or -1)
  elseif tab == 'tint' then
    TriggerEvent('qbx_modifpreview:client:set', 'tint', tonumber(value) or 0)
  elseif tab == 'plate' then
    TriggerEvent('qbx_modifpreview:client:set', 'plate', tonumber(value) or 0)
  elseif tab == 'horn' then
    TriggerEvent('qbx_modifpreview:client:set', 'horn', tonumber(value) or -1)
  end

  cb(true)
end)

RegisterNUICallback('requestPaintOptions', function(data, cb)
  local groupId = data.type or data.groupId or 'Classic'
  local list = Paints.list[groupId] or {}
  local out = { {label='Stock', value='stock'} }
  for _, c in ipairs(list) do
    out[#out+1] = { label=c.label, value=c.id }
  end
  cb(out)
end)

RegisterNUICallback('requestWheelIndexOptions', function(_, cb)
  cb(buildWheelIndexList())
end)

RegisterNUICallback('requestBodyOptions', function(data, cb)
  local partKey = data.partKey
  for _, p in ipairs(ModMap.bodyParts or {}) do
    if p.key == partKey then
      cb(buildBodyIndexList(p.modType))
      return
    end
  end
  cb({{label='Stock', value=-1}})
end)

AddEventHandler('onClientResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  nuiOpen = false
  SendNUIMessage({ action='close' })
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
end)
