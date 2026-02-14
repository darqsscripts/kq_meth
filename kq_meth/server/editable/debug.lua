-- Commandes de debug et redémarrage sécurisé

-- Commande pour redémarrer le script en toute sécurité
RegisterCommand("kq_meth_restart", function(source, args)
    if source ~= 0 then
        -- Vérifier si le joueur a la permission (modifiez selon votre système)
        if not IsPlayerAceAllowed(source, "command.kq_meth_restart") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Système", "Vous n'avez pas la permission d'utiliser cette commande"}
            })
            return
        end
    end
    
    print("^3[KQ_METH]^7 Redémarrage sécurisé du script...")
    
    -- Notifier tous les clients de se préparer au redémarrage
    TriggerClientEvent(GetCurrentResourceName() .. ':client:safeRestart', -1, source)
    
    -- Attendre que les clients se nettoient
    Citizen.Wait(5000)
    
    print("^2[KQ_METH]^7 Redémarrage du script terminé")
end, false)

-- Commandes de debug (uniquement si Config.debug est activé)
if Config.debug then
    -- Donner tous les items nécessaires pour la meth
    RegisterCommand("givemethitems", function(source, args)
        if source == 0 then return end
        
        AddItem(source, Config.items.meth_lab_kit, 1)
        AddItem(source, Config.items.acetone, 5)
        AddItem(source, Config.items.pills, 5)
        AddItem(source, Config.items.ammonia, 5)
        AddItem(source, Config.items.ethanol, 5)
        AddItem(source, Config.items.lithium, 10)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Debug", "Vous avez reçu tous les items pour la meth"}
        })
    end, false)
    
    -- Donner tous les items nécessaires pour les amphétamines
    RegisterCommand("giveamphetaminesitems", function(source, args)
        if source == 0 then return end
        
        AddItem(source, 'kq_amphetamines_lab_kit', 1)
        AddItem(source, Config.items.acetone, 5)
        AddItem(source, Config.items.ammonia, 5)
        AddItem(source, 'kq_sulfuric_acid', 5)
        AddItem(source, 'kq_sodium', 5)
        AddItem(source, 'kq_amphetamines_cut', 20)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Debug", "Vous avez reçu tous les items pour les amphétamines"}
        })
    end, false)
    
    -- Réinitialiser les stocks d'ammoniaque
    RegisterCommand("resetammonia", function(source, args)
        if source ~= 0 then return end
        
        if Config.itemCollection and Config.itemCollection.ammonia then
            for tankIndex, _ in pairs(Config.itemCollection.ammonia.locations) do
                ammoniaStocks[tankIndex] = {
                    amount = Config.itemCollection.ammonia.ammoniaAmount or 4,
                    refilling = false
                }
            end
        end
        
        print("^2[KQ_METH]^7 Stocks d'ammoniaque réinitialisés")
    end, true)
    
    -- Afficher les cuissons actives
    RegisterCommand("activecooks", function(source, args)
        if source ~= 0 then return end
        
        print("^3=== Cuissons actives ===^7")
        local count = 0
        for netId, cookData in pairs(activeCooks) do
            count = count + 1
            print(string.format("NetID: %s | Joueur: %s | Depuis: %ds", 
                netId, 
                GetPlayerName(cookData.player), 
                os.time() - cookData.startTime
            ))
        end
        
        if count == 0 then
            print("Aucune cuisson active")
        end
        print("^3=====================^7")
    end, true)
    
    -- Afficher les stocks d'ammoniaque
    RegisterCommand("ammoniastocks", function(source, args)
        if source ~= 0 then return end
        
        print("^3=== Stocks d'ammoniaque ===^7")
        for tankIndex, stock in pairs(ammoniaStocks) do
            print(string.format("Tank %d: %d/%d %s", 
                tankIndex, 
                stock.amount, 
                Config.itemCollection.ammonia.ammoniaAmount or 4,
                stock.refilling and "(en cours de remplissage)" or ""
            ))
        end
        print("^3===========================^7")
    end, true)
    
    -- Téléporter vers une zone de loot
    RegisterCommand("tploot", function(source, args)
        if source == 0 then return end
        
        local lootType = args[1]
        local index = tonumber(args[2]) or 1
        
        if not lootType then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 165, 0},
                multiline = true,
                args = {"Debug", "Usage: /tploot [ammonia|battery|ethanol|acetone|pills] [index]"}
            })
            return
        end
        
        local coords = nil
        
        if lootType == "ammonia" and Config.itemCollection and Config.itemCollection.ammonia then
            local location = Config.itemCollection.ammonia.locations[index]
            if location then
                coords = location.coords
            end
        elseif Config.itemCollection and Config.itemCollection.simple then
            for lootKey, lootData in pairs(Config.itemCollection.simple) do
                if string.find(lootKey:lower(), lootType:lower()) or string.find(lootData.label:lower(), lootType:lower()) then
                    local location = lootData.locations[index]
                    if location then
                        coords = location.coords
                        break
                    end
                end
            end
        end
        
        if coords then
            SetEntityCoords(GetPlayerPed(source), coords.x, coords.y, coords.z + 1.0)
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Debug", "Téléporté vers " .. lootType .. " #" .. index}
            })
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Debug", "Zone de loot introuvable"}
            })
        end
    end, false)
    
    -- Afficher les informations de debug
    RegisterCommand("methdebug", function(source, args)
        if source ~= 0 then return end
        
        print("^3=== KQ Meth Debug Info ===^7")
        print("Framework: " .. FrameworkName)
        print("Cuissons actives: " .. TableLength(activeCooks))
        print("Gardes spawnés: " .. (spawnedGuards and TableLength(spawnedGuards) or 0))
        print("Tanks d'ammoniaque: " .. TableLength(ammoniaStocks))
        print("Config.debug: " .. tostring(Config.debug))
        print("^3==========================^7")
    end, true)
