local deleteModels = {
    'kq_acetone',
    'kq_ammonia',
    'kq_ammonia_tank',
    'kq_ethanol',
    'kq_pot',
    'kq_stove_button',
    'kq_thermometer',
    'kq_tray',
    'kq_valve',
    'kq_battery_stack',
    'ex_office_swag_pills2',
    'prop_cs_pills',
    'kq_portable_stove',
}


local function ContainsHash(tab, val)
    for index, value in ipairs(tab) do
        if GetHashKey(value) == val then
            return true
        end
    end
    
    return false
end


RegisterNetEvent(GetCurrentResourceName() .. ':client:safeRestart')
AddEventHandler(GetCurrentResourceName() .. ':client:safeRestart', function(caller)
    Citizen.Wait(1000)
    local entities = GetGamePool('CObject')
    
    for k, entity in pairs(entities) do
        if DoesEntityExist(entity) then
            if ContainsHash(deleteModels, GetEntityModel(entity)) then
                SetEntityAsMissionEntity(entity, true, true)
                DeleteEntity(entity)
            end
        end
    end
    
    DeleteGuards()
    
    if caller == GetPlayerServerId(PlayerId()) then
        Citizen.Wait(2000)
        
        DoScreenFadeIn(1)
        AnimpostfxStopAll()
        ClearTimecycleModifier()
        
        ExecuteCommand('ensure ' .. GetCurrentResourceName())
    end
end)
