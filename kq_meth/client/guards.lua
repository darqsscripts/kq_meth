local guardInstances = {}
local GuardStatus = {
    combat = "COMBAT",
    returning = "RETURNING",
    idle = "IDLE",
    dead = "DEAD",
    respawning = "RESPAWNING"
}

function DeleteGuards()
    for _, guard in pairs(guardInstances) do
        if DoesEntityExist(guard.entity) then
            DeleteEntity(guard.entity)
        end
    end
end

function GetPlayerPedsCached()
    return UseCache("GetPlayerPedsCached", function()
        local playerPeds = {}
        for _, playerId in ipairs(GetActivePlayers()) do
            local playerPed = GetPlayerPed(playerId)
            table.insert(playerPeds, playerPed)
        end
        return playerPeds
    end, 3000)
end

function GetNearbyPlayers(position, radius)
    local cachedPeds = GetPlayerPedsCached()
    local nearbyPlayers = {}
    for _, ped in pairs(cachedPeds) do
        local pedCoords = GetEntityCoords(ped)
        local distance = #(pedCoords - position)
        if radius >= distance then
            table.insert(nearbyPlayers, ped)
        end
    end
    return nearbyPlayers
end

function CreateGuardInstance(pedEntity)
    local instance = {}
    instance.entity = pedEntity
    instance.owned = false
    instance.state = {}
    instance.lastPushedState = {}

    function instance.Boot()
        instance.FetchBaseState()
        instance.FetchState()
        instance.SetPedAttributes()
        Citizen.Wait(20)
        instance.MainThread()
    end

    function instance.SetPedAttributes()
        SetBlockingOfNonTemporaryEvents(instance.entity, true)
        SetPedDropsWeaponsWhenDead(instance.entity, false)
        SetPedCanSwitchWeapon(instance.entity, true)
        SetEntityAsMissionEntity(instance.entity, true, false)
    end

    function instance.FetchBaseState()
        local entityState = Entity(instance.entity).state.kq_meth_ped_base
        if not entityState then
            return
        end
        for key, value in pairs(entityState) do
            instance[key] = value
        end
    end

    function instance.FetchState()
        local entityState = Entity(instance.entity).state.kq_meth_ped_state
        if not entityState then
            entityState = {}
        end
        instance.state = entityState
    end

    function instance.PushState()
        instance.state.netOwner = GetPlayerServerId(NetworkGetEntityOwner(instance.entity))
        instance.state.lastUpdate = GetNetworkTime()
        Entity(instance.entity).state:set("kq_meth_ped_state", instance.state, true)
    end

    function instance.MainThread()
        Citizen.CreateThread(function()
            while instance ~= nil do
                local waitTime = 5000
                instance.FetchState()
                if NetworkHasControlOfEntity(instance.entity) then
                    waitTime = 2000
                    instance.CheckAliveState()
                    if instance.state.status ~= GuardStatus.respawning then
                        instance.PerformActions()
                    end
                    instance.PushState()
                end
                Citizen.Wait(waitTime)
            end
        end)
    end

    function instance.SetStatus(newStatus)
        if instance.state.status == newStatus then
            return
        end
        instance.state.status = newStatus
    end

    function instance.PerformActions()
        instance.FindCombatTargets()
        local nearestTarget = instance.GetNearestTarget()
        if nearestTarget then
            instance.CombatTarget(nearestTarget)
        else
            local distanceFromSpawn = #(instance.coords - GetEntityCoords(instance.entity))
            if distanceFromSpawn > 0.5 then
                instance.ReturnToSpawn()
            else
                instance.PlayBaseAnim()
            end
        end
    end

    function instance.CheckAliveState()
        if instance.state.status ~= GuardStatus.respawning then
            if not DoesEntityExist(instance.entity) or GetEntityHealth(instance.entity) <= 0.0 then
                TriggerServerEvent("kq_meth:server:ped:respawn", instance.key)
                instance.SetStatus(GuardStatus.respawning)
            end
        end
    end

    function instance.PlayBaseAnim()
        instance.PlayAnim(instance.animation.dict, instance.animation.name)
        instance.SetStatus(GuardStatus.idle)
    end

    function instance.PlayAnim(animDict, animName, animFlag)
        if IsEntityPlayingAnim(instance.entity, animDict, animName, animFlag) then
            return
        end
        Citizen.CreateThread(function()
            while instance and not HasAnimDictLoaded(instance.animation.dict) do
                RequestAnimDict(instance.animation.dict)
                Citizen.Wait(20)
            end
            if not instance then
                return
            end
            TaskPlayAnim(instance.entity, animDict, animName, 2.0, 2.0, -1, animFlag or 1, 1.0, 0, 0, 0)
        end)
    end

    function instance.ReturnToSpawn()
        TaskFollowNavMeshToCoord(instance.entity, instance.coords, 2.0, -1, 0.1, 0, instance.heading)
        instance.SetStatus(GuardStatus.returning)
    end

    function instance.CombatTarget(targetData)
        local targetEntity = NetworkGetEntityFromNetworkId(targetData.netId)
        if instance.state.lastTarget ~= targetData.netId then
            ClearPedTasks(instance.entity)
        end
        instance.state.lastTarget = targetData.netId
        TaskCombatPed(instance.entity, targetEntity, 0, 16)
        instance.SetStatus(GuardStatus.combat)
    end

    function instance.GetNearestTarget()
        local nearestTarget = nil
        local nearestDistance = 50
        local myCoords = GetEntityCoords(instance.entity)
        for netId, targetData in pairs(instance.state.targets or {}) do
            if NetworkDoesNetworkIdExist(netId) then
                local targetEntity = NetworkGetEntityFromNetworkId(netId)
                if targetData.timeout >= GetNetworkTime() and GetEntityHealth(targetEntity) > 0.0 then
                    local targetDistance = #(GetEntityCoords(targetEntity) - myCoords)
                    if nearestDistance > targetDistance then
                        nearestTarget = targetData
                        nearestDistance = targetDistance
                    end
                else
                    instance.RemoveCombatTarget(targetEntity)
                end
            end
        end
        return nearestTarget, nearestDistance
    end

    function instance.FindCombatTargets()
        if not instance.guard then
            return
        end
        local nearbyPlayers = GetNearbyPlayers(instance.guard.coords, instance.guard.radius)
        for _, playerPed in pairs(nearbyPlayers) do
            instance.AddCombatTarget(playerPed)
        end
    end

    function instance.AddCombatTarget(targetEntity)
        if not instance.state.targets then
            instance.state.targets = {}
        end
        if not NetworkGetEntityIsNetworked(targetEntity) then
            return
        end
        local targetNetId = NetworkGetNetworkIdFromEntity(targetEntity)
        instance.state.targets[targetNetId] = {
            netId = NetworkGetNetworkIdFromEntity(targetEntity),
            timeout = GetNetworkTime() + 60000
        }
    end

    function instance.RemoveCombatTarget(targetEntity)
        if not instance.state.targets then
            instance.state.targets = {}
            return
        end
        local targetNetId = NetworkGetNetworkIdFromEntity(targetEntity)
        instance.state.targets[targetNetId] = nil
    end

    function instance.ResetCombatTarget()
        instance.state.targets = {}
    end

    function instance.Delete()
        SetPedAsNoLongerNeeded(instance.entity)
        guardInstances[instance.entity] = nil
        instance = nil
    end

    instance.Boot()
    guardInstances[instance.entity] = instance
    return instance