end

-- Fonction utilitaire pour compter les éléments d'une table
function TableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end



-- Commandes de debug et redémarrage sécurisé

-- Commande pour redémarrer le script en toute sécurité
RegisterCommand("kq_meth_restart", function(source, args)
    if source ~= 0 then
        if not IsPlayerAceAllowed(source, "command.kq_meth_restart") then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Système", "Vous n'avez pas la permission d'utiliser cette commande"}
            })
            return
        end
    end
    
    print("^3[KQ_METH]^7 Redémarrage sécurisé du script...")
    TriggerClientEvent(GetCurrentResourceName() .. ':client:safeRestart', -1, source)
    Citizen.Wait(5000)
    print("^2[KQ_METH]^7 Redémarrage du script terminé")
end, false)

-- NOUVELLE COMMANDE: Test de cuisson complet
RegisterCommand("testcook", function(source, args)
    if source == 0 then 
        print("^1[ERROR]^7 Cette commande doit être exécutée en jeu")
        return 
    end
    
    local purity = tonumber(args[1]) or 49.40
    local amount = tonumber(args[2]) or 1800
    local drugType = args[3] or "meth"
    
    print("\n^3========================================^7")
    print("^3[TEST COOK]^7 Démarrage du test de cuisson")
    print("^3========================================^7")
    print("Joueur: " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    print("Pureté: " .. purity .. "%")
    print("Amount: " .. amount)
    print("Type: " .. drugType)
    
    local timeCheck = os.time() * 1000
    
    -- Simuler l'événement de succès de cuisson
    TriggerEvent("kq_meth:server:cookingSuccess", source, 0, amount, purity, timeCheck, drugType)
    
    print("^3========================================^7\n")
end, false)

-- NOUVELLE COMMANDE: Vérifier la configuration
RegisterCommand("checkmethconfig", function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, "command.checkmethconfig") then
        return
    end
    
    print("\n^3========================================^7")
    print("^3[CONFIG CHECK]^7 Vérification de la configuration")
    print("^3========================================^7")
    
    if Config and Config.production then
        print("^2✓^7 Config.production existe")
        print("  - maxItemAmountPerBatch: " .. tostring(Config.production.maxItemAmountPerBatch))
        print("  - dontSaveItemMetadata: " .. tostring(Config.production.dontSaveItemMetadata))
        
        if Config.production.itemPerPurity then
            print("^2✓^7 Config.production.itemPerPurity existe (" .. #Config.production.itemPerPurity .. " entrées)")
            for i, purityConfig in ipairs(Config.production.itemPerPurity) do
                print(string.format("    [%d] Pureté >= %d%% => Item: %s", 
                    i, 
                    purityConfig.minimumPurity, 
                    purityConfig.item
                ))
            end
        else
            print("^1✗^7 Config.production.itemPerPurity n'existe pas!")
        end
    else
        print("^1✗^7 Config.production n'existe pas!")
    end
    
    print("\n^3[FRAMEWORK CHECK]^7")
    print("  - Framework détecté: " .. tostring(FrameworkName))
    print("  - ESX: " .. tostring(ESX ~= nil))
    print("  - QBCore: " .. tostring(QBCore ~= nil))
    
    if source ~= 0 then
        local player = GetPlayer(source)
        print("  - Player object: " .. tostring(player ~= nil))
    end
    
    print("^3========================================^7\n")
    
    if source ~= 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Debug", "Vérification terminée, consultez F8"}
        })
    end
