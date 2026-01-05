# qbx_modifpreview
for fivem scripts QBX

-- Tambah di ox_inventory items.lua
['mod_list_cosmetic'] = {
			label = 'Modif List',
			weight = 1,
			stack = false,
			close = true,
			description = 'Daftar modifikasi kosmetik untuk mechanic.',
			client = {
			event = 'qbx_modifpreview:client:useModifList'
		}
	},


    
