fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Astro'
description 'Custom UI qb-management with qb-banking and randol_billing integration'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua',
    'shared/sh_config.lua',
    'shared/sh_themes.lua',
    'shared/sh_businesses.lua'
}

client_scripts {
    'client/cl_utils.lua',
    'client/cl_theme.lua',
    'client/cl_nui.lua',
    'client/cl_main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_main.lua',
    'server/sv_permissions.lua',
    'server/sv_banking.lua',
    'server/sv_employees.lua',
    'server/sv_bonuses.lua',
    'server/sv_billing.lua',
    'server/sv_logs.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/themes.js'
}