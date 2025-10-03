-- CriderGPT Helper Mod (Upgraded)
-- Author: Jessie Crider
-- Version: 1.1.0.0

CriderGPTHelper = {}
local CriderGPTHelper_mt = Class(CriderGPTHelper)

-- Default Economy Prices (Normal difficulty, vanilla FS22)
local ECONOMY = {
    limePricePer1000L = 350,
    solidFertPricePer1000L = 1820,
    liquidFertPricePerL   = 1.60
}

function CriderGPTHelper:new(customMt)
    local self = setmetatable({}, customMt or CriderGPTHelper_mt)
    self._autofeedTimer = 0
    print("CriderGPT Helper loaded — your AI farmhand is clocked in.")
    return self
end

-- HUD Notification System
function CriderGPTHelper:showNotification(message)
    if g_currentMission ~= nil then
        g_currentMission:addExtraPrintText("CriderGPT: " .. message)
    end
end

-- =========================
-- Auto-Drive (stub)
-- =========================
function CriderGPTHelper:autoDriveTo(x, z)
    -- Future hook: integrate Courseplay / AI Jobs here
    self:showNotification(string.format("Auto-driving to (%.1f, %.1f)…", x, z))
end

-- =========================
-- Precision Farming Support
-- =========================
local function isPFLoaded()
    return g_precisionFarming ~= nil or (g_currentMission and g_currentMission.precisionFarmingSystem ~= nil)
end

local function getFieldPH(field)
    if not isPFLoaded() then return nil end
    local pf = g_currentMission.precisionFarmingSystem
    if pf and pf.getFieldPH ~= nil then
        return pf:getFieldPH(field.fieldId)
    end
    return nil
end

local function getFieldNitrogenState(field)
    if not isPFLoaded() then return nil end
    local pf = g_currentMission.precisionFarmingSystem
    if pf and pf.getFieldNitrogenState ~= nil then
        return pf:getFieldNitrogenState(field.fieldId)
    end
    return nil
end

function CriderGPTHelper:estimateLimeCost(field, currentPH, targetPH)
    if not currentPH then return nil end
    local delta = math.max(0, targetPH - currentPH)
    if delta <= 0 then return {liters=0, cost=0} end

    local ha = field.totalFieldArea or 1
    local litersNeeded = delta * 1200 * ha
    local cost = (litersNeeded / 1000) * ECONOMY.limePricePer1000L
    return {liters = math.floor(litersNeeded), cost = math.floor(cost)}
end

function CriderGPTHelper:estimateNitrogenCost(field, nState, useLiquid)
    local ha = field.totalFieldArea or 1
    local factorByState = { RED = 1.0, YELLOW = 0.5, GREEN = 0.0 }
    local f = factorByState[nState or "RED"] or 1.0

    local litersPerHa = useLiquid and 180 or 200
    local litersNeeded = litersPerHa * f * ha
    local cost = useLiquid and (litersNeeded * ECONOMY.liquidFertPricePerL)
                           or ((litersNeeded / 1000) * ECONOMY.solidFertPricePer1000L)
    return {liters = math.floor(litersNeeded), cost = math.floor(cost)}
end

-- =========================
-- Auto-Feed System
-- =========================
local function isHusbandry(placeable)
    return placeable ~= nil and placeable.getName ~= nil and placeable.modules ~= nil
end

function CriderGPTHelper:autoFeedScanOnce()
    local ps = g_currentMission and g_currentMission.placeableSystem
    if ps == nil then return end

    for _, placeable in pairs(ps.placeables) do
        if isHusbandry(placeable) then
            for name, module in pairs(placeable.modules) do
                if module and module.getFillLevelPercentage ~= nil then
                    local pct = module:getFillLevelPercentage() * 100
                    if pct < 25 then
                        if module.addFood ~= nil then
                            local added = module:addFood(1000) -- try to add 1000L
                            if added > 0 then
                                self:showNotification(string.format(
                                    "Auto-fed %d L to %s (was below 25%%)",
                                    added, placeable:getName()))
                            end
                        else
                            self:showNotification(string.format(
                                "Feed low at %s (<25%%). Manual refill required.",
                                placeable:getName()))
                        end
                    end
                end
            end
        end
    end
end

-- =========================
-- Update Loop
-- =========================
function CriderGPTHelper:update(dt)
    -- Fuel Warning
    local vehicle = g_currentMission and g_currentMission.controlledVehicle
    if vehicle ~= nil and vehicle.getConsumerFillUnitFillLevel ~= nil then
        local fuelLevel = vehicle:getConsumerFillUnitFillLevel(FillType.DIESEL)
        if fuelLevel ~= nil and fuelLevel < 50 then
            self:showNotification("Fuel is running low! (" .. math.floor(fuelLevel) .. " L left)")
        end
    end

    -- Auto-feed scan every 20 seconds
    self._autofeedTimer = self._autofeedTimer + dt
    if self._autofeedTimer >= 20000 then
        self._autofeedTimer = 0
        self:autoFeedScanOnce()
    end
end

addModEventListener(CriderGPTHelper:new())
