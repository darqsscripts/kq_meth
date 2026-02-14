function HandleInteraction(resource, enableInteraction)
  local vehicle, cursorX, cursorY, cursorZ, clampedX, clampedY
  if resource then
    vehicle = GetActiveVehicle()
    cursorX, cursorY, cursorZ, clampedX, clampedY = UseCache("cursorInteraction", function()
      local x, y, z = GetCursorCoordinates(vehicle)
      local cX, cY = ClampCoordsToCounter(x)
      return x, y, z, cX, cY
    end, 10)
    
    local drewInteractionLabel = false
    if enableInteraction then
      local nearestResource = GetNearestResource(clampedY, false, resource)
      if nearestResource then
        local resourceInteraction = nearestResource.type.interaction
        if resourceInteraction then
          resource.interactable = nearestResource
          nearestResource.interactable = resource
          local interaction = FindInteraction(resource, nearestResource)
          if interaction then
            Draw2DTextTimed(clampedX - 0.0015 * #interaction.label, clampedY - 0.03, interaction.label, 0.3, 30)
            drewInteractionLabel = true
          end
        end
      else
        local currentInteractable = resource.interactable
        if currentInteractable then
          resource.interactable = nil
        end
      end
    end
    
    if not drewInteractionLabel then
      local shouldDrawLabel = Config.display.drawResourceLabelOnHover
      if shouldDrawLabel then
        Draw2DTextTimed(clampedX - 0.0015 * #resource.type.label, clampedY - 0.03, resource.type.label, 0.3, 30)
      end
    end
  end
end

function FindInteraction(sourceResource, targetResource)
  local cacheKey = "FindInteraction_" .. sourceResource.id .. "_" .. targetResource.id
  return UseCache(cacheKey, function()
    local canInteract = sourceResource.CanInteractWith(targetResource)
    if canInteract then
      local sourceFillLevel = sourceResource.GetFillLevel()
      local targetFillLevel = targetResource.GetFillLevel()
      local totalFillLevel = sourceFillLevel + targetFillLevel
      local maxVolume = targetResource.type.liquid.maxVolume
      if totalFillLevel <= maxVolume then
        local interaction = {}
        local labelText = L("🧪 Pour {A} into the {B}")
        labelText = labelText:gsub("{A}", sourceResource.type.label)
        labelText = labelText:gsub("{B}", targetResource.type.label)
        interaction.label = labelText
        return interaction
      else
        local interaction = {}
        local labelText = L("~r~The {A} is too full")
        labelText = labelText:gsub("{A}", targetResource.type.label)
        interaction.label = labelText
        return interaction
      end
    end
    return nil
  end, 500)
end