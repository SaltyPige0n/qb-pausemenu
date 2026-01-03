local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('qb-pausemenu:server:disconnect', function()
    QBCore.Functions.Kick(source, 'Player disconnected')
end)
