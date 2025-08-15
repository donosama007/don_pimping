shared_script "@ReaperV4/bypass.lua"
lua54 "yes" -- needed for Reaper

fx_version 'cerulean'
game 'gta5'

author 'Donald Draper'
description 'Comprehensive Pimp Management System'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/utils.lua',
    'shared/notifications.lua',
    'shared/permissions.lua',
    'shared/reputation_system.lua',
    'shared/girl_happiness.lua'
}

client_scripts {
    'client/shared_variables.lua', -- Load this first
    'client/utils.lua',
    'client/animations.lua', -- Added new animations file
    'client/discipline.lua',
    'client/main.lua',
    'client/girls.lua',
    'client/npc_interaction.lua',
    'client/negotiation.lua',
    'client/working_notifications.lua',
    'client/territory_system.lua',
    'client/client_notification.lua',
    'client/girl_happiness.lua',
    'client/shop_system.lua' -- Added new shop system script
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db_update.lua',
    'server/main.lua',
    'server/girl_management.lua',
    'server/reputation_perks.lua',
    'server/territory_system.lua',
    'server/discipline_sync.lua',
    'server/girl_happiness.lua',
    'server/db_init.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

-- UI page and files are commented out as they don't exist yet
-- ui_page 'web/index.html'
-- 
-- files {
--     'web/index.html',
--     'web/script.js',
--     'web/style.css',
--     'web/assets/*.png',
--     'web/assets/*.jpg'
-- }