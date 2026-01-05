fx_version 'cerulean'
game 'gta5'

name 'nexun_government'
author 'Nexun Dev'
version '2.0.0'
description 'Sistema de Governo Avançado - Logística, Impostos e Patrimônio'

shared_scripts {
    '@qb-core/shared/main.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/utils.lua',
    'client/modules/*.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/protect.lua', -- Cadeado de autenticidade
    'server/modules/*.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/*.css',
    'web/js/*.js',
    'web/assets/**/*',
}

lua54 'yes'