fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'qbx_modifpreview'
version '0.2.0'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/style.css',
  'web/app.js',
}

shared_scripts {
  '@ox_lib/init.lua',
  'shared/config.lua',
  'shared/modmap.lua',
  'shared/paints.lua',
}

client_scripts {
  'client/workshops.lua',

  -- camera harus ada sebelum preview (preview manggil camera)
  'client/camera.lua',

  -- preview expose Preview_GetVehicle/Selected untuk nui.lua
  'client/preview.lua',

  -- nui open/close + callbacks
  'client/nui.lua',

  -- UI modlist / menu mechanic (boleh setelah nui, tapi tidak wajib)
  'client/order_menu.lua',
  'client/mechanic_install.lua',

  -- command terakhir (dia trigger startPreview dll)
  'client/command.lua',
}

server_scripts {
  -- kalau inv/install/orders/main saling pakai, aman urut begini:
  'server/inv.lua',
  'server/install.lua',
  'server/orders.lua',
  'server/usable.lua',
  'server/main.lua',
}

dependencies {
  'ox_lib',
  'ox_inventory',
  'qbx_core'
}
