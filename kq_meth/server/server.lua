-- Variables globales
local activeCooks = {}
local ammoniaStocks = {}
local simpleLootCooldowns = {}

-- CORRECTION CRITIQUE: Ne pas utiliser de cache, utiliser Config directement
-- Cela évite les problèmes de synchronisation

-- Initialisation des stocks d'ammoniaque
Citizen.CreateThread(function()
    -- Attendre que Config soit chargé
    Citizen.Wait(1000)
    
    if Config.itemCollection and Config.itemCollection.ammonia then
        for tankIndex, _ in pairs(Config.itemCollection.ammonia.locations) do
            ammoniaStocks[tankIndex] = {
                amount = Config.itemCollection.ammonia.ammoniaAmount or 4,
                refilling = false
            }
        end
    end
    
    -- Vérifier que la config est bien chargée
    if Config and Config.production then
        print("^2[KQ_METH]^7 Configuration chargée:")
        print("  - maxItemAmountPerBatch:", Config.production.maxItemAmountPerBatch)
        print("  - itemPerPurity count:", #Config.production.itemPerPurity)
        print("  - Seuils de pureté:")
        for i, purityConfig in ipairs(Config.production.itemPerPurity) do
            print(string.format("    [%d] >= %d%% => %s", i, purityConfig.minimumPurity, purityConfig.item))
        end
    else
        print("^1[KQ_METH ERROR]^7 Config.production non trouvé!")
    end
end)

-- Gestion du début de cuisson
RegisterNetEvent("kq_meth:server:startedCooking")
AddEventHandler("kq_meth:server:startedCooking", function(vehicleNetId)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if not DoesEntityExist(vehicle) then
        return
    end
    
    activeCooks[vehicleNetId] = {
        player = source,
        startTime = os.time()
    }
    
    Entity(vehicle).state:set("kq_meth_cook", source, true)
    TriggerClientEvent("kq_meth:client:freezeEntity", -1, vehicleNetId, true)
end)

-- Gestion de l'arrêt de cuisson
RegisterNetEvent("kq_meth:server:stoppedCooking")
AddEventHandler("kq_meth:server:stoppedCooking", function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if DoesEntityExist(vehicle) then
        Entity(vehicle).state:set("kq_meth_cook", nil, true)
        TriggerClientEvent("kq_meth:client:freezeEntity", -1, vehicleNetId, false)
    end
    
    activeCooks[vehicleNetId] = nil
end)

-- Détection des types de drogue disponibles
RegisterNetEvent("kq_meth:server:detectDrugCookTypes")
AddEventHandler("kq_meth:server:detectDrugCookTypes", function()
    local source = source
    local items = {}
    
    -- Vérifier si le joueur a les items nécessaires
    items.meth_lab_kit = PlayerHasItem(source, Config.items.meth_lab_kit, 1)
    items.amphetamines_lab_kit = PlayerHasItem(source, 'kq_amphetamines_lab_kit', 1)
    
    TriggerClientEvent("kq_meth:client:detectDrugCookTypes", source, items)
end)

-- Prise des ressources de base pour la méthamphétamine
RegisterNetEvent("kq_meth:server:takeBaseMethResources")
AddEventHandler("kq_meth:server:takeBaseMethResources", function()
    local source = source
    local items = {}
    
    -- Retirer les items du joueur
    if RemovePlayerItem(source, Config.items.meth_lab_kit, 1) then
        items.meth_lab_kit = true
    end
    
    if PlayerHasItem(source, Config.items.acetone, 1) and RemovePlayerItem(source, Config.items.acetone, 1) then
        items.acetone = true
    end
    
    if PlayerHasItem(source, Config.items.pills, 1) and RemovePlayerItem(source, Config.items.pills, 1) then
        items.pills = true
    end
    
    if PlayerHasItem(source, Config.items.ammonia, 1) and RemovePlayerItem(source, Config.items.ammonia, 1) then
        items.ammonia = true
    end
    
    if PlayerHasItem(source, Config.items.ethanol, 1) and RemovePlayerItem(source, Config.items.ethanol, 1) then
        items.ethanol = true
    end
    
    -- Compter les plaques de lithium
    local lithiumCount = 0
    for i = 1, 3 do
        if PlayerHasItem(source, Config.items.lithium, 1) and RemovePlayerItem(source, Config.items.lithium, 1) then
            lithiumCount = lithiumCount + 1
        else
            break
        end
    end
    
    if lithiumCount > 0 then
        items.lithium = { amount = lithiumCount }
    end
    
    local timeCheck = os.time() * 1000
    TriggerClientEvent("kq_meth:client:spawnBaseMethResources", source, items, timeCheck)
end)

-- Prise des ressources de base pour les amphétamines
RegisterNetEvent("kq_meth:server:takeBaseAmphetaminesResources")
AddEventHandler("kq_meth:server:takeBaseAmphetaminesResources", function()
    local source = source
    local items = {}
    
    -- Retirer les items du joueur
    if RemovePlayerItem(source, 'kq_amphetamines_lab_kit', 1) then
        items.amphetamines_lab_kit = true
    end
    
    if PlayerHasItem(source, Config.items.acetone, 1) and RemovePlayerItem(source, Config.items.acetone, 1) then
        items.acetone = true
    end
    
    if PlayerHasItem(source, Config.items.ammonia, 1) and RemovePlayerItem(source, Config.items.ammonia, 1) then
        items.ammonia = true
    end
    
    if PlayerHasItem(source, 'kq_sulfuric_acid', 1) and RemovePlayerItem(source, 'kq_sulfuric_acid', 1) then
        items.sulfuric_acid = true
    end
    
    if PlayerHasItem(source, 'kq_sodium', 1) and RemovePlayerItem(source, 'kq_sodium', 1) then
        items.sodium = true
    end
    
    -- Compter les agents de coupe
    local cuttingCount = 0
    for i = 1, 20 do
        if PlayerHasItem(source, 'kq_amphetamines_cut', 1) and RemovePlayerItem(source, 'kq_amphetamines_cut', 1) then
            cuttingCount = cuttingCount + 1
        else
            break
        end
    end
    
    if cuttingCount > 0 then
        items.amphetamines_cut = { amount = cuttingCount }
    end
    
    local timeCheck = os.time() * 1000
    TriggerClientEvent("kq_meth:client:spawnBaseAmphetaminesResources", source, items, timeCheck)
end)

-- Succès de la cuisson (VERSION FINALE - ULTRA CORRIGÉE)
-- Succès de la cuisson (VERSION ULTIME - ULTRA SIMPLIFIÉE)
RegisterNetEvent("kq_meth:server:cookingSuccess")
AddEventHandler("kq_meth:server:cookingSuccess", function(vehicleNetId, amount, purity, timeCheck, drugType)
    local source = source
    
    print("\n^3========================================^7")
    print("^2[KQ_METH]^7 cookingSuccess appelé")
    print("^3========================================^7")
    print("Joueur: " .. GetPlayerName(source) .. " (ID: " .. source .. ")")
    print("Amount brut: " .. tostring(amount))
    print("Purity brute: " .. tostring(purity))
    print("DrugType: " .. tostring(drugType))
    
    -- Validation basique
    if not source or source == 0 then
        print("^1[ERROR]^7 Source invalide")
        return
    end
    
    if type(purity) ~= "number" or type(amount) ~= "number" then
        print("^1[ERROR]^7 Types invalides - purity:", type(purity), "amount:", type(amount))
        return
    end
    
    if drugType ~= "meth" and drugType ~= "amphetamines" then
        print("^1[ERROR]^7 DrugType invalide:", drugType)
        return
    end
    
    -- Normaliser la pureté (toujours entre 0 et 100)
    local normalizedPurity = purity
    if purity > 100 then
        normalizedPurity = purity / 100
    elseif purity < 1 then
        normalizedPurity = purity * 100
    end
    
    print("\n^5[NORMALISATION]^7")
    print("Pureté normalisée: " .. normalizedPurity .. "%")
    
    -- TRAITEMENT METH
    if drugType == "meth" then
        print("\n^5[CALCUL METH]^7")
        
        -- Vérifier que Config existe
        if not Config or not Config.production then
            print("^1[ERROR]^7 Config.production manquant!")
            return
        end
        
        print("Config.production.maxItemAmountPerBatch: " .. tostring(Config.production.maxItemAmountPerBatch))
        
        -- Calcul de la quantité avec GARANTIE minimum
        local baseAmount = math.floor((amount / 1800) * Config.production.maxItemAmountPerBatch)
        local itemAmount = baseAmount
        
        print("Calcul: (" .. amount .. " / 1800) * " .. Config.production.maxItemAmountPerBatch .. " = " .. baseAmount)
        
        -- GARANTIE: Au moins 1 item si amount > 0
        if amount > 0 and itemAmount == 0 then
            itemAmount = 1
            print("^3[CORRECTION]^7 Quantité forcée à 1 (minimum garanti)")
        end
        
        -- GARANTIE SUPPLÉMENTAIRE: Échelle alternative
        if amount >= 50 and itemAmount == 0 then
            itemAmount = math.max(1, math.ceil(amount / 300))
            print("^3[CORRECTION]^7 Quantité recalculée avec échelle alternative: " .. itemAmount)
        end
        
        print("Quantité FINALE: " .. itemAmount)
        
        if itemAmount <= 0 then
            print("^1[ERROR]^7 Quantité invalide après tous les calculs!")
            return
        end
        
        -- Trouver l'item correspondant à la pureté
        print("\n^5[SÉLECTION ITEM]^7")
        print("Recherche pour pureté: " .. normalizedPurity .. "%")
        
        if not Config.production.itemPerPurity then
            print("^1[ERROR]^7 Config.production.itemPerPurity manquant!")
            return
        end
        
        print("Nombre de seuils configurés: " .. #Config.production.itemPerPurity)
        
        -- Trier par pureté décroissante
        local sortedItems = {}
        for _, purityConfig in ipairs(Config.production.itemPerPurity) do
            table.insert(sortedItems, {
                minPurity = purityConfig.minimumPurity,
                item = purityConfig.item
            })
        end
        
        table.sort(sortedItems, function(a, b)
            return a.minPurity > b.minPurity
        end)
        
        -- Afficher les seuils
        print("\nSeuils disponibles (du plus élevé au plus bas):")
        for i, config in ipairs(sortedItems) do
            print(string.format("  [%d] Pureté >= %d%% => %s", i, config.minPurity, config.item))
        end
        
        -- Trouver le premier match
        local selectedItem = nil
        print("\nTests de correspondance:")
        for i, config in ipairs(sortedItems) do
            local matches = normalizedPurity >= config.minPurity
            print(string.format("  Test #%d: %.2f >= %d ? %s", 
                i, 
                normalizedPurity, 
                config.minPurity, 
                matches and "^2OUI^7" or "^1NON^7"
            ))
            
            if matches and not selectedItem then
                selectedItem = config.item
                print("  ^2✓ SÉLECTIONNÉ: " .. selectedItem .. "^7")
                break
            end
        end
        
        if not selectedItem then
            print("^1[ERROR]^7 Aucun item trouvé pour cette pureté!")
            print("^1[ERROR]^7 La pureté " .. normalizedPurity .. "% ne correspond à aucun seuil configuré")
            return
        end
        
        -- Préparer les métadonnées
        local metadata = {}
        if not Config.production.dontSaveItemMetadata then
            metadata.purity = math.floor(normalizedPurity * 100) / 100
        end
        
        -- AJOUT DE L'ITEM
        print("\n^5[AJOUT ITEM]^7")
        print("Item: " .. selectedItem)
        print("Quantité: " .. itemAmount)
        print("Metadata: " .. json.encode(metadata))
        
        local success = AddItem(source, selectedItem, itemAmount, metadata)
        
        print("\n^5[RÉSULTAT]^7")
        if success then
            print("^2✓✓✓ SUCCÈS! ✓✓✓^7")
            print("^2" .. GetPlayerName(source) .. " a reçu " .. itemAmount .. "x " .. selectedItem .. "^7")
        else
            print("^1✗✗✗ ÉCHEC! ✗✗✗^7")
            print("^1La fonction AddItem a retourné false^7")
            print("^1Vérifiez:")
            print("  - Que l'item '" .. selectedItem .. "' existe")
            print("  - Que le joueur a de la place")
            print("  - Les logs de votre framework/inventaire^7")
        end
        
    -- TRAITEMENT AMPHETAMINES
    elseif drugType == "amphetamines" then
        print("\n^5[CALCUL AMPHETAMINES]^7")
        local amphetaminesData = GlobalState.kq_meth_amphetamines
        
        if not amphetaminesData then
            print("^1[ERROR]^7 Données amphetamines manquantes!")
            return
        end
        
        local itemAmount = math.floor((amount / 1000) * amphetaminesData.production.itemsPer1000g)
        
        if amount > 0 and itemAmount == 0 then
            itemAmount = 1
        end
        
        local sortedItems = {}
        for _, purityConfig in pairs(amphetaminesData.production.itemPerPurity) do
            table.insert(sortedItems, {
                minPurity = purityConfig.minimumPurity,
                item = purityConfig.item
            })
        end
        
        table.sort(sortedItems, function(a, b)
            return a.minPurity > b.minPurity
        end)
        
        local selectedItem = nil
        for _, config in ipairs(sortedItems) do
            if normalizedPurity >= config.minPurity then
                selectedItem = config.item
                break
            end
        end
        
        if not selectedItem then
            print("^1[ERROR]^7 Aucun item amphetamines trouvé!")
            return
        end
        
        local metadata = {}
        if not Config.production.dontSaveItemMetadata then
            metadata.purity = math.floor(normalizedPurity * 100) / 100
        end
        
        local success = AddItem(source, selectedItem, itemAmount, metadata)
        
        if success then
            print("^2✓ Amphetamines ajoutées avec succès!^7")
        else
            print("^1✗ Échec de l'ajout des amphetamines^7")
        end
    end
    
    print("^3========================================^7\n")
end)

-- Remboursement des ressources
RegisterNetEvent("kq_meth:server:refundResources")
AddEventHandler("kq_meth:server:refundResources", function(refundItems)
    local source = source
    
    for itemKey, _ in pairs(refundItems) do
        local itemName = GetItemNameFromKey(itemKey)
        if itemName then
            AddPlayerItem(source, itemName, 1)
        end
    end
end)

-- Collecte d'ammoniaque
RegisterNetEvent("kq_meth:server:takeAmmonia")
AddEventHandler("kq_meth:server:takeAmmonia", function(tankIndex)
    local source = source
    
    if not ammoniaStocks[tankIndex] then
        return
    end
    
    local stock = ammoniaStocks[tankIndex]
    
    if stock.refilling then
        Notify(source, L('This tank is being refilled'), 'error')
        return
    end
    
    if stock.amount <= 0 then
        Notify(source, L('This tank is empty'), 'error')
        
        stock.refilling = true
        local refillTime = (Config.itemCollection.ammonia.refillTime or 20) * 60000
        
        Citizen.SetTimeout(refillTime, function()
            stock.amount = Config.itemCollection.ammonia.ammoniaAmount or 4
            stock.refilling = false
        end)
        
        return
    end
    
    if AddPlayerItem(source, Config.items.ammonia, 1) then
        stock.amount = stock.amount - 1
        TriggerClientEvent("kq_meth:client:pourAmmoniaFromValve", -1, tankIndex)
    end
end)

-- Collecte de loot simple
RegisterNetEvent("kq_meth:server:simpleLoot")
AddEventHandler("kq_meth:server:simpleLoot", function(lootKey, locationKey)
    local source = source
    local identifier = GetIdentifier(source)
    local cooldownKey = identifier .. "_" .. lootKey .. "_" .. locationKey
    
    if simpleLootCooldowns[cooldownKey] and simpleLootCooldowns[cooldownKey] > os.time() then
        Notify(source, L('You must wait before collecting this again'), 'error')
        return
    end
    
    local lootData = Config.itemCollection.simple[lootKey]
    if not lootData then
        return
    end
    
    if AddPlayerItem(source, lootData.item, lootData.amount) then
        simpleLootCooldowns[cooldownKey] = os.time() + 600
    end
end)

-- Gestion de la fumée du van
RegisterNetEvent("kq_meth:server:startVanSmoke")
AddEventHandler("kq_meth:server:startVanSmoke", function(networkId, coords, cookType)
    TriggerClientEvent("kq_meth:client:startVanSmoke", -1, networkId, coords, cookType)
end)

RegisterNetEvent("kq_meth:server:stopVanSmoke")
AddEventHandler("kq_meth:server:stopVanSmoke", function(networkId)
    TriggerClientEvent("kq_meth:client:stopVanSmoke", -1, networkId)
end)

-- Fonctions utilitaires
function GetItemNameFromKey(itemKey)
    local mapping = {
        acetone = Config.items.acetone,
        pills = Config.items.pills,
        ammonia = Config.items.ammonia,
        ethanol = Config.items.ethanol,
        lithium = Config.items.lithium,
    }
    
    return mapping[itemKey]
end

function Debug(...)
    if Config.debug then
        print(...)
    end
end

function L(key)
    if Locale and Locale[key] then
        return Locale[key]
    end
    return key
end