function PlayGetInAnimation(vehicle)
    Debug("play anim")
    local vehicleSettings = GetVehicleSettings(vehicle)
    if not vehicleSettings.animate then
        DoScreenFadeOut(500)
        Citizen.Wait(700)
        return
    end
    ClearPedTasksImmediately(PlayerPedId())
    RemoveHandWeapons()
    if vehicleSettings.animate == "journey" then
        if IsVanDoorAccessible(vehicle) then
            PlaySynchronisedJourneyEnteringScene(vehicle, true)
        else
            DoScreenFadeOut(500)
            Citizen.Wait(700)
        end
    elseif vehicleSettings.animate == "camper" then
        SetVehicleDoorOpen(vehicle, 3, false, false)
        Citizen.Wait(1000)
        DoScreenFadeOut(500)
        Citizen.Wait(700)
    elseif vehicleSettings.animate == "rumpo" then
        SetVehicleDoorOpen(vehicle, 3, false, false)
        Citizen.Wait(1000)
        DoScreenFadeOut(500)
        Citizen.Wait(700)
    end
end

function PlayGetOutAnimation(vehicle)
    local playerPed = PlayerPedId()
    DoScreenFadeOut(500)
    Citizen.Wait(900)
    ClearPedTasks(playerPed)
    DetachEntity(playerPed)
    local vehicleSettings = GetVehicleSettings(vehicle)
    if IsVanDoorAccessible(vehicle) then
        if vehicleSettings.animate then
            ClearPedTasksImmediately(playerPed)
            ResetEntityAlpha(playerPed)
            if vehicleSettings.animate == "journey" then
                PlaySynchronisedJourneyExitingScene(vehicle)
            elseif vehicleSettings.animate == "camper" then
                DoNormalExit(vehicle)
                Citizen.Wait(1500)
                SetVehicleDoorShut(vehicle, 3, 0)
            elseif vehicleSettings.animate == "rumpo" then
                DoNormalExit(vehicle)
                Citizen.Wait(1500)
                SetVehicleDoorShut(vehicle, 3, 0)
            else
                DoNormalExit(vehicle)
            end
        end
    else
        DoNormalExit(vehicle)
    end
end

function DoNormalExit(vehicle)
    local playerPed = PlayerPedId()
    local vehicleSettings = GetVehicleSettings(vehicle)
    local exitPosition = GetOffsetFromEntityInWorldCoords(vehicle, vehicleSettings.door.exit)
    ResetCookingCamera()
    ResetEntityAlpha(playerPed)
    SetEntityCoords(playerPed, exitPosition)
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
    Citizen.Wait(500)
end

