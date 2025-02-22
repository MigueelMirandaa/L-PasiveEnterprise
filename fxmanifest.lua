shared_script '@cfx-gabz-pdprops_1/shared_fg-obfuscated.lua'
shared_script '@cfx-gabz-pdprops_1/ai_module_fg-obfuscated.lua'
fx_version 'cerulean'
games { 'gta5' }
author 'lockserdev'
description '.gg/locksershop'
lua54 'yes'

client_scripts {
    'Client/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'Server/*.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'Shared/*.lua'
}

ui_page 'UI/index.html'

files {
    'UI/*.*'
}

escrow_ignore {
    'Shared/*.*'
}
        