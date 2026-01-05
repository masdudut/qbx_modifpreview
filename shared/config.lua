Config = {}

Config.Command = 'modif'
Config.ConfirmCommand = 'modifconfirm'

Config.RequireDriver = true

Config.OrderItemName = 'mod_list_cosmetic'
Config.partkitItemName = 'partkit'


-- Job mechanic yang boleh install (nanti dipakai untuk gating)
Config.AllowedMechanicJobs = {
  mechanic = true,
  bennys = true,
}


Config.Workshops = {
  {
    id = 'bennys',
    coords = vec3(-205.7, -1312.8, 31.3),
    size = vec3(12.0, 16.0, 6.0),
    rotation = 0.0,
  }
}
