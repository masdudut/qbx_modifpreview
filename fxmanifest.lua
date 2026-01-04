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
  'client/camera.lua',     -- IMPORTANT: sebelum preview.lua
  'client/preview.lua',
  'client/nui.lua',
  'client/command.lua',
  'client/order_menu.lua',
}

server_scripts {
  'server/inv.lua',
  'server/orders.lua',
  'server/usable.lua',
  'server/main.lua',
}

dependencies {
  'ox_lib',
  'ox_inventory',
  'qbx_core'
}
