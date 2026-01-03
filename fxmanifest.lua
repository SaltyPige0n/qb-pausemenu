fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'ProjectPigeon'
description 'Custom QBCore pause menu with NUI tiles and rules'
version '1.0.0'

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js'
}