end, false)

-- NOUVELLE COMMANDE: Test direct d'ajout d'item
RegisterCommand("testdirectadd", function(source, args)
    if source == 0 then 
        print("^1[ERROR]^7 Cette commande doit être exécutée en jeu")
        return 
    end
    
    local itemName = args[1] or "kq_meth_mid"
    local amount = tonumber(args[2]) or 1
    
    print("\n^3========================================^7")
    print("^3[TEST DIRECT ADD]^7 Test d'ajout direct")
    print("^3========================================^7")
    print("Joueur: " .. GetPlayerName(source))
    print("Item: " .. itemName)
    print("Quantité: " .. amount)
    
    local metadata = {purity = 49.40}
    
    print("\nAppel de AddItem()...")
    local success = AddItem(source, itemName, amount, metadata)
    
    print("Résultat: " .. tostring(success))
    print("^3========================================^7\n")
    
    TriggerClientEvent('chat:addMessage', source, {
        color = success and {0, 255, 0} or {255, 0, 0},
        multiline = true,
        args = {"Test", success and "✓ Item ajouté!" or "✗ Échec de l'ajout"}
    })
end, false)

-- NOUVELLE COMMANDE: Simuler une cuisson complète avec logs détaillés
RegisterCommand("fullcooktest", function(source, args)
    if source == 0 then 
        print("^1[ERROR]^7 Cette commande doit être exécutée en jeu")
        return 
    end
    
    print("\n^3================================================^7")
    print("^3[FULL COOK TEST]^7 Test de cuisson complet avec diagnostic")
    print("^3================================================^7")
    
    -- Étape 1: Vérifier le joueur
    print("\n^5[ÉTAPE 1]^7 Vérification du joueur")
    local player = GetPlayer(source)
    if player then
        print("^2✓^7 Player trouvé: " .. GetPlayerName(source))
    else
        print("^1✗^7 Player non trouvé!")
        return
    end
    
    -- Étape 2: Vérifier la config
    print("\n^5[ÉTAPE 2]^7 Vérification de la configuration")
    if not Config or not Config.production then
        print("^1✗^7 Config.production manquant!")
        return
    end
    print("^2✓^7 Configuration OK")
    
    -- Étape 3: Paramètres de test
    local testPurity = tonumber(args[1]) or 49.40
    local testAmount = tonumber(args[2]) or 1800
    
    print("\n^5[ÉTAPE 3]^7 Paramètres de test")
    print("  Pureté: " .. testPurity .. "%")
    print("  Amount: " .. testAmount)
    
    -- Étape 4: Normalisation de la pureté
    print("\n^5[ÉTAPE 4]^7 Normalisation de la pureté")
    local normalizedPurity = testPurity
    if normalizedPurity > 100 then
        normalizedPurity = normalizedPurity / 100
        print("  Pureté divisée par 100: " .. normalizedPurity)
    elseif normalizedPurity < 1 then
        normalizedPurity = normalizedPurity * 100
        print("  Pureté multipliée par 100: " .. normalizedPurity)
    end
    print("  Pureté finale: " .. normalizedPurity .. "%")
    
    -- Étape 5: Calcul de la quantité
    print("\n^5[ÉTAPE 5]^7 Calcul de la quantité d'items")
    local itemAmount = math.floor((testAmount / 1800) * Config.production.maxItemAmountPerBatch)
    if testAmount > 0 and itemAmount == 0 then
        itemAmount = 1
    end
    print("  Quantité calculée: " .. itemAmount)
    
    -- Étape 6: Détermination de l'item
    print("\n^5[ÉTAPE 6]^7 Détermination de l'item selon la pureté")
    
    local sortedPurity = {}
    for i, purityConfig in ipairs(Config.production.itemPerPurity) do
        table.insert(sortedPurity, purityConfig)
    end
    
    table.sort(sortedPurity, function(a, b)
        return a.minimumPurity > b.minimumPurity
    end)
    
    local itemName = nil
    for i, purityConfig in ipairs(sortedPurity) do
        local matches = normalizedPurity >= purityConfig.minimumPurity
        print(string.format("  Test #%d: %.2f%% >= %d%% ? %s => %s", 
            i,
            normalizedPurity, 
            purityConfig.minimumPurity,
            matches and "^2OUI^7" or "^1NON^7",
            purityConfig.item
        ))
        
        if matches and not itemName then
            itemName = purityConfig.item
            print("  ^2✓ Item sélectionné: " .. itemName .. "^7")
        end
    end
    
    if not itemName then
        print("  ^1✗ AUCUN ITEM TROUVÉ!^7")
        print("\n^3================================================^7")
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Test", "Échec: Aucun item trouvé pour cette pureté"}
        })
        return
    end
    
    -- Étape 7: Préparation des métadonnées
    print("\n^5[ÉTAPE 7]^7 Préparation des métadonnées")
    local metadata = {}
    if not Config.production.dontSaveItemMetadata then
        metadata.purity = math.floor(normalizedPurity * 100) / 100
        print("  Metadata.purity: " .. metadata.purity)
    else
        print("  Pas de métadonnées (dontSaveItemMetadata = true)")
    end
    
    -- Étape 8: Ajout de l'item
    print("\n^5[ÉTAPE 8]^7 Ajout de l'item au joueur")
    print("  Item: " .. itemName)
    print("  Quantité: " .. itemAmount)
    print("  Metadata: " .. json.encode(metadata))
    
    local success = AddItem(source, itemName, itemAmount, metadata)
    
    print("\n^5[RÉSULTAT FINAL]^7")
    if success then
        print("^2✓✓✓ SUCCÈS! L'item a été ajouté avec succès! ✓✓✓^7")
    else
        print("^1✗✗✗ ÉCHEC! L'item n'a pas pu être ajouté! ✗✗✗^7")
    end
    
    print("^3================================================^7\n")
    
    TriggerClientEvent('chat:addMessage', source, {
        color = success and {0, 255, 0} or {255, 0, 0},
        multiline = true,
        args = {"Test Complet", success and "✓ Succès! Vérifiez F8 pour les détails" or "✗ Échec! Vérifiez F8"}
    })
