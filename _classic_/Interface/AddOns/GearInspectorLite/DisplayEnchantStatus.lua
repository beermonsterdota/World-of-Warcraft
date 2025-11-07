local slotIds = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "ShirtSlot", "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}

local enchantableSlots = {
    HeadSlot = false,
    NeckSlot = false,
    ShoulderSlot = true,
    BackSlot = true,
    ChestSlot = true,
    WristSlot = true,
    HandsSlot = true,
    WaistSlot = true,
    LegsSlot = true,
    FeetSlot = true,
    MainHandSlot = true,
    SecondaryHandSlot = true,
    Finger0Slot = false,
    Finger1Slot = false,
}
local debug = false
local inspectMissingEnchantText = nil

-- Tooltip scanner for buckle detection
local BuckleTooltipScanner = CreateFrame("GameTooltip", "BuckleTooltipScanner", nil, "GameTooltipTemplate")
BuckleTooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local debug = true  -- Set to false to disable debug output

local function BeltHasBuckle(unit, slotId)
    BuckleTooltipScanner:ClearLines()
    BuckleTooltipScanner:SetInventoryItem(unit, slotId)

    for i = 1, BuckleTooltipScanner:NumLines() do
        local line = _G["BuckleTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and text:find("Prismatic Socket") then
                return true -- Buckle is applied and empty
            end
        end
    end

    -- Tooltip doesn't show prismatic socket, may be filled
    local itemLink = GetInventoryItemLink(unit, slotId)
    local gem2 = GetItemGem(itemLink, 2)
    if gem2 then
        return true -- Buckle is applied and filled
    end

    return false -- No buckle detected
end



local function ShowMissingEnchantWarning(slotFrame, slotName)
    if not slotFrame then return end
    if not slotFrame.warningIcon then
        local icon = slotFrame:CreateTexture(nil, "OVERLAY")
        icon:SetTexture("Interface\\Common\\Help-I")
        icon:SetSize(32, 32)
        icon:ClearAllPoints()
        icon:SetPoint("BOTTOM", slotFrame, "BOTTOM", 0, -5)
        slotFrame.warningIcon = icon
    end
    slotFrame.warningIcon:Show()
end

local function HideWarning(slotFrame)
    if slotFrame and slotFrame.warningIcon then
        slotFrame.warningIcon:Hide()
    end
end

function GearInspectorLite_CheckEnchantStatus(slotName)
    local slotID = GetInventorySlotInfo(slotName)
    local frame = _G["Character" .. slotName]
    local link = GetInventoryItemLink("player", slotID)

    if link and frame then
        local itemString = string.match(link, "item:([^|]+)")
        local enchantID = itemString and select(2, strsplit(":", itemString))

        if slotName == "WaistSlot" then
            if not BeltHasBuckle("player", slotID) then
                ShowMissingEnchantWarning(frame, slotName)
                return false
            else
                HideWarning(frame)
                return true
            end
        end

        if not enchantID or enchantID == "" or enchantID == "0" then
            ShowMissingEnchantWarning(frame, slotName)
            return false
        else
            HideWarning(frame)
            return true
        end
    elseif frame then
        HideWarning(frame)
    end

    return true
end

function GearInspectorLite_UpdatePlayerEnchantDisplay()
    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Character" .. slotName]
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotId)

        if slotFrame and slotFrame.warningIcon then
            slotFrame.warningIcon:Hide()
        end

        if itemLink and slotFrame and enchantableSlots[slotName] then
            GearInspectorLite_CheckEnchantStatus(slotName)
        end
    end
end

function GearInspectorLite_CheckInspectEnchantStatus(inspectUnit, slotName)
    local slotID = GetInventorySlotInfo(slotName)
    local frame = _G["Inspect" .. slotName]
    local link = GetInventoryItemLink(inspectUnit, slotID)

    if link and frame then
        local itemString = string.match(link, "item:([^|]+)")
        local enchantID = itemString and select(2, strsplit(":", itemString))

        if slotName == "WaistSlot" then
            if not BeltHasBuckle(inspectUnit, slotID) then
                ShowMissingEnchantWarning(frame, slotName)
                return false
            else
                HideWarning(frame)
                return true
            end
        end

        if not enchantID or enchantID == "" or enchantID == "0" then
            ShowMissingEnchantWarning(frame, slotName)
            return false
        else
            HideWarning(frame)
            return true
        end
    elseif frame then
        HideWarning(frame)
    end

    return true
end

function GearInspectorLite_UpdateInspectEnchantDisplay(inspectUnit)
    local missingEnchantCount = 0

    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Inspect" .. slotName]
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink(inspectUnit, slotId)

        if slotFrame and slotFrame.warningIcon then
            slotFrame.warningIcon:Hide()
        end

        if itemLink and slotFrame and enchantableSlots[slotName] then
            if not GearInspectorLite_CheckInspectEnchantStatus(inspectUnit, slotName) then
                missingEnchantCount = missingEnchantCount + 1
            end
        end
    end

    if not inspectMissingEnchantText then
        local inspectFrame = _G["InspectPaperDollFrame"]
        local levelClassText = _G["InspectLevelText"]

        inspectMissingEnchantText = inspectFrame:CreateFontString(nil, "OVERLAY")
        inspectMissingEnchantText:SetFont(STANDARD_TEXT_FONT, 9)
        inspectMissingEnchantText:SetTextColor(1, 0.82, 0) -- gold

        if levelClassText then
            inspectMissingEnchantText:SetPoint("TOP", levelClassText, "BOTTOM", 0, -28)
        else
            inspectMissingEnchantText:SetPoint("TOP", inspectFrame, "TOP", 0, -75)
        end
    end

    inspectMissingEnchantText:SetText("Missing Enchant Count: " .. missingEnchantCount)
    inspectMissingEnchantText:Show()
end