function PlaySynchronisedJourneyEnteringScene(vehicle)
    local playerPed = PlayerPedId()
    local animDict = "oddjobs@hunterintro"
    local pedAnim = "_trevor"
    local vehicleAnim = "_trevor_journey"
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Citizen.Wait(1)
    end
    PlayEnteringCamera(vehicle)
    local scene = NetworkCreateSynchronisedScene(GetEntityCoords(vehicle), GetEntityRotation(vehicle), 2, true, false, 8.0, 1000.0, 1.0)
    NetworkAddPedToSynchronisedScene(playerPed, scene, animDict, pedAnim, 1000.0, 8.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(vehicle, scene, animDict, vehicleAnim, 1.0, 1.0, 1)
    NetworkStartSynchronisedScene(scene)
    Citizen.Wait(GetAnimDuration(animDict, pedAnim) * 1000 - 400)
    PlayAnim("missfbi4prepp1", "walk")
    AttachEntityToEntity(playerPed, vehicle, 0, -0.1, -0.05, 1.0, 0.0, 0.0, 180.0, 0, false, 0, 1, 0, 1)
    Citizen.Wait(1)
    NetworkStopSynchronisedScene(scene)
    Citizen.Wait(100)
    local zOffset = 0.05
    while zOffset < 2.25 do
        Citizen.Wait(6)
        zOffset = zOffset + 0.006
        if zOffset > 0.2 then
            zOffset = zOffset + 0.003
        end
        if zOffset > 0.5 then
            zOffset = zOffset + 0.004
        end
        AttachEntityToEntity(playerPed, vehicle, 0, -0.1, -zOffset, 1.0, 0.0, 0.0, 180.0, 0, false, 0, 1, 0, 1)
    end
    Citizen.Wait(500)
    ClearPedTasks(playerPed)
end

function PlayEnteringCamera(vehicle)
    if Config.other.disableJourneyCameras then
        return
    end
    Citizen.CreateThread(function()
        local timeline = {
            {
                coords = vector3(-3.0, 1.0, 0.6),
                rotation = vector3(0.0, 5.0, 240.0),
                transition = 0,
                duration = 2000
            },
            {
                coords = vector3(-1.1, 0.05, 1.3),
                rotation = vector3(0.0, 0.0, 260.0),
                transition = 4000,
                duration = -600
            },
            {
                coords = vector3(-0.1, -1.0, 1.3),
                rotation = vector3(0.0, 0.0, 200.0),
                transition = 2000,
                duration = -1600
            }
        }
        PlayCameraTimeline(timeline, vehicle, true, false)
    end)
end

function PlaySynchronisedJourneyExitingScene(vehicle)
    local playerPed = PlayerPedId()
    local animDict = "oddjobs@hunteroutro"
    local pedAnim = "_trevor"
    local vehicleAnim = "_trevor_journey"
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Citizen.Wait(1)
    end
    PlayExitingCamera(vehicle)
    local scene = NetworkCreateSynchronisedScene(GetEntityCoords(vehicle), GetEntityRotation(vehicle), 2, true, false, 8.0, 1000.0, 1.0)
    NetworkAddPedToSynchronisedScene(playerPed, scene, animDict, pedAnim, 1000.0, 8.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(vehicle, scene, animDict, vehicleAnim, 1.0, 1.0, 1)
    NetworkStartSynchronisedScene(scene)
    Citizen.Wait(GetAnimDuration(animDict, pedAnim) * 1000 - 1000)
    NetworkStopSynchronisedScene(scene)
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
end

function PlayExitingCamera(vehicle)
    if Config.other.disableJourneyCameras then
        DoScreenFadeIn(500)
        DestroyCam(COOKING_CAMERA)
        return
    end
    Citizen.CreateThread(function()
        local timeline = {
            {
                coords = vector3(-1.25, 0.2, 1.3),
                rotation = vector3(0.0, 0.0, 260.0),
                transition = 0,
                duration = 0
            },
            {
                coords = vector3(-3.0, 1.0, 0.6),
                rotation = vector3(0.0, 5.0, 240.0),
                transition = 0,
                duration = 3500
            }
        }
        PlayCameraTimeline(timeline, vehicle, false, true)
    end)
end

function PlayCameraTimeline(timeline, vehicle, fadeOut, fadeIn)
    for index, cameraData in pairs(timeline) do
        local cameraPosition = GetOffsetFromEntityInWorldCoords(vehicle, cameraData.coords)
        local cameraRotation = GetEntityRotation(vehicle, 5) + cameraData.rotation
        local camera = CreateCinematicCamera(cameraPosition, cameraRotation)
        timeline[index].cam = camera
        if index > 1 then
            TransitionToCamera(camera, timeline[index - 1].cam, cameraData.transition)
        else
            TransitionToCamera(camera, nil, cameraData.transition)
        end
        Citizen.Wait(cameraData.duration + cameraData.transition)
        if fadeIn then
            Citizen.Wait(700)
            DoScreenFadeIn(500)
        end
        if index > 1 then
            DestroyCam(timeline[index - 1].cam, 1)
        end
    end
    if fadeOut then
        DoScreenFadeOut(500)
        Citizen.Wait(500)
    end
    RenderScriptCams(false, not fadeOut, 1000, true, false, false)
    DestroyCam(timeline[#timeline].cam)
end

function CreateCinematicCamera(position, rotation)
    local camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", position, rotation, GetGameplayCamFov(), 1, 5)
    ShakeCinematicCam(camera, 1)
    ShakeCam(camera, "HAND_SHAKE", 1.5)
    return camera
end

function TransitionToCamera(camera, previousCamera, transitionTime)
    if previousCamera then
        SetCamActiveWithInterp(camera, previousCamera, transitionTime, 2, 2)
    end
    RenderScriptCams(true, nil == previousCamera, transitionTime, true, false, false)
end