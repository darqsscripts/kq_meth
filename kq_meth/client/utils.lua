local COOLDOWN = 0

function IsCooldown(cooldownTime)
  local time = cooldownTime or 1500
  return COOLDOWN + time > GetGameTimer()
end

function SetCooldown()
  COOLDOWN = GetGameTimer()
end

function GetClosestVehicleWithModel(modelName, maxDistance)
  local vehicle, distance = UseCache("GetClosestVehicleWithModel" .. modelName .. maxDistance, function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestDistance = maxDistance
    local closestVehicle = nil
    
    for _, veh in pairs(GetGamePool("CVehicle")) do
      if GetEntityModel(veh) == GetHashKey(modelName) then
        local vehCoords = GetEntityCoords(veh)
        local dist = #(playerCoords - vehCoords)
        if dist < closestDistance then
          closestDistance = dist
          closestVehicle = veh
        end
      end
    end
    
    return closestVehicle, closestDistance
  end, 1000)
  
  if not DoesEntityExist(vehicle) then
    return nil, distance
  end
  
  return vehicle, distance
end

function SyncWalkToCoords(coords, heading, timeout)
  local playerPed = PlayerPedId()
  TaskGoStraightToCoord(playerPed, coords, 1.0, timeout, heading, 0.45)
  
  local distance = #(GetEntityCoords(playerPed) - coords)
  local endTime = GetGameTimer() + timeout
  
  while distance > 0.4 and GetGameTimer() < endTime do
    distance = #(GetEntityCoords(playerPed) - coords)
    Citizen.Wait(50)
  end
end

function SetEntitySize(entity, scale)
  local rightVector, forwardVector, upVector, position = GetEntityMatrix(entity)
  
  local shouldAdjust = false
  if scale > 1.0 and upVector.z <= 1.0 then
    shouldAdjust = true
  end
  if scale < 1.0 and upVector.z >= 1.0 then
    shouldAdjust = true
  end
  
  if shouldAdjust then
    position = position + vector3(0.0, 0.0, scale - 1)
    rightVector = rightVector * scale
    forwardVector = forwardVector * scale
    upVector = upVector * scale
  end
  
  SetEntityMatrix(entity, rightVector, forwardVector, upVector, position)
end

function PlayAnim(dict, anim, duration, ped)
  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do
    Citizen.Wait(100)
  end
  
  TaskPlayAnim(ped or PlayerPedId(), dict, anim, 1.4, 1.4, 5.0, duration or 1, 1, false, false, false)
  RemoveAnimDict(dict)
end

function DoRequestModel(model)
  local hash = model
  if type(model) ~= "number" then
    hash = GetHashKey(model)
  end
  
  RequestModel(hash)
  local timeout = 2000
  
  while not HasModelLoaded(hash) and timeout > 0 do
    Citizen.Wait(50)
    RequestModel(hash)
    timeout = timeout - 20
  end
  
  if timeout <= 0 then
    print("^1Requesting of a model timed out \"" .. hash .. ":" .. model .. "\"")
    return false
  end
  
  return true
end

function DeleteNearestOfType(coords, modelHash, radius)
  local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius or 2.0, modelHash, 0, 0, 0)
  
  while object ~= 0 do
    SetEntityAsMissionEntity(object, 1, 1)
    DeleteEntity(object)
    object = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius or 2.0, modelHash, 0, 0, 0)
    Citizen.Wait(10)
  end
end

function FaceCoordinates(targetCoords)
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)
  local targetHeading = GetHeadingFromVector_2d(targetCoords.x - playerCoords.x, targetCoords.y - playerCoords.y)
  local currentHeading = GetEntityHeading(playerPed)
  
  if currentHeading > targetHeading + 25 or currentHeading < targetHeading - 25 then
    TaskTurnPedToFaceCoord(playerPed, targetCoords, 1000)
    Citizen.Wait(1200)
  end
end

function RemoveHandWeapons()
  SetCurrentPedWeapon(PlayerPedId(), -1569615261, true)
end

function Contains(table, value)
  for _, item in ipairs(table) do
    if item == value then
      return true
    end
  end
  return false
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