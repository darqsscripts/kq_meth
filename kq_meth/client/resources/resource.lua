local resources = {}
RESOURCES = resources

function DeleteResources(refund)
  local refundItems = {}
  for _, resource in pairs(RESOURCES) do
    if resource ~= nil then
      local shouldDelete = not DoesEntityExist(resource.entity) or resource.inactive
    end
    resource.Delete()
  end
  RESOURCES = {}
  
  for _, entity in pairs(GetGamePool("CObject")) do
    if Entity(entity).state.kq_meth_resource or Entity(entity).state.kq_meth_resource_child then
      SetEntityAsMissionEntity(entity, 1, 1)
      DeleteEntity(entity)
    end
  end
  
end

function GetNearestResource(position, draggableOnly, excludeResource, deviceId)
  local cacheKey = ""
  if deviceId then
    cacheKey = "device_" .. deviceId
  end
  if excludeResource then
    cacheKey = cacheKey .. "-" .. excludeResource.id
  end
  
  return UseCache("GetNearestResource_" .. cacheKey, function()
    local nearestResource = nil
    local minDistance = 0.02
    
    for _, resource in pairs(RESOURCES) do
      if excludeResource and resource.id == excludeResource.id then
        goto continue
      end
      
      if not resource.inactive and DoesEntityExist(resource.entity) then
        if not draggableOnly or resource.type.draggable then
          local resourcePos = GetEntityCoords(resource.entity) - resource.type.offset.coords
          local distance = #(position - resourcePos) - resource.type.size
          
          if distance < minDistance then
            minDistance = distance
            nearestResource = resource
          end
        end
      end
      
      ::continue::
    end
    
    return nearestResource, minDistance
  end, 150)
end