end

local globalInitKey = GlobalState.kq_meth_init_key
Citizen.SetTimeout(3000, function()
    globalInitKey = GlobalState.kq_meth_init_key
end)

function IsMethGuardPed(pedEntity)
    return UseCache("isMethPed" .. pedEntity, function()
        if not DoesEntityExist(pedEntity) then
            return false
        end
        local entityState = Entity(pedEntity).state.kq_meth_ped_base
        local guardInstance = guardInstances[pedEntity]
        return guardInstance ~= nil or entityState ~= nil
    end, 5000)
end

function GetAllMethGuardPeds()
    return UseCache("GetMethPeds", function()
        local methPeds = {}
        for _, ped in pairs(GetGamePool("CPed")) do
            if IsMethGuardPed(ped) and DoesEntityExist(ped) then
                table.insert(methPeds, ped)
            end
        end
        return methPeds
    end, 5000)
end

Citizen.CreateThread(function()
    while true do
        local waitTime = 1000
        for _, ped in pairs(GetAllMethGuardPeds()) do
            if not guardInstances[ped] and IsEntityAMissionEntity(ped) then
                CreateGuardInstance(ped)
            end
        end
        for pedEntity, guardInstance in pairs(guardInstances) do
            if not DoesEntityExist(pedEntity) or not IsEntityAMissionEntity(pedEntity) then
                guardInstance.Delete()
            end
        end
        Citizen.Wait(waitTime)
    end
end)

if Config.debug then
    function DrawGuardDebugInfo(guardInstance)
        local pedCoords = GetEntityCoords(guardInstance.entity)
        local debugText = json.encode(guardInstance.state, {indent = true})
        SetTextScale(0.28, 0.28)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextDropshadow(1, 1, 1, 1, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(0)
        AddTextEntry("meth_ped_info", debugText)
        SetTextEntry("meth_ped_info")
        SetDrawOrigin(pedCoords, 0)
        DrawText(0.0, 0.0)
        ClearDrawOrigin()
    end

    function DrawGuardLiveState(guardInstance)
        local offsetCoords = GetOffsetFromEntityInWorldCoords(guardInstance.entity, vector3(-1.0, 0, 0))
        local liveState = UseCache("liveState" .. guardInstance.entity, function()
            return Entity(guardInstance.entity).state.kq_meth_ped_state
        end, 500)
        local stateText = "~g~" .. json.encode(liveState, {indent = true})
        SetTextScale(0.28, 0.28)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextDropshadow(1, 1, 1, 1, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(0)
        AddTextEntry("meth_ped_info2", stateText)
        SetTextEntry("meth_ped_info2")
        SetDrawOrigin(offsetCoords, 0)
        DrawText(0.0, 0.0)
        ClearDrawOrigin()
    end

    Citizen.CreateThread(function()
        while true do
            local waitTime = 5000
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            for _, guardInstance in pairs(guardInstances) do
                local guardCoords = GetEntityCoords(guardInstance.entity)
                local distance = #(playerCoords - guardCoords)
                if distance <= 5.0 then
                    waitTime = 1
                    DrawGuardLiveState(guardInstance)
                    DrawGuardDebugInfo(guardInstance)
                end
            end
            Citizen.Wait(waitTime)
        end
    end)
end