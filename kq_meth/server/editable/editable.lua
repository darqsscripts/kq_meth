-- Fonction personnalisée pour ajouter un item
function AddItem(source, itemName, amount, metadata)
    amount = amount or 1
    metadata = metadata or {}
    
    print(string.format("^3[KQ_METH DEBUG]^7 Tentative d'ajout de %dx %s au joueur %s", amount, itemName, GetPlayerName(source)))
    print("^3[KQ_METH DEBUG]^7 Metadata:", json.encode(metadata))
    
    -- Pour ESX
    if FrameworkName == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if Config.production.dontSaveItemMetadata or not next(metadata) then
                xPlayer.addInventoryItem(itemName, amount)
                print(string.format("^2[KQ_METH SUCCESS]^7 ESX: Item %s x%d ajouté avec succès", itemName, amount))
            else
                -- Pour ESX avec support des métadonnées (ox_inventory)
                if GetResourceState('ox_inventory') == 'started' then
                    local success = exports.ox_inventory:AddItem(source, itemName, amount, metadata)
                    print(string.format("^2[KQ_METH SUCCESS]^7 ESX+OX: Item %s x%d ajouté: %s", itemName, amount, tostring(success)))
                    if success then
                        TriggerClientEvent('kq_link:Notify', source, 
                            string.format("Vous avez reçu %dx %s", amount, itemName), 'success')
                    end
                    return success
                else
                    xPlayer.addInventoryItem(itemName, amount)
                    print(string.format("^2[KQ_METH SUCCESS]^7 ESX: Item %s x%d ajouté (metadata ignorées)", itemName, amount))
                end
            end
            
            -- Notification au joueur
            TriggerClientEvent('kq_link:Notify', source, 
                string.format("Vous avez reçu %dx %s", amount, itemName), 'success')
            return true
        else
            print("^1[KQ_METH ERROR]^7 xPlayer non trouvé pour le joueur " .. source)
        end
    end
    
    -- Pour QBCore
    if FrameworkName == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local info = metadata
            if Config.production.dontSaveItemMetadata then
                info = {}
            end
            
            local success = Player.Functions.AddItem(itemName, amount, nil, info)
            print(string.format("^2[KQ_METH SUCCESS]^7 QBCore: Item %s x%d ajouté: %s", itemName, amount, tostring(success)))
            
            if success then
                TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], "add", amount)
                TriggerClientEvent('kq_link:Notify', source, 
                    string.format("Vous avez reçu %dx %s", amount, itemName), 'success')
            end
            return success
        else
            print("^1[KQ_METH ERROR]^7 Player non trouvé pour le joueur " .. source)
        end
    end
    
    -- Pour ox_inventory (standalone)
    if GetResourceState('ox_inventory') == 'started' then
        local success
        if Config.production.dontSaveItemMetadata or not next(metadata) then
            success = exports.ox_inventory:AddItem(source, itemName, amount)
        else
            success = exports.ox_inventory:AddItem(source, itemName, amount, metadata)
        end
        
        print(string.format("^2[KQ_METH SUCCESS]^7 OX_INVENTORY: Item %s x%d ajouté: %s", itemName, amount, tostring(success)))
        
        if success then
            TriggerClientEvent('kq_link:Notify', source, 
                string.format("Vous avez reçu %dx %s", amount, itemName), 'success')
        end
        return success
    end
    
    print("^1[KQ_METH ERROR]^7 Aucun système d'inventaire compatible trouvé!")
    return false
end

-- Test pour vérifier quel framework est détecté
RegisterCommand("testframework", function(source, args)
    if source == 0 then return end
    
    print("^3=== TEST FRAMEWORK ===^7")
    print("Framework détecté: " .. FrameworkName)
    print("ESX: " .. tostring(ESX ~= nil))
    print("QBCore: " .. tostring(QBCore ~= nil))
    print("ox_inventory: " .. GetResourceState('ox_inventory'))
    
    local player = GetPlayer(source)
    print("Player object: " .. tostring(player ~= nil))
    
    if player then
        print("^2Player trouvé!^7")
    else
        print("^1Player non trouvé!^7")
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"Debug", "Framework: " .. FrameworkName .. " | Player: " .. tostring(player ~= nil)}
    })
end, false)

-- Commande de test pour ajouter un item
RegisterCommand("testadditem", function(source, args)
    if source == 0 then return end
    
    local itemName = args[1] or "bread"
    local amount = tonumber(args[2]) or 1
    
    print(string.format("^3[TEST]^7 Ajout de %dx %s au joueur %s", amount, itemName, GetPlayerName(source)))
    
    local success = AddItem(source, itemName, amount)
    
    if success then
        print("^2[TEST] Succès!^7")
    else
        print("^1[TEST] Échec!^7")
    end
end, false)

