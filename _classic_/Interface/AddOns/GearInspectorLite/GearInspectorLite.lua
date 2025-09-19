
local function UpdatePlayerCharacterScreen()
    GearInspectorLite_UpdatePlayerEmptySocketIcons()
    GearInspectorLite_UpdatePlayerItemLevelDisplay()
    GearInspectorLite_UpdatePlayerEnchantDisplay()

end

local function UpdateInspectCharacterScreen(inspectUnitToken)
    GearInspectorLite_UpdateInspectEmptySocketIcons(inspectUnitToken)
    GearInspectorLite_UpdateInspectEnchantDisplay(inspectUnitToken)
    GearInspectorLite_UpdateInspectItemLevelDisplay(inspectUnitToken)
    

end

local playerFrame = CreateFrame("Frame")
playerFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
playerFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
    UpdatePlayerCharacterScreen()
end)

CharacterFrame:HookScript("OnShow", function()
    UpdatePlayerCharacterScreen()
end)

local inspectUnit = nil

local inspectFrame = CreateFrame("Frame")
inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "INSPECT_READY" and unit == inspectUnit then
        --print ("Inspecting")
        GearInspectorLite_UpdateInspectEmptySocketIcons(inspectUnit)
    end
end)

local inspectUnitToken = nil
local inspectGUID = nil
local lastInspectUpdate = 0
local INSPECT_UPDATE_COOLDOWN = 1.0  -- seconds

local function HookInspectFrame()
    local inspectFrame = _G["InspectFrame"]
    if not inspectFrame then
        --print("InspectFrame not loaded yet.")
        return
    end

    inspectFrame:HookScript("OnShow", function()
        inspectUnitToken = "target"  -- store inspected unit token once
        if UnitExists(inspectUnitToken) then
            inspectGUID = UnitGUID(inspectUnitToken)
            NotifyInspect(inspectUnitToken)
        else
            inspectGUID = nil
        end
        --print("Inspection hook triggered, inspectUnitToken set to:", inspectUnitToken, "GUID:", inspectGUID)
    end)

    inspectFrame:HookScript("OnHide", function()
        inspectUnitToken = nil
        inspectGUID = nil
        lastInspectUpdate = 0
        --print("Inspect frame closed, cleared inspectUnitToken and inspectGUID")
        -- Optionally clear overlays here if needed
    end)
end

if IsAddOnLoaded("Blizzard_InspectUI") then
    HookInspectFrame()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_InspectUI" then
            HookInspectFrame()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

if IsAddOnLoaded("Blizzard_InspectUI") then
    HookInspectFrame()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Blizzard_InspectUI" then
            HookInspectFrame()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

local fInspectReady = CreateFrame("Frame")
fInspectReady:RegisterEvent("INSPECT_READY")

fInspectReady:SetScript("OnEvent", function(_, event, unitGUID)
    if not inspectGUID then return end
    if unitGUID == inspectGUID then
        local now = GetTime()
        if now - lastInspectUpdate > INSPECT_UPDATE_COOLDOWN then
            lastInspectUpdate = now
            -- Delay update by 0.5 seconds to ensure inspect data is fully loaded
            C_Timer.After(0.5, function()
                UpdateInspectCharacterScreen(inspectUnitToken)
            end)
        end
    end
end)