function RegisterResource(vehicle, resourceType, spawnData)
  local typeConfig = Types[resourceType]
  if not typeConfig then
    error("Invalid resource type:" .. resourceType)
    return nil
  end
  
  Debug("Registering", resourceType)
  
  local resource = {}
  resource.id = GetGameTimer() .. resourceType .. "-" .. math.random(0, 9999)
  resource.type = Types[resourceType]
  resource.vehicle = vehicle
  resource.interactable = nil
  resource.inactive = false
  resource.spawnCoords = spawnData.coords
  resource.velocity = vector3(0, 0, 0)
  resource.coords = spawnData.coords
  resource.rotation = spawnData.rotation
  resource.entity = nil
  resource.children = {}
  resource.liquids = {}
  resource.beingUsed = false
  resource.temperature = 0
  resource.minTemp = 15
  resource.type.key = resourceType
  
  function resource.Setup()
    if resource.entity and DoesEntityExist(resource.entity) then
      DeleteEntity(resource.entity)
      resource.entity = nil
    end
    
    local model = resource.type.model
    DoRequestModel(model)
    resource.entity = CreateObject(model, GetOffsetFromEntityInWorldCoords(resource.vehicle, resource.coords), false, 1, 0)
    
    if resource.type.callback then
      resource.type.callback(resource.entity)
    end
    
    if resource.type.temperature then
      resource.minTemp = Types[resourceType].temperature.min or 15
    end
    
    Entity(resource.entity).state:set("kq_meth_resource", true)
    Entity(resource.entity).state:set("kq_meth_resource_vehicle", NetworkGetNetworkIdFromEntity(resource.vehicle))
    
    SetEntityAsMissionEntity(resource.entity, 1, 1)
    
    local vehicleCoords = CounterCoordsToVehicleCoords(resource.coords)
    resource.SetPosition(vehicleCoords, resource.rotation)
    resource.lastSafeCoords = vehicleCoords
    
    if resource.type.children then
      resource.CreateChildren()
    end
  end
  
  function resource.CreateChildren()
    for _, childConfig in pairs(resource.type.children) do
      local childModel = childConfig.model
      DoRequestModel(childModel)
      local childEntity = CreateObject(childModel, GetOffsetFromEntityInWorldCoords(resource.entity, childConfig.offset), false, 1, 0)
      AttachEntityToEntity(childEntity, resource.entity, 0, childConfig.offset, childConfig.rotation, 0, 1, 0, 0, 0, 1)
      Entity(resource.entity).state:set("kq_meth_resource_child", true)
      table.insert(resource.children, childEntity)
    end
  end
  
  function resource.SetPosition(newCoords, newRotation)
    resource.coords = newCoords
    resource.rotation = newRotation or resource.rotation
    
    if not resource.coords then
      return
    end
    
    if resource.type.alwaysFacePlayer and not resource.beingUsed then
      Citizen.Wait(1)
      local camOffset = GetOffsetFromEntityGivenWorldCoords(resource.vehicle, GetCamCoord(COOKING_CAMERA))
      camOffset = camOffset + vector3(0.5, 0, 0)
      local direction = resource.coords - camOffset
      local heading = GetHeadingFromVector_2d(direction.x, direction.y)
      resource.rotation = vector3(0, 0, heading)
    end
    
    if not IsEntityAttachedToEntity(resource.entity, resource.vehicle) then
      DetachEntity(resource.entity)
    end
    
    AttachEntityToEntity(resource.entity, resource.vehicle, 0, resource.coords + resource.type.offset.coords, 
                         resource.rotation + resource.type.offset.rotation, 0, 0, false, 0, 5, 1)
  end
  
  function resource.MoveTo(targetCoords, targetRotation)
    resource.beingDragged = true
    
    if targetCoords == nil or targetCoords.x == nil or targetCoords.x == 0.0 then
      return
    end
    
    if not resource or not resource.coords then
      Debug("set coords to " .. targetCoords)
      resource.coords = targetCoords
    end
    
    local distance = #(resource.coords - targetCoords)
    if distance < 0.002 and targetRotation == resource.rotation then
      return
    end
    
    local collides, collisionHeight, collisionAmount = resource.GetCollidesAnotherResource(targetCoords)
    
    if collides then
      targetCoords = vector3(targetCoords.xy, targetCoords.z + collisionHeight * collisionAmount)
    else
      if not resource.type.unplaceable then
        resource.lastSafeCoords = targetCoords
      end
    end
    
    local previousPos = GetEntityCoords(resource.entity)
    resource.SetPosition(targetCoords, targetRotation)
    
    if resource.type.liquid and resource.type.liquid.shuffles then
      SetTimeout(200, function()
        if not resource then return end
        local currentPos = GetEntityCoords(resource.entity)
        resource.velocity = resource.velocity + (previousPos - currentPos)
      end)
    end
  end
  
  function resource.OnDraggingStopped()
    if not resource then return end
    resource.beingDragged = false
    resource.SetPosition(resource.lastSafeCoords)
  end
  
  function resource.Interact()
    if resource.inactive or (resource.interactable and resource.beingUsed) then
      return
    end
    
    if not resource.interactable then
      return
    end
    
    Debug("I " .. resource.id .. " should interact with " .. resource.interactable.id)
    
    local transferred = false
    resource.beingUsed = true
    
    if resource.CanInteractWith(resource.interactable) then
      resource.interactable.interactingWith = true
      resource.AnimateInteraction()
      
      local particles = resource.type.interaction.particles
      if particles then
        Citizen.SetTimeout(particles.delay or 0, function()
          resource.interactable.CreateParticles(particles.effect, particles.scale, 
                                               vector3(0, 0, 0.1), particles.duration)
        end)
      end
      
      for _, liquid in pairs(resource.liquids) do
        if not resource then return end
        
        local remainingAmount = liquid.amount
        while resource and remainingAmount > 0 do
          if not resource then return end
          
          local transferAmount = math.min(remainingAmount, resource.type.interaction.speed)
          remainingAmount = remainingAmount - transferAmount
          resource.interactable.AddLiquid(liquid.name, transferAmount)
          Citizen.Wait(1)
        end
        transferred = true
      end
    end
    
    resource.beingUsed = false
    resource.interactable.interactingWith = false
    
    if transferred then
      resource.FadeOutDelete()
    end
    
    return transferred
  end
  
  function resource.CanInteractWith(target)
    local canInteract = resource.type.interaction and resource.type.interaction.canPourOut
    
    if not canInteract then
      return false
    end
    
    resource.GetFillLevel()
    
    canInteract = target.type.interaction.storesLiquids or 
                 (target.type.interaction.storesLiquids and 
                  resource.GetFillLevel() + target.GetFillLevel() > 0 and 
                  not target.inactive)
    
    if not canInteract then
      return false
    end
    
    if target.type.interaction and target.type.interaction.interactsWith then
      canInteract = Contains(target.type.interaction.interactsWith, resource.type.key)
    end
    
    return canInteract
  end
  
  function resource.AnimateInteraction()
    local animationType = resource.type.interaction.animation
    
    if animationType == "drop" then
      DetachEntity(resource.entity, 1, 1)
      SetEntityCollision(resource.entity, 0, 1)
      ActivatePhysics(resource.entity)
    elseif animationType == "pour" then
      local targetTop = vector3(0.0, 0.0, resource.interactable.type.height + 0.05)
      local targetPosition = resource.interactable.coords + targetTop
      resource.SetPosition(targetPosition + resource.type.interaction.offset, vector3(120.0, 0.0, 0.0), true)
      
      local pourTarget = GetOffsetFromEntityInWorldCoords(resource.interactable.entity, 
                                                          vector3(0, 0, resource.interactable.type.height + 0.05))
      DoPouringParticle(resource.entity, pourTarget)
    end
  end
  
  function resource.GetCollidesAnotherResource(checkCoords)
    for _, otherResource in pairs(RESOURCES) do
      if otherResource.coords then
        local distance = #(otherResource.coords - checkCoords)
        
        if not otherResource.inactive and not otherResource.type.ignore and otherResource.id ~= resource.id then
          local combinedSize = (otherResource.type.size / 2) + (resource.type.size / 2) + 0.035
          
          if distance < combinedSize then
            if not Contains(resource.type.ignores or {}, otherResource.type.key) then
              local collides = true
              local collisionHeight = otherResource.type.height
              local overlapDistance = math.max(0, (otherResource.type.size + resource.type.size) / 2 - 0.015 - distance)
              local collisionAmount = 1 - (overlapDistance / 0.05)
              return collides, collisionHeight, collisionAmount
            end
          end
        end
      end
    end
  end
  
  function resource.GeneralThread()
    Citizen.CreateThread(function()
      while resource do
        if resource.type.liquid then
          if resource.GetLiquidsCount() > 0 then
            resource.PerformLiquidReactions()
            
            if resource.temperature > resource.minTemp then
              resource.temperature = resource.temperature - 0.15
              local velocityEffect = math.min(0.4, #resource.velocity) * 0.4
              resource.temperature = resource.temperature - velocityEffect
            end
          end
        end
        Citizen.Wait(100)
      end
    end)
  end
  
  function resource.SlowThread()
    Citizen.CreateThread(function()
      while resource do
        if resource.type.liquid then
          if resource.GetLiquidsCount() > 0 then
            if resource.temperature > Config.recipe.cookingTemperature - 3 then
              resource.CreateParticles("proj_grenade_smoke", 0.75, vector3(0, 0, 0.1), 2000)
              resource.CreateParticles("ent_amb_acid_bath", 0.01, vector3(0, 0, 0.1), 2000)
            end
            resource.CreateParticles("exp_grd_grenade_smoke", 0.01, vector3(0, 0, 0.1), 2000, 1.0)
          end
        end
        Citizen.Wait(2000)
      end
    end)
  end
  
  function resource.LiquidThread()
    if not resource.type.liquid or resource.liquidThreadRunning or resource.inactive then
      return
    end
    
    Citizen.CreateThread(function()
      resource.liquidThreadRunning = true
      
      while resource and resource.type.liquid and resource.GetLiquidsCount() > 0 do
        local rotation = vector3(0, 0, 0)
        
        if resource.type.liquid.shuffles then
          resource.velocity = resource.velocity * 0.96
          local velocityEffect = resource.velocity * (50 * resource.type.liquid.sizeX)
          local shuffleMultiplier = math.min(5, (resource.type.shufflingEfficiency or 0) * 10)
          rotation = velocityEffect * shuffleMultiplier
        end
        
        if resource.type.spinWithShuffle then
          resource.rotation = resource.rotation + vector3(0.0, 0.0, #resource.velocity * 2)
        end
        
        local fillColor = resource.GetFillColor()
        local fillLevel = resource.GetFillLevel() / resource.type.liquid.maxVolume
        local liquidHeight = resource.type.liquid.coords.max * fillLevel + resource.type.liquid.coords.min
        local liquidWorldPos = GetOffsetFromEntityInWorldCoords(resource.entity, liquidHeight)
        
        if not resource.beingUsed then
          if resource.type.liquid.usePoly then
            local corner1 = GetOffsetFromEntityInWorldCoords(resource.entity, 
              vector3(resource.type.liquid.sizeX / 2, resource.type.liquid.sizeY / 2, liquidHeight.z))
            local corner2 = GetOffsetFromEntityInWorldCoords(resource.entity, 
              vector3(-resource.type.liquid.sizeX / 2, resource.type.liquid.sizeY / 2, liquidHeight.z))
            local corner3 = GetOffsetFromEntityInWorldCoords(resource.entity, 
              vector3(resource.type.liquid.sizeX / 2, -resource.type.liquid.sizeY / 2, liquidHeight.z))
            local corner4 = GetOffsetFromEntityInWorldCoords(resource.entity, 
              vector3(-resource.type.liquid.sizeX / 2, -resource.type.liquid.sizeY / 2, liquidHeight.z))
            
            DrawPoly(corner1, corner2, corner3, fillColor[1], fillColor[2], fillColor[3], fillColor[4])
            DrawPoly(corner3, corner2, corner4, fillColor[1], fillColor[2], fillColor[3], fillColor[4])
          else
            DrawMarker(resource.type.liquid.marker, liquidWorldPos, vector3(0.0, 0.0, 0.0), rotation,
                      vector3(resource.type.liquid.sizeX, resource.type.liquid.sizeY, 0.001),
                      fillColor[1], fillColor[2], fillColor[3], fillColor[4], 0, 0, 2, 0, 0, 0, 0)
          end
        end
        
        resource.DrawLiquidInformation()
        resource.DebugLiquids()
        Citizen.Wait(1)
      end
      
      if not resource then return end
      resource.liquidThreadRunning = false
    end)
  end
  
  function resource.PerformLiquidReactions()
    if resource.beingUsed or resource.inactive then
      return
    end
    
    Citizen.CreateThread(function()
      for _, reaction in pairs(Reactions) do
        if not resource or not resource.type then return end
        
        if not reaction.count then
          reaction.count = -1
        end
        reaction.count = reaction.count + 1
        
        local shouldReact = true
        
        if reaction.shuffling then
          if reaction.shuffling.min > #resource.velocity then
            shouldReact = false
          end
          if reaction.shuffling.max < #resource.velocity then
            shouldReact = false
          end
          local efficiency = (resource.type.shufflingEfficiency or 0) * 100
          if efficiency < math.random(0, 100) then
            shouldReact = false
          end
        end
        
        if reaction.chance then
          if reaction.chance < math.random(0, 100) then
            shouldReact = false
          end
        end
        
        if reaction.temperature then
          if reaction.temperature.min and reaction.temperature.min > resource.temperature then
            shouldReact = false
          end
          if reaction.temperature.max and reaction.temperature.max < resource.temperature then
            shouldReact = false
          end
        end
        
        if reaction.input then
          for _, inputLiquid in pairs(reaction.input) do
            local liquid = resource.liquids[inputLiquid.liquid]
            if not liquid or liquid.amount < inputLiquid.amount then
              shouldReact = false
            end
          end
        end
        
        if reaction.without then
          for _, withoutLiquid in pairs(reaction.without) do
            local liquid = resource.liquids[withoutLiquid.liquid]
            if liquid and liquid.amount >= withoutLiquid.amount then
              shouldReact = false
            end
          end
        end
        
        if shouldReact then
          if reaction.input then
            for _, inputLiquid in pairs(reaction.input) do
              resource.AddLiquid(inputLiquid.liquid, -inputLiquid.amount)
            end
          end
          
          if reaction.output then
            resource.AddLiquid(reaction.output.liquid, reaction.output.amount)
          end
          
          if reaction.particles then
            for _, particle in pairs(reaction.particles) do
              if not particle.every or reaction.count % particle.every == 0 then
                local offset = particle.offset or vector3(0, 0, 0.1)
                
                if offset == "random" then
                  local range = math.floor(resource.type.size * 1000) / 2
                  offset = vector3(
                    math.random(-range, range) / 1000,
                    math.random(-range, range) / 1000,
                    math.random(0.0, math.floor(resource.type.height * 500)) / 1000
                  )
                end
                
                resource.CreateParticles(particle.name, particle.size, offset, 
                                       particle.duration or 120, particle.alpha)
              end
            end
          end
          
          if reaction.temperature and reaction.temperature.change then
            resource.temperature = resource.temperature + reaction.temperature.change
          end
          
          if reaction.explosion then
            resource.Explode()
          end
          
          if reaction.smoke then
            CreateMethSmoke(resource.vehicle)
            if serverTimeCheckDone == 0 then
              serverTimeCheck = serverTimeCheck * 2
              serverTimeCheckDone = 1
            end
            MakePlayerHigh()
          end
        end
      end
    end)
  end
  
  function resource.DebugLiquids()
    if not Config.debug then return end
    if not DoesEntityExist(resource.entity) then return end
    
    local lineCount = 0
    local success, screenX, screenY = UseCache("screenEntityCoords" .. resource.entity, function()
      return GetScreenCoordFromWorldCoord(table.unpack(GetEntityCoords(resource.entity)))
    end, 100)
    
    for _, liquid in pairs(resource.liquids) do
      lineCount = lineCount + 1
      Draw2DText(screenX, screenY + 0.03 + (0.013 * lineCount), liquid.name .. ": " .. liquid.amount, 0.3)
    end
    
    resource.GetFillColor()
  end
  
  function resource.DrawLiquidInformation()
    if resource.inactive then return end
    
    local success, screenX, screenY = UseCache("screenEntityCoords" .. resource.entity, function()
      return GetScreenCoordFromWorldCoord(table.unpack(GetEntityCoords(resource.entity)))
    end, 100)
    
    local tempUnit = L("c")
    if Config.units.temperature == "f" then
      tempUnit = L("f")
    end
    
    local displayTemp = UseCache("smoothTemperature", function()
      local temp = math.floor(resource.temperature)
      if Config.units.temperature == "f" then
        tempUnit = "f"
        temp = temp * 9 / 5 + 32
      end
      return temp
    end, 500)
    
    if resource.type.info.drawTemp and not resource.beingUsed then
      local tempDisplayPos = GetOffsetFromEntityInWorldCoords(resource.children[1], vector3(0.0, 0.005, 0.18))
      local tempSuccess, tempScreenX, tempScreenY = UseCache("screenEntityCoords" .. resource.coords.x .. "-" .. resource.coords.y, function()
        return GetScreenCoordFromWorldCoord(table.unpack(tempDisplayPos))
      end, 10)
      
      local tempText = L("{temp}°{unit}"):gsub("{temp}", displayTemp):gsub("{unit}", tempUnit)
      DrawDisplayText(tempScreenX, tempScreenY, tempDisplayPos, tempText)
    end
    
    local methPurity = resource.GetLiquidsPurity({"liquid_meth", "meth"})
    
    if not resource.beingUsed then
      if resource.type.info.drawPurityRaw and methPurity <= 0 then
        local rawPurity = resource.GetLiquidsPurity({"cooked_ace_lith"})
        if rawPurity > 0 then
          local purityText = L("~b~Meth mixture purity: {percentage}%"):gsub("{percentage}", rawPurity)
          Draw2DText(screenX, screenY - 0.015, purityText, 0.3)
        end
      end
      
      if resource.type.info.drawPurity and methPurity > 0 then
        local purityText = L("~b~Meth purity: {percentage}%"):gsub("{percentage}", methPurity)
        Draw2DText(screenX, screenY - 0.015, purityText, 0.3)
      end
      
      if resource.type.info.drawCooling then
        if resource.liquids.meth and resource.liquids.liquid_meth then
          local liquidAmount = resource.liquids.liquid_meth.amount
          local crystalAmount = resource.liquids.meth.amount
          local coolingText = L("~b~Meth crystallizing: {percentage}%"):gsub("{percentage}", 
            math.floor(crystalAmount / (crystalAmount + liquidAmount) * 100))
          Draw2DText(screenX, screenY, coolingText, 0.3)
        end
      end
    end
  end
  
  function resource.GetLiquidsPurity(liquidNames)
    local targetAmount = 0
    for _, liquidName in pairs(liquidNames) do
      if resource.liquids[liquidName] then
        targetAmount = targetAmount + resource.liquids[liquidName].amount
      end
    end
    
    local totalAmount = 0
    for _, liquid in pairs(resource.liquids) do
      totalAmount = totalAmount + liquid.amount
    end
    
    return math.floor((targetAmount / totalAmount) * 1000) / 10
  end
  
  function resource.SetLiquid(liquidName, amount)
    resource.liquids = {}
    if liquidName == nil then return end
    resource.AddLiquid(liquidName, amount)
  end
  
  function resource.AddLiquid(liquidName, amount)
    if not resource then return end
    
    Debug("Add liquid to", resource.id, liquidName, amount)
    
    if resource.liquids[liquidName] then
      local newAmount = resource.liquids[liquidName].amount + amount
      resource.liquids[liquidName].amount = newAmount
      
      if newAmount < 0 then
        resource.liquids[liquidName] = nil
      end
    else
      resource.liquids[liquidName] = {
        name = liquidName,
        type = Liquids[liquidName],
        amount = amount
      }
    end
    
    if amount > 0 then
      local liquidConfig = Liquids[liquidName]
      if liquidConfig.baseTemperature then
        local baseTemp = liquidConfig.baseTemperature
        local currentFillLevel = resource.GetFillLevel() - amount
        resource.temperature = (resource.temperature * currentFillLevel + baseTemp * amount) / resource.GetFillLevel()
      end
    end
    
    resource.LiquidThread()
  end
  
  function resource.GetFillLevel()
    local total = 0
    for _, liquid in pairs(resource.liquids) do
      total = total + liquid.amount
    end
    return total
  end
  
  function resource.GetFillColor()
    local color = {0, 0, 0, 0}
    local sampleCount = 0
    
    for _, liquid in pairs(resource.liquids) do
      for i = 1, math.ceil(liquid.amount / 20) do
        sampleCount = sampleCount + 1
        color[1] = color[1] + liquid.type.color[1]
        color[2] = color[2] + liquid.type.color[2]
        color[3] = color[3] + liquid.type.color[3]
        color[4] = color[4] + liquid.type.color[4]
      end
    end
    
    local fillLevel = resource.GetFillLevel() / resource.type.liquid.maxVolume
    return {
      math.floor(color[1] / sampleCount),
      math.floor(color[2] / sampleCount),
      math.floor(color[3] / sampleCount),
      math.floor(color[4] / sampleCount + fillLevel * 20)
    }
  end
  
  function resource.GetLiquidsCount()
    if not resource then return end
    
    local count = 0
    for _, liquid in pairs(resource.liquids) do
      count = count + 1
    end
    return count
  end
  
  function resource.CreateParticles(particleName, scale, offset, duration, alpha, networked)
    Citizen.CreateThread(function()
      local assetName = "core"
      
      if not HasNamedPtfxAssetLoaded(assetName) then
        RequestNamedPtfxAsset(assetName)
        while not HasNamedPtfxAssetLoaded(assetName) do
          Citizen.Wait(1)
        end
      end
      
      if not resource then return end
      
      local particleHandle
      
      if networked then
        SetPtfxAssetNextCall(assetName)
        particleHandle = StartNetworkedParticleFxLoopedOnEntity(particleName, resource.entity, offset, 
                                                                0.0, 0.0, 0.0, scale, 0, 0, 0)
      else
        SetPtfxAssetNextCall(assetName)
        particleHandle = StartParticleFxLoopedOnEntity(particleName, resource.entity, offset, 
                                                       0.0, 0.0, 0.0, scale, 0, 0, 0)
      end
      
      SetParticleFxLoopedAlpha(particleHandle, alpha or 1.0)
      SetParticleFxLoopedColour(particleHandle, 1.0, 1.0, 0.0, 0)
      
      Citizen.Wait(duration)
      
      StopParticleFxLooped(particleHandle, 0)
      RemoveParticleFx(particleHandle, true)
    end)
  end
  
  function resource.Explode()
    if not Config.explosion.enabled then return end
    
    AddExplosion(GetEntityCoords(resource.entity) + vector3(0.0, 0.0, 0.0), 0, 3.5, 1, 0, 1065353216, 
                not Config.explosion.dealsDamage)
    resource.Delete()
    OnResourceExploded()
  end
  
  function resource.FadeOutDelete()
    if not resource then return end
    
    local alpha = 255
    local entity = resource.entity
    resource.DeleteChildren()
    resource = nil
    
    Citizen.CreateThread(function()
      while alpha > 5 do
        alpha = alpha - 5
        SetEntityAlpha(entity, alpha)
        Citizen.Wait(1)
      end
      DeleteEntity(entity)
    end)
  end
  
  function resource.SetInactive()
    if not resource then return end
    resource.DeleteChildren()
    DeleteEntity(resource.entity)
    resource.inactive = true
    return true
  end
  
  function resource.Delete()
    if not resource then return end
    resource.DeleteChildren()
    DeleteEntity(resource.entity)
    resource = nil
    return true
  end
  
  function resource.DeleteChildren()
    for _, child in pairs(resource.children or {}) do
      DeleteEntity(child)
    end
    return true
  end
  
  function resource.SetTemperature(temp)
    resource.temperature = temp
  end
  
  function resource.GetTemperature()
    return resource.temperature
  end
  
  resource.LiquidThread()
  resource.GeneralThread()
  resource.SlowThread()
  
  table.insert(RESOURCES, resource)
  resource.Setup()
  
  Debug("Finished", resourceType)
  return resource
end