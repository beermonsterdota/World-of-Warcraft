-- DisplayItemLevel.lua

GearInspectorLite = GearInspectorLite or {}

local MAX_RETRIES = 5
local RETRY_DELAY = 0.2

local slotIds = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}

local ilvlTextConfig = {
    default = {
        point = "LEFT",
        relativePoint = "RIGHT",
        xOffset = 8,
        yOffset = 0,
    },
    rightSide = {
        point = "RIGHT",
        relativePoint = "LEFT",
        xOffset = -10,
        yOffset = 0,
    },
    above = {
        point = "BOTTOM",
        relativePoint = "TOP",
        xOffset = 0,
        yOffset = 6,
    },
}

local function GetFlatIlvlColor(ilvl, minIlvl, maxIlvl)
    if maxIlvl == minIlvl then
        return 0, 1, 0 -- all green if same
    elseif ilvl == maxIlvl then
        return 0, 1, 0
    elseif ilvl == minIlvl then
        return 1, 0, 0
    else
        return 1, 0.75, 0 -- amber
    end
end

local function DeterminePositionConfig(slotName)
    if slotName == "MainHandSlot" or slotName == "SecondaryHandSlot" then
        return ilvlTextConfig.above
    end

    local leftSlots = {
        HeadSlot = true, NeckSlot = true, ShoulderSlot = true, BackSlot = true, ChestSlot = true,
        ShirtSlot = true, TabardSlot = true, WristSlot = true,
    }

    if leftSlots[slotName] then
        return ilvlTextConfig.default
    else
        return ilvlTextConfig.rightSide
    end
end

local inspectAvgIlvlText  -- file-level cached FontString

local function CalculateAndPrintInspectAverageItemLevel(inspectUnit)
    if not inspectUnit or not UnitExists(inspectUnit) then return end

    local sumIlvl = 0
    local count = 0

    local offhandLink = GetInventoryItemLink(inspectUnit, GetInventorySlotInfo("SecondaryHandSlot"))

    for _, slotName in ipairs(slotIds) do
        local slotId = GetInventorySlotInfo(slotName)
        local link = GetInventoryItemLink(inspectUnit, slotId)
        local ilvl = link and select(4, GetItemInfo(link))

        if ilvl and ilvl > 0 then
            if slotName == "MainHandSlot" and not offhandLink then
                sumIlvl = sumIlvl + ilvl * 2
                count = count + 2
            elseif slotName ~= "SecondaryHandSlot" then
                sumIlvl = sumIlvl + ilvl
                count = count + 1
            end
        end
    end

    if count == 0 then return end

    local avgIlvl = math.floor(sumIlvl / count)

    if not inspectAvgIlvlText then
        local inspectFrame = _G["InspectPaperDollFrame"]
        local levelClassText = _G["InspectLevelText"]

        inspectAvgIlvlText = inspectFrame:CreateFontString(nil, "OVERLAY")
        inspectAvgIlvlText:SetFont(STANDARD_TEXT_FONT, 8)
        inspectAvgIlvlText:SetTextColor(1, 0.82, 0)

    if levelClassText then
        inspectAvgIlvlText:SetPoint("TOP", levelClassText, "BOTTOM", 0, 0)
    else
        inspectAvgIlvlText:SetPoint("TOP", inspectFrame, "TOP", 0, -75)
    end

    end

    inspectAvgIlvlText:SetText("Average Item Level: " .. avgIlvl)
    inspectAvgIlvlText:Show()
end



-- Retry counters
local playerRetryCount = 0
local inspectRetryCount = {}

