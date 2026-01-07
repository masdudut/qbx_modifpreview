fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Baba'
description 'Mechanic Preview Mode + Install Kit On garage'
version '0.3.0'

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
  'client/utils_3dtext.lua', -- ⬅️ WAJIB SEBELUM
  'client/mechanic_install.lua',
  'client/order_menu.lua',
  'client/use_modlist.lua',      -- ✅ BARU
  'client/camera.lua',
  'client/preview.lua',
  'client/nui.lua',
  'client/command.lua',
}

server_scripts {
  'server/inv.lua',
  'server/orders.lua',
  'server/install.lua',
  'server/usable.lua',
  'server/main.lua',
}



dependencies {
  'ox_lib',
  'ox_inventory',
  'qbx_core'
}