end, false)

-- Commandes de debug existantes (si Config.debug est activé)
if Config.debug then
    -- Donner tous les items nécessaires pour la meth
    RegisterCommand("givemethitems", function(source, args)
        if source == 0 then return end
        
        AddItem(source, Config.items.meth_lab_kit, 1)
        AddItem(source, Config.items.acetone, 5)
        AddItem(source, Config.items.pills, 5)
        AddItem(source, Config.items.ammonia, 5)
        AddItem(source, Config.items.ethanol, 5)
        AddItem(source, Config.items.lithium, 10)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Debug", "Vous avez reçu tous les items pour la meth"}
        })
    end, false)
    
    -- Donner tous les items nécessaires pour les amphétamines
    RegisterCommand("giveamphetaminesitems", function(source, args)
        if source == 0 then return end
        
        AddItem(source, 'kq_amphetamines_lab_kit', 1)
        AddItem(source, Config.items.acetone, 5)
        AddItem(source, Config.items.ammonia, 5)
        AddItem(source, 'kq_sulfuric_acid', 5)
        AddItem(source, 'kq_sodium', 5)
        AddItem(source, 'kq_amphetamines_cut', 20)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Debug", "Vous avez reçu tous les items pour les amphétamines"}
        })
    end, false)
    
    -- Réinitialiser les stocks d'ammoniaque
    RegisterCommand("resetammonia", function(source, args)
        if source ~= 0 then return end
        
        if Config.itemCollection and Config.itemCollection.ammonia then
            for tankIndex, _ in pairs(Config.itemCollection.ammonia.locations) do
                ammoniaStocks[tankIndex] = {
                    amount = Config.itemCollection.ammonia.ammoniaAmount or 4,
                    refilling = false
                }
            end
        end
        
        print("^2[KQ_METH]^7 Stocks d'ammoniaque réinitialisés")
    end, true)
    
    -- Afficher les cuissons actives
    RegisterCommand("activecooks", function(source, args)
        if source ~= 0 then return end
        
        print("^3=== Cuissons actives ===^7")
        local count = 0
        for netId, cookData in pairs(activeCooks) do
            count = count + 1
            print(string.format("NetID: %s | Joueur: %s | Depuis: %ds", 
                netId, 
                GetPlayerName(cookData.player), 
                os.time() - cookData.startTime
            ))
        end
        
        if count == 0 then
            print("Aucune cuisson active")
        end
        print("^3=====================^7")
    end, true)
    
    -- Afficher les stocks d'ammoniaque
    RegisterCommand("ammoniastocks", function(source, args)
        if source ~= 0 then return end
        
        print("^3=== Stocks d'ammoniaque ===^7")
        for tankIndex, stock in pairs(ammoniaStocks) do
            print(string.format("Tank %d: %d/%d %s", 
                tankIndex, 
                stock.amount, 
                Config.itemCollection.ammonia.ammoniaAmount or 4,
                stock.refilling and "(en cours de remplissage)" or ""
            ))
        end
        print("^3===========================^7")
    end, true)
    
    -- Téléporter vers une zone de loot
    RegisterCommand("tploot", function(source, args)
        if source == 0 then return end
        
        local lootType = args[1]
        local index = tonumber(args[2]) or 1
        
        if not lootType then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 165, 0},
                multiline = true,
                args = {"Debug", "Usage: /tploot [ammonia|battery|ethanol|acetone|pills] [index]"}
            })
            return
        end
        
        local coords = nil
        
        if lootType == "ammonia" and Config.itemCollection and Config.itemCollection.ammonia then
            local location = Config.itemCollection.ammonia.locations[index]
            if location then
                coords = location.coords
            end
        elseif Config.itemCollection and Config.itemCollection.simple then
            for lootKey, lootData in pairs(Config.itemCollection.simple) do
                if string.find(lootKey:lower(), lootType:lower()) or string.find(lootData.label:lower(), lootType:lower()) then
                    local location = lootData.locations[index]
                    if location then
                        coords = location.coords
                        break
                    end
                end
            end
        end
        
        if coords then
            SetEntityCoords(GetPlayerPed(source), coords.x, coords.y, coords.z + 1.0)
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Debug", "Téléporté vers " .. lootType .. " #" .. index}
            })
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Debug", "Zone de loot introuvable"}
            })
        end
    end, false)
    
    -- Afficher les informations de debug
    RegisterCommand("methdebug", function(source, args)
        if source ~= 0 then return end
        
        print("^3=== KQ Meth Debug Info ===^7")
        print("Framework: " .. FrameworkName)
        print("Cuissons actives: " .. TableLength(activeCooks))
        print("Gardes spawnés: " .. (spawnedGuards and TableLength(spawnedGuards) or 0))
        print("Tanks d'ammoniaque: " .. TableLength(ammoniaStocks))
        print("Config.debug: " .. tostring(Config.debug))
        print("^3==========================^7")
    end, true)
end

-- Fonction utilitaire pour compter les éléments d'une table
function TableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end




