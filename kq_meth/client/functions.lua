local gasMaskEffectEndTime

function PlayGetInAnimation(vehicle) end
function PlayGetOutAnimation(vehicle) end

function GetVehicleSettings(vehicle)
  for model, settings in pairs(Settings.vehicles) do
    if GetHashKey(model) == GetEntityModel(vehicle) then
      return settings
    end
  end
  return Settings.vehicles[1]
end

function GetActiveVehicle()
  return LocalPlayer.state.kq_meth_cooking_van
end

function SetActiveVan(vehicle)
  LocalPlayer.state.kq_meth_cooking_van = vehicle
end

function IsInCookingMode()
  return UseCache("IsInCookingMode", function()
    return LocalPlayer.state.kq_meth_cooking_mode
  end, 500)
end

function SetCookingMode(enabled)
  LocalPlayer.state.kq_meth_cooking_mode = enabled
  WipeCache("IsInCookingMode")
end

function CounterCoordsToVehicleCoords(counterCoords)
  local startOffset, endOffset = GetVanTableOffsets()
  local midPoint = (startOffset + endOffset) / 2
  return counterCoords + midPoint
end

function StartEnterVan(vehicle)
  SetActiveVan(vehicle)
  local vehicleSettings = GetVehicleSettings(vehicle)
  local doorPosition = GetOffsetFromEntityInWorldCoords(vehicle, vehicleSettings.door.offset)
  SyncWalkToCoords(doorPosition, GetEntityHeading(vehicle) + 90.0, 3500)
  
  if IsVanOccupied(vehicle) then
    ClearPedTasks(PlayerPedId())
    return
  end
  
  TriggerServerEvent("kq_meth:server:startedCooking", NetworkGetNetworkIdFromEntity(vehicle))
  PlayGetInAnimation(vehicle)
  EnterCookingMode(vehicle)
  DoScreenFadeIn(500)
end

function StartExitVan(vehicle)
  LeaveCursorMode()
  Debug("ExitCookingMode", "StartExitVan")
  ExitCookingMode(vehicle)
  PlayGetOutAnimation(vehicle)
  DoScreenFadeIn(500)
end

function OnResourceExploded()
  local activeVehicle = GetActiveVehicle()
  local playerPed = PlayerPedId()
  
  LeaveCursorMode()
  ExitCookingMode()
  SetEntityNoCollisionEntity(playerPed, activeVehicle, false)
  
  Citizen.Wait(500)
  DoScreenFadeOut(100)
  Citizen.Wait(250)
  
  ClearPedTasksImmediately(playerPed)
  DetachEntity(playerPed)
  ResetEntityAlpha(playerPed)
  ResetCookingCamera()
  
  local vehicleSettings = GetVehicleSettings(activeVehicle)
  local exitPosition = GetOffsetFromEntityInWorldCoords(activeVehicle, vehicleSettings.spaceCheck.offsetStart)
  
  SetEntityCoords(playerPed, exitPosition, 1, 0, 0, 0)
  FreezeEntityPosition(playerPed, false)
  
  Citizen.Wait(10)
  SetPedToRagdoll(playerPed, 15000, 15000, 0, 0, 0, 0)
  Citizen.Wait(10)
  
  ApplyForceToEntity(playerPed, 1, 15.0, 0.0, 9.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
  
  Citizen.Wait(1000)
  SetEntityNoCollisionEntity(playerPed, activeVehicle, true)
  DoScreenFadeIn(5000)
  
  AfterExploded()
end

function AfterExploded()
  Citizen.CreateThread(function()
    local effectEndTime = GetGameTimer() + 30000
    
    AnimpostfxPlay("Dax_TripFreefallImpact", 30000, 0)
    ShakeGameplayCam("DRUNK_SHAKE", 1.0)
    
    while GetGameTimer() < effectEndTime do
      Citizen.Wait(500)
    end
    
    StopGameplayCamShaking(0)
    AnimpostfxStopAll()
  end)
end

function IsVanDoorAccessible(vehicle)
  local vehicleSettings = GetVehicleSettings(vehicle)
  local startPosition = GetOffsetFromEntityInWorldCoords(vehicle, vehicleSettings.spaceCheck.offsetStart)
  local endPosition = GetOffsetFromEntityInWorldCoords(vehicle, vehicleSettings.spaceCheck.offsetEnd)
  
  local raycast = StartShapeTestSweptSphere(startPosition, endPosition, 0.5, 4294967027, vehicle, 1)
  local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(raycast)
  
  if Config.debug then
    DrawSphere(endCoords, 0.2, 255, 0, 0, 1.0)
  end
  
  return not hit or hit == 0
end

local DisableControlAction = DisableControlAction

function DisableInputs()
  local controlsToDisable = {0, 14, 15, 16, 17, 21, 23, 140, 141, 261, 262, 263, 264}
  
  for _, control in pairs(controlsToDisable) do
    DisableControlAction(0, control, true)
  end
end

function ResetCookingCamera()
  RenderScriptCams(false, false, 0, true, false, false)
  DestroyCam(COOKING_CAMERA)
  COOKING_CAMERA = nil
end

function SetCookingCamera(vehicle)
  local camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 
    GetEntityCoords(vehicle), 
    GetEntityRotation(vehicle, 5), 
    60.0, 1, 5)
  
  COOKING_CAMERA = camera
  
  local vehicleSettings = GetVehicleSettings(vehicle)
  AttachCamToVehicleBone(camera, vehicle, 0, 1, 
    vehicleSettings.camera.rotation, 
    vehicleSettings.camera.offset, true)
  
  ShakeCinematicCam(camera, 1)
  ShakeCam(COOKING_CAMERA, "HAND_SHAKE", 0.2)
  
  SetCamActive(camera, true)
  RenderScriptCams(true, false, 0, true, false, false)