-- Commande pour diagnostiquer l'inventaire
RegisterCommand("diagmeth", function(source, args)
    if source == 0 then
        print("Cette commande doit être exécutée par un joueur")
        return
    end
    
    print("^3=== DIAGNOSTIC KQ_METH ===^7")
    print("Joueur: " .. GetPlayerName(source) .. " (" .. source .. ")")
    
    -- Test 1: Framework
    print("\n^3[1] Framework:^7")
    print("  - FrameworkName: " .. tostring(FrameworkName))
    print("  - ESX existe: " .. tostring(ESX ~= nil))
    print("  - QBCore existe: " .. tostring(QBCore ~= nil))
    
    -- Test 2: Ressources
    print("\n^3[2] Ressources:^7")
    print("  - es_extended: " .. GetResourceState('es_extended'))
    print("  - qb-core: " .. GetResourceState('qb-core'))
    print("  - ox_inventory: " .. GetResourceState('ox_inventory'))
    print("  - kq_link: " .. GetResourceState('kq_link'))
    
    -- Test 3: Player Object
    print("\n^3[3] Player Object:^7")
    if FrameworkName == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            print("  - ESX xPlayer: ^2TROUVÉ^7")
            print("  - Identifier: " .. tostring(xPlayer.identifier))
            print("  - Name: " .. tostring(xPlayer.getName()))
            
            -- Test ajout d'item ESX
            print("\n^3[4] Test ajout item (bread):^7")
            local beforeCount = xPlayer.getInventoryItem('bread')
            print("  - Avant: " .. tostring(beforeCount and beforeCount.count or 0))
            
            xPlayer.addInventoryItem('bread', 1)
            
            Citizen.Wait(100)
            local afterCount = xPlayer.getInventoryItem('bread')
            print("  - Après: " .. tostring(afterCount and afterCount.count or 0))
            
            if afterCount and beforeCount and afterCount.count > beforeCount.count then
                print("  - ^2SUCCÈS: Item ajouté!^7")
            else
                print("  - ^1ÉCHEC: Item non ajouté!^7")
            end
        else
            print("  - ESX xPlayer: ^1NON TROUVÉ^7")
        end
    elseif FrameworkName == "qbcore" and QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            print("  - QBCore Player: ^2TROUVÉ^7")
            print("  - CitizenID: " .. tostring(Player.PlayerData.citizenid))
            print("  - Name: " .. tostring(Player.PlayerData.charinfo.firstname))
            
            -- Test ajout d'item QBCore
            print("\n^3[4] Test ajout item (bread):^7")
            local success = Player.Functions.AddItem('bread', 1)
            print("  - Résultat: " .. tostring(success))
        else
            print("  - QBCore Player: ^1NON TROUVÉ^7")
        end
    else
        print("  - ^1Aucun framework détecté^7")
    end
    
    -- Test 4: Config items
    print("\n^3[5] Config Items:^7")
    print("  - meth_lab_kit: " .. tostring(Config.items.meth_lab_kit))
    print("  - acetone: " .. tostring(Config.items.acetone))
    print("  - ammonia: " .. tostring(Config.items.ammonia))
    
    -- Test de la configuration de production
    print("\n^3[6] Configuration Production:^7")
    print("  - maxItemAmountPerBatch: " .. tostring(Config.production.maxItemAmountPerBatch))
    print("  - dontSaveItemMetadata: " .. tostring(Config.production.dontSaveItemMetadata))
    for i, purityConfig in ipairs(Config.production.itemPerPurity) do
        print(string.format("  - Purity #%d: %d%% => %s", i, purityConfig.minimumPurity, purityConfig.item))
    end
    
    print("\n^3======================^7\n")
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"Debug", "Diagnostic terminé, vérifiez la console serveur (F8)"}
    })
end, false)

-- Commande pour tester l'ajout d'un item de meth
RegisterCommand("testmethadd", function(source, args)
    if source == 0 then return end
    
    local purityArg = tonumber(args[1]) or 49.40
    local itemName = args[2] or "kq_meth_mid"
    local amount = tonumber(args[3]) or 5
    
    print(string.format("^3[TEST METH]^7 Test d'ajout de %dx %s avec pureté %.2f%%", amount, itemName, purityArg))
    
    local metadata = {}
    if not Config.production.dontSaveItemMetadata then
        metadata.purity = purityArg
    end
    
    local result = AddItem(source, itemName, amount, metadata)
    
    print(string.format("^3[TEST METH]^7 Résultat: %s", tostring(result)))
    
    TriggerClientEvent('chat:addMessage', source, {
        color = result and {0, 255, 0} or {255, 0, 0},
        multiline = true,
        args = {"Test", result and "Item ajouté avec succès!" or "Échec de l'ajout"}
    })
end, false)