local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isOpen = false
local allowPauseMenu = false
local pauseMenuOpened = false
local allowPauseMenuUntil = 0
local suppressOpenUntil = 0
local isLoggedIn = false
local config = Config or {}
local INPUT_PAUSE = 200
local INPUT_P = 199
local INPUT_LOOK_LR = 1
local INPUT_LOOK_UD = 2
local INPUT_ATTACK = 24
local INPUT_AIM = 25
local INPUT_MELEE_ATTACK_ALT = 142
local INPUT_VEH_MOUSE_CONTROL_OVERRIDE = 106
local INPUT_GROUP = 0

local GetGameTimer = GetGameTimer
local IsPauseMenuActive = IsPauseMenuActive
local SetPauseMenuActive = SetPauseMenuActive
local DisableControlAction = DisableControlAction
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local GetActivePlayers = GetActivePlayers
local GetConvarInt = GetConvarInt

local function getJobLabel(job)
    if not job then
        return 'Unemployed'
    end

    local label = job.label or job.name or 'Unemployed'
    if type(job.grade) == 'table' then
        if job.grade.name and job.grade.name ~= '' then
            label = label .. ' - ' .. job.grade.name
        elseif job.grade.level and job.grade.level > 0 then
            label = label .. ' - ' .. tostring(job.grade.level)
        end
    end

    return label
end

local function buildPauseData()
    local data = PlayerData or {}
    local money = data.money or {}
    local charinfo = data.charinfo or {}
    return {
        cash = money.cash or 0,
        bank = money.bank or 0,
        id = GetPlayerServerId(PlayerId()),
        cid = data.citizenid or 'N/A',
        job = getJobLabel(data.job),
        name = (charinfo.firstname and charinfo.lastname) and (charinfo.firstname .. ' ' .. charinfo.lastname) or '',
        onlineCount = #GetActivePlayers(),
        onlineMax = GetConvarInt('sv_maxclients', 64),
        rules = config.Rules or {},
        rulesTitle = config.RulesTitle or 'RP Rules',
        discordUrl = config.DiscordUrl or '',
        discordLabel = config.DiscordLabel or 'Join Our Discord',
        discordTag = config.DiscordTag or '',
        showStatusBox = config.ShowStatusBox ~= false
    }
end

local function openPauseMenu()
    if isOpen then return end

    PlayerData = QBCore.Functions.GetPlayerData()
    SendNUIMessage({
        action = 'open',
        data = buildPauseData()
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    isOpen = true
end

local function closePauseMenu()
    if not isOpen then return end

    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    isOpen = false
end

local function openFrontendPauseMenu()
    closePauseMenu()
    allowPauseMenu = true
    pauseMenuOpened = false
    allowPauseMenuUntil = GetGameTimer() + 3000
    suppressOpenUntil = GetGameTimer() + 800
    ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_MP_PAUSE'), false, -1)
    SendNUIMessage({ action = 'uiDisabled' })
    SetNuiFocus(false, false)
end

local function openLandingMenu()
    closePauseMenu()
    allowPauseMenu = true
    pauseMenuOpened = false
    allowPauseMenuUntil = GetGameTimer() + 3000
    suppressOpenUntil = GetGameTimer() + 800
    ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_LANDING_MENU'), false, -1)
    SendNUIMessage({ action = 'uiDisabled' })
    SetNuiFocus(false, false)
end

RegisterNUICallback('close', function(_, cb)
    closePauseMenu()
    cb('ok')
end)

RegisterNUICallback('settings', function(_, cb)
    openLandingMenu()
    cb('ok')
end)

RegisterNUICallback('map', function(_, cb)
    openFrontendPauseMenu()
    cb('ok')
end)

RegisterNUICallback('quit', function(_, cb)
    closePauseMenu()
    cb('ok')
    TriggerServerEvent('qb-pausemenu:server:disconnect')
end)

RegisterNUICallback('discord', function(_, cb)
    TriggerEvent('qb-pausemenu:client:OpenDiscord')
    cb('ok')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    closePauseMenu()
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
    if isOpen then
        SendNUIMessage({ action = 'update', data = buildPauseData() })
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
    if isOpen then
        SendNUIMessage({ action = 'update', data = buildPauseData() })
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = LocalPlayer.state.isLoggedIn
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if isOpen then
        SetNuiFocus(false, false)
    end
end)

CreateThread(function()
    while true do
        if isLoggedIn then
            local now = GetGameTimer()
            local pauseActive = IsPauseMenuActive()

            if allowPauseMenu then
                if pauseActive then
                    pauseMenuOpened = true
                elseif pauseMenuOpened then
                    allowPauseMenu = false
                    pauseMenuOpened = false
                    suppressOpenUntil = now + 400
                elseif now > allowPauseMenuUntil then
                    allowPauseMenu = false
                end
            end

            if not allowPauseMenu then
                if pauseActive then
                    SetPauseMenuActive(false)
                end

                DisableControlAction(INPUT_GROUP, INPUT_PAUSE, true) -- ESC
                DisableControlAction(INPUT_GROUP, INPUT_P, true) -- P

                if not isOpen and now > suppressOpenUntil then
                    if IsDisabledControlJustReleased(INPUT_GROUP, INPUT_PAUSE) or IsDisabledControlJustReleased(INPUT_GROUP, INPUT_P) then
                        openPauseMenu()
                    end
                end
            end

            if isOpen then
                DisableControlAction(INPUT_GROUP, INPUT_LOOK_LR, true)
                DisableControlAction(INPUT_GROUP, INPUT_LOOK_UD, true)
                DisableControlAction(INPUT_GROUP, INPUT_ATTACK, true)
                DisableControlAction(INPUT_GROUP, INPUT_AIM, true)
                DisableControlAction(INPUT_GROUP, INPUT_MELEE_ATTACK_ALT, true)
                DisableControlAction(INPUT_GROUP, INPUT_VEH_MOUSE_CONTROL_OVERRIDE, true)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)