end

gasMaskEffectEndTime = 0

function MakePlayerHigh()
  if not Config.gasMask.enabled then
    return
  end
  
  local previousEndTime = gasMaskEffectEndTime
  gasMaskEffectEndTime = GetGameTimer() + 40000
  
  if previousEndTime >= GetGameTimer() then
    return
  end
  
  Citizen.Wait(5000)
  
  local effectType = Config.gasMask.effectType
  local effectName = "DRUG_gas_huffin"
  local maxStrength = 1.0
  local reductionMultiplier = 1.0
  
  if IsWearingAGasMask() then
    reductionMultiplier = Config.gasMask.maskReductionMultiplier
  end
  
  if effectType == "STONED" then
    effectName = "Barry1_Stoned"
    maxStrength = 1.2
  else
    effectName = "DRUG_gas_huffin"
    maxStrength = 0.3
  end
  
  ShakeCam(COOKING_CAMERA, "FAMILY5_DRUG_TRIP_SHAKE", 
    0.2 * reductionMultiplier * Config.gasMask.effectStrengthMultiplier)
  
  SetTimecycleModifier(effectName)
  
  local strength = 0
  while strength < 1 do
    strength = strength + 0.01
    SetTimecycleModifierStrength(strength * maxStrength * reductionMultiplier * Config.gasMask.effectStrengthMultiplier)
    Citizen.Wait(150)
  end
  
  while gasMaskEffectEndTime > GetGameTimer() do
    Citizen.Wait(500)
  end
  
  while strength > 0 do
    strength = strength - 0.01
    SetTimecycleModifierStrength(strength * maxStrength * reductionMultiplier * Config.gasMask.effectStrengthMultiplier)
    Citizen.Wait(100)
  end
  
  ShakeCam(COOKING_CAMERA, "HAND_SHAKE", 0.2)
  ClearTimecycleModifier()
end

function ClampCoordsToCounter(coords)
  local startOffset, endOffset = GetVanTableOffsets()
  
  local clampedOffset = vector3(
    math.clamp(coords.x, startOffset.x, endOffset.x),
    math.clamp(coords.y, startOffset.y, endOffset.y),
    startOffset.z
  )
  
  local worldCoords = GetOffsetFromEntityInWorldCoords(GetActiveVehicle(), clampedOffset)
  
  return clampedOffset, worldCoords
end

function HandleCursorStyle(isHovering, isHolding, isSpecial)
  SetMouseCursorSprite(2)
  
  if isHovering then
    if isHolding then
      SetMouseCursorSprite(4)
    else
      SetMouseCursorSprite(3)
    end
  elseif isSpecial then
    SetMouseCursorSprite(5)
  end
end

function GetCursorCoordinates(vehicle)
  local cursorX = GetDisabledControlNormal(0, 239)
  local cursorY = GetDisabledControlNormal(0, 240)
  
  return UseCache("GetCursorCoordinates" .. cursorX .. "-" .. cursorY, function()
    local screenWorldCoords, screenWorldNormal = GetWorldCoordFromScreenCoord(cursorX, cursorY)
    local mappedCoords = MapScreenCoordsToBounds(screenWorldCoords, screenWorldNormal, vehicle)
    return mappedCoords, cursorX, cursorY
  end, 500)
end

function MapScreenCoordsToBounds(worldCoords, worldNormal, vehicle)
  local tableOffset = GetVanTableOffsets()
  local depthMultiplier = 0.0
  local adjustedCoords = worldCoords + worldNormal * depthMultiplier
  local iterations = 250
  local difference = 1
  
  while difference > 0.05 and iterations > 0 do
    local entityOffset = GetOffsetFromEntityGivenWorldCoords(vehicle, adjustedCoords)
    local projectedZ = GetOffsetFromEntityInWorldCoords(vehicle, entityOffset.xy, tableOffset.z).z
    difference = math.abs(adjustedCoords.z - projectedZ)
    
    iterations = iterations - 1
    depthMultiplier = depthMultiplier + 0.02
    adjustedCoords = worldCoords + worldNormal * depthMultiplier
  end
  
  return GetOffsetFromEntityGivenWorldCoords(vehicle, adjustedCoords)
end

function DoPouringParticle(entity, position)
  Citizen.CreateThread(function()
    local assetName = "core"
    
    if not HasNamedPtfxAssetLoaded(assetName) then
      RequestNamedPtfxAsset(assetName)
      while not HasNamedPtfxAssetLoaded(assetName) do
        Citizen.Wait(1)
      end
    end
    
    SetPtfxAssetNextCall(assetName)
    local particle = StartParticleFxLoopedAtCoord("ent_sht_beer_barrel", position, 0.0, 0.0, 0.0, 0.1, 1.0, 1.0, 1.0, 0)
    SetParticleFxLoopedFarClipDist(particle, 300.0)
    
    while DoesEntityExist(entity) do
      Citizen.Wait(10)
    end
    
    StopParticleFxLooped(particle, 0)
    RemoveParticleFx(particle, true)
  end)
end

function Draw2DTextTimed(x, y, text, scale, duration)
  Draw2DText(x, y, text, scale)
end
