COOKING_MODE = false
COOKING_CAMERA = nil
IS_DRAGGING = false
DRAGGING_RESOURCE = nil
SELECTED_INTERACTABLE = nil
COOKING_TRAY = nil
PROCESS_STARTED = false
TRAY_TIMEOUT = nil
COOK_TYPE = nil
AMPHETAMINES_CUTTING_COUNT = 0
AMPHETAMINES_PROGRESSED = false
MIXER_RESOURCE = nil

function GetAmphetaminesData()
    local amphetaminesData = GlobalState.kq_meth_amphetamines
    return amphetaminesData
end

function ResetGlobalValues()
    IS_DRAGGING = false
    DRAGGING_RESOURCE = nil
    SELECTED_INTERACTABLE = nil
    COOKING_TRAY = nil
    TRAY_TIMEOUT = nil
    PROCESS_STARTED = false
    COOK_TYPE = nil
    AMPHETAMINES_PROGRESSED = false
    AMPHETAMINES_CUTTING_COUNT = 0
    MIXER_RESOURCE = nil
end

if IsInCookingMode() then
    local playerPed = PlayerPedId()
    DoScreenFadeIn(1)
    DetachEntity(playerPed, 1, 0)
    SetCookingMode(false)
    ResetEntityAlpha(playerPed)
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
    LeaveCursorMode()
end

function IsVanOccupied(vehicle)
    local entityState = Entity(vehicle).state
    local isOccupied = nil ~= entityState.kq_meth_cook
    return isOccupied
end

RegisterNetEvent("kq_meth:client:freezeEntity")
AddEventHandler("kq_meth:client:freezeEntity", function(networkId, shouldFreeze)
    FreezeEntityPosition(NetworkGetEntityFromNetworkId(networkId), shouldFreeze)
end)