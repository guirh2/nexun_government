fx_version 'cerulean'
game 'gta5'

author 'Nexun Dev'
description 'Sistema avançado de Governo'
version '1.0.0'

-- CORREÇÃO: shared_script (SINGULAR)
shared_script 'config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sync.lua',
    'server/main.lua',
    'server/taxes.lua',
    'server/departments.lua',
    'server/protect.lua'
}

client_scripts {
    'client/entry.lua',  -- Adicionei aqui
    'client/main.lua',
    'client/tablet.lua',
    'client/modules/finance.lua',
    'client/modules/health.lua',
    'client/modules/logistic.lua',
    'client/modules/security.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/*.css',
    'web/js/*.js',
    'web/apps/governo/*.html',
    'web/apps/governo/css/*.css',
    'web/apps/governo/js/*.js',
    'web/apps/saude/*.html',
    'web/apps/saude/css/*.css',
    'web/apps/saude/js/*.js',
    'web/assets/*.png',
    'web/assets/*.jpg'
}

dependencies {
    'qb-core',
    'oxmysql'
}

lua54 'yes'