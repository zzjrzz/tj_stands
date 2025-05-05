fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TJ Development'
description 'Advanced Marketplace System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/*.js',
    'html/*.css',
    'locales/*.json'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_target',
    'ox_inventory'
}