-- Player item level display
function GearInspectorLite_UpdatePlayerItemLevelDisplay()
    local ilvlTexts = GearInspectorLite.playerIlvlTexts or {}
    GearInspectorLite.playerIlvlTexts = ilvlTexts

    local minIlvl, maxIlvl = math.huge, 0
    local foundValidIlvl = false

    for _, slotName in ipairs(slotIds) do
        local slotId = GetInventorySlotInfo(slotName)
        local link = GetInventoryItemLink("player", slotId)
        local ilvl = link and select(4, GetItemInfo(link))

        if ilvl and ilvl > 0 then
            foundValidIlvl = true
            if ilvl < minIlvl then minIlvl = ilvl end
            if ilvl > maxIlvl then maxIlvl = ilvl end
        end
    end

    if not foundValidIlvl then
        if playerRetryCount < MAX_RETRIES then
            playerRetryCount = playerRetryCount + 1
            C_Timer.After(RETRY_DELAY, GearInspectorLite_UpdatePlayerItemLevelDisplay)
            return
        else
            playerRetryCount = 0
        end
    else
        playerRetryCount = 0
    end

    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Character" .. slotName]
        if slotFrame then
            local slotId = GetInventorySlotInfo(slotName)
            local link = GetInventoryItemLink("player", slotId)
            local ilvl = link and select(4, GetItemInfo(link))

            local text = ilvlTexts[slotName]
            if not text then
                text = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                local cfg = DeterminePositionConfig(slotName)
                text:SetPoint(cfg.point, slotFrame, cfg.relativePoint, cfg.xOffset, cfg.yOffset)
                ilvlTexts[slotName] = text
            end

            if ilvl and ilvl > 0 then
                local r, g, b = GetFlatIlvlColor(ilvl, minIlvl, maxIlvl)
                text:SetText(ilvl)
                text:SetTextColor(r, g, b)
                text:Show()
            else
                text:Hide()
            end
        end
    end
end

-- Inspect item level display
function GearInspectorLite_UpdateInspectItemLevelDisplay(inspectUnit)
    if not inspectUnit or not UnitExists(inspectUnit) then return end

    local guid = UnitGUID(inspectUnit)
    if not guid then return end

    inspectRetryCount[guid] = inspectRetryCount[guid] or 0

    local ilvlTexts = GearInspectorLite.inspectIlvlTexts or {}
    GearInspectorLite.inspectIlvlTexts = ilvlTexts

    local minIlvl, maxIlvl = math.huge, 0
    local foundValidIlvl = false

    for _, slotName in ipairs(slotIds) do
        local slotId = GetInventorySlotInfo(slotName)
        local link = GetInventoryItemLink(inspectUnit, slotId)
        local ilvl = link and select(4, GetItemInfo(link))

        if ilvl and ilvl > 0 then
            foundValidIlvl = true
            if ilvl < minIlvl then minIlvl = ilvl end
            if ilvl > maxIlvl then maxIlvl = ilvl end
        end
    end

    if not foundValidIlvl then
        if inspectRetryCount[guid] < MAX_RETRIES then
            inspectRetryCount[guid] = inspectRetryCount[guid] + 1
            C_Timer.After(RETRY_DELAY, function()
                GearInspectorLite_UpdateInspectItemLevelDisplay(inspectUnit)
            end)
            return
        else
            inspectRetryCount[guid] = 0
        end
    else
        inspectRetryCount[guid] = 0
    end

    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Inspect" .. slotName]
        if slotFrame then
            local slotId = GetInventorySlotInfo(slotName)
            local link = GetInventoryItemLink(inspectUnit, slotId)
            local ilvl = link and select(4, GetItemInfo(link))

            local text = ilvlTexts[slotName]
            if not text then
                text = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                local cfg = DeterminePositionConfig(slotName)
                text:SetPoint(cfg.point, slotFrame, cfg.relativePoint, cfg.xOffset, cfg.yOffset)
                ilvlTexts[slotName] = text
            end

            if ilvl and ilvl > 0 then
                local r, g, b = GetFlatIlvlColor(ilvl, minIlvl, maxIlvl)
                text:SetText(ilvl)
                text:SetTextColor(r, g, b)
                text:Show()
            else
                text:Hide()
            end
        end
    end
    CalculateAndPrintInspectAverageItemLevel(inspectUnit)
end

-- Optional cleanup on frame close
if InspectFrame then
    InspectFrame:HookScript("OnHide", function()
        local guid = UnitGUID("target")
        if guid then
            inspectRetryCount[guid] = nil
        end
    end)
end
