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
    WaistSlot = false,
    LegsSlot = true,
    FeetSlot = true,
    MainHandSlot = true,
    SecondaryHandSlot = true,
    Finger0Slot = false,
    Finger1Slot = false,
}

local inspectMissingEnchantText = nil

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

        if not enchantID or enchantID == "" or enchantID == "0" then
            ShowMissingEnchantWarning(frame, slotName)
        else
            HideWarning(frame)
        end
    elseif frame then
        HideWarning(frame)
    end
end

function GearInspectorLite_UpdatePlayerEnchantDisplay()
    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Character" .. slotName]
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotId)

        if itemLink and slotFrame then
            -- 🔶 Enchant check
            if enchantableSlots[slotName] then
                --print ("Checking enchant slot ", slotName)
                GearInspectorLite_CheckEnchantStatus(slotName)
            end
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

        if not enchantID or enchantID == "" or enchantID == "0" then
            if not frame.warningIcon then
                local icon = frame:CreateTexture(nil, "OVERLAY")
                icon:SetTexture("Interface\\Common\\Help-I")
                icon:SetSize(32, 32)
                icon:ClearAllPoints()
                icon:SetPoint("BOTTOM", frame, "BOTTOM", 0, -5)

                frame.warningIcon = icon
            end
            frame.warningIcon:Show()
            return false
        else
            if frame.warningIcon then
                frame.warningIcon:Hide()
            end
        end
    elseif frame then
        if frame.warningIcon then
            frame.warningIcon:Hide()
        end
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

    if itemLink and slotFrame then
        if enchantableSlots[slotName] then
            if not GearInspectorLite_CheckInspectEnchantStatus(inspectUnit, slotName) then
                --print(string.format("Counting %s as missing an enchant", slotName))
                missingEnchantCount = missingEnchantCount + 1
            --else
                --print(string.format("Counting %s as having an enchant", slotName))
            end
        end
    end

    --print(string.format("Missing enchants so far: %d", missingEnchantCount))
end

    -- Create the missing enchant count text if needed
    if not inspectMissingEnchantText then
        local inspectFrame = _G["InspectPaperDollFrame"]
        local levelClassText = _G["InspectLevelText"]

        inspectMissingEnchantText = inspectFrame:CreateFontString(nil, "OVERLAY")
        inspectMissingEnchantText:SetFont(STANDARD_TEXT_FONT, 8)
        inspectMissingEnchantText:SetTextColor(1, 0.82, 0) -- Gold color

        if levelClassText then
            inspectMissingEnchantText:SetPoint("TOP", levelClassText, "BOTTOM", 0, -16)
        else
            inspectMissingEnchantText:SetPoint("TOP", inspectFrame, "TOP", 0, -75)
        end
    end

    inspectMissingEnchantText:SetText("Missing Enchant Count: " .. missingEnchantCount)
    inspectMissingEnchantText:Show()
end
