local function StopDragging(resource)
    resource.Interact()
    resource.OnDraggingStopped()
end
OnDraggingStopped = StopDragging

function HandleDragging()
    local activeVehicle = GetActiveVehicle()
    local cursorX, cursorY, cursorZ = GetCursorCoordinates(activeVehicle)
    local clampedX, clampedY = ClampCoordsToCounter(cursorX)
    local draggedResource = DRAGGING_RESOURCE
    
    if not IS_DRAGGING then
        draggedResource = GetNearestResource(clampedY, true)
        DRAGGING_RESOURCE = draggedResource
    end
    
    local isDragging = false
    
    if draggedResource then
        if IsControlPressed(0, Config.keybinds.drag.input) or IsDisabledControlPressed(0, Config.keybinds.drag.input) then
            local rotation = draggedResource.rotation
            
            if draggedResource.type.rotatable then
                if IsControlPressed(0, Config.keybinds.rotateRight.input) then
                    rotation = rotation + vector3(0.0, 0.0, 10.0)
                end
                
                if IsControlPressed(0, Config.keybinds.rotateLeft.input) then
                    rotation = rotation + vector3(0.0, 0.0, -10.0)
                end
            end
            
            draggedResource.MoveTo(clampedX, rotation)
            isDragging = true
        end
    end
    
    if IS_DRAGGING and not isDragging then
        OnDraggingStopped(draggedResource)
        DRAGGING_RESOURCE = nil
    end
    
    IS_DRAGGING = isDragging
    return draggedResource, isDragging
end