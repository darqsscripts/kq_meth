
Framework = nil
FrameworkName = "standalone"

Citizen.CreateThread(function()

    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = ESX
        FrameworkName = "esx"
        print("^2[KQ_METH]^7 ESX Framework detected")
        return
    end
    
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = QBCore
        FrameworkName = "qbcore"
        print("^2[KQ_METH]^7 QBCore Framework detected")
        return
    end
    
    print("^3[KQ_METH]^7 No framework detected, running in standalone mode")
end)


function GetPlayer(source)
    if FrameworkName == "esx" then
        return ESX.GetPlayerFromId(source)
    elseif FrameworkName == "qbcore" then
        return QBCore.Functions.GetPlayer(source)
    end
    return nil
end


function GetIdentifier(source)
    if FrameworkName == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    elseif FrameworkName == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    end
    

    local identifiers = GetPlayerIdentifiers(source)
    return identifiers and identifiers[1] or nil
end


function GetPlayerName(source)
    if FrameworkName == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or GetPlayerName(source)
    elseif FrameworkName == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname or GetPlayerName(source)
    end
    
    return GetPlayerName(source)
end


function PlayerHasItem(source, itemName, amount)
    amount = amount or 1
    
    if FrameworkName == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local item = xPlayer.getInventoryItem(itemName)
            return item and item.count >= amount
        end
    elseif FrameworkName == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local item = Player.Functions.GetItemByName(itemName)
            return item and item.amount >= amount
        end
    end
    
    return false
end


function RemovePlayerItem(source, itemName, amount)
    amount = amount or 1
    
    if FrameworkName == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.removeInventoryItem(itemName, amount)
            return true
        end
    elseif FrameworkName == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.RemoveItem(itemName, amount)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "remove", amount)
            return true
        end
    end
    
    return false
end


function AddPlayerItem(source, itemName, amount, metadata)
    amount = amount or 1
    metadata = metadata or {}
    
    if FrameworkName == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if next(metadata) then

                xPlayer.addInventoryItem(itemName, amount, metadata)
            else
                xPlayer.addInventoryItem(itemName, amount)
            end
            return true
        end
    elseif FrameworkName == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.AddItem(itemName, amount, nil, metadata)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "add", amount)
            return true
        end
    end
    
    return false
end

function Notify(source, message, type)
    type = type or 'info'
    TriggerClientEvent('kq_link:Notify', source, message, type)
end


function Debug(...)
    if Config.debug then
        print('^3[KQ_METH DEBUG]^7', ...)
    end
end


function Log(...)
    print('^2[KQ_METH]^7', ...)
end


function L(key)
    if Locale and Locale[key] then
        return Locale[key]
    end
    return key
end


function SendDiscordLog(title, message, color)
    if not Config.discordWebhook then
        return
    end
    
    local embed = {
        {
            ["color"] = color or 3447003,
            ["title"] = title,
            ["description"] = message,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    
    PerformHttpRequest(Config.discordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "KQ Meth",
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end


function GetDistance(coords1, coords2)
    return #(vector3(coords1.x, coords1.y, coords1.z) - vector3(coords2.x, coords2.y, coords2.z))
end


function IsPlayerTooFar(source, coords, maxDistance)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    return GetDistance(playerCoords, coords) > maxDistance
end


local playerCooldowns = {}

function IsPlayerOnCooldown(source, actionName, cooldownTime)
    local identifier = GetIdentifier(source)
    local key = identifier .. "_" .. actionName
    
    if playerCooldowns[key] and playerCooldowns[key] > os.time() then
        return true
    end
    
    playerCooldowns[key] = os.time() + (cooldownTime or 5)
    return false
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) 
        
        local currentTime = os.time()
        for key, expireTime in pairs(playerCooldowns) do
            if expireTime <= currentTime then
                playerCooldowns[key] = nil
            end
        end
    end
end)