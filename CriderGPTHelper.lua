-- CriderGPT Helper Mod
-- Author: Jessie Crider
-- Version: 1.0.0.0

CriderGPTHelper = {}
local CriderGPTHelper_mt = Class(CriderGPTHelper)

function CriderGPTHelper:new(customMt)
    local self = setmetatable({}, customMt or CriderGPTHelper_mt)
    print("CriderGPT Helper loaded - your AI farmhand is ready.")
    return self
end

-- HUD Notification System
function CriderGPTHelper:showNotification(message)
    g_currentMission:addExtraPrintText("CriderGPT: " .. message)
end

-- Placeholder Auto-Drive
function CriderGPTHelper:autoDriveTo(x, z)
    self:showNotification("Auto-driving to location ("..x..","..z..")")
    -- TODO: Navmesh/pathfinding
end

-- Placeholder Auto-Feed
function CriderGPTHelper:autoFeedBarn(barnId)
    self:showNotification("Feeding animals at barn ID: "..barnId)
    -- TODO: Deduct feed, update barn fill levels
end

function CriderGPTHelper:update(dt)
    local vehicle = g_currentMission.controlledVehicle
    if vehicle ~= nil then
        local fuelLevel = vehicle:getConsumerFillUnitFillLevel(FillType.DIESEL)
        if fuelLevel ~= nil and fuelLevel < 50 then
            self:showNotification("Fuel is running low! (" .. math.floor(fuelLevel) .. "L left)")
        end
    end
end

addModEventListener(CriderGPTHelper:new())
