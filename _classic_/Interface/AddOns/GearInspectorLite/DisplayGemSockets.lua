-- DisplayGemSockets.lua


local inspectMissingGemCountText = nil

local slotIds = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "ShirtSlot", "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}

local socketFileIDs = {
    EMPTY_SOCKET_BLUE = 136256,
    EMPTY_SOCKET_META = 136257,
    EMPTY_SOCKET_RED = 136258,
    EMPTY_SOCKET_YELLOW = 136259,
    EMPTY_SOCKET_PRISMATIC = 458977,
}

local socketOrder = {
    "EMPTY_SOCKET_META",
    "EMPTY_SOCKET_RED",
    "EMPTY_SOCKET_YELLOW",
    "EMPTY_SOCKET_BLUE",
    "EMPTY_SOCKET_PRISMATIC",
}

local socketIconSize = 14
local overlays = {}
local ilvlTexts = {}

local function GetItemSocketInfo(link)
    if not link then return nil end

    local _, payload = strsplit("Hitem:", link)
    local itemID, enchantID, gem1, gem2, gem3 = strsplit(":", payload)
    local ret = {
        numSockets = 0,
        numEmptySockets = 0,
        socketTypes = {},
        filledSockets = {},
        emptySockets = {},
    }

    local sockets = {}
    local itemSocketsOrdered = {}

    local stats = GetItemStats(link)
    if stats then
        for k, v in pairs(stats) do
            if k:find("SOCKET", nil, true) then
                sockets[k] = (sockets[k] or 0) + v
                ret.numSockets = ret.numSockets + v
            end
        end
    end
    if ret.numSockets > 0 then
        for _, socketType in ipairs(socketOrder) do
            if sockets[socketType] and sockets[socketType] > 0 then
                for i = 1, sockets[socketType] do
                    table.insert(itemSocketsOrdered, socketFileIDs[socketType])
                    table.insert(ret.socketTypes, socketType)
                end
            end
        end

        for i = 1, 3 do
            local gemTexture = GetItemGem(link, i)
            local socketType = ret.socketTypes[i]

            if gemTexture then
                table.insert(ret.filledSockets, socketType or "UNKNOWN")
            elseif itemSocketsOrdered[i] then
                table.insert(ret.emptySockets, socketType or "UNKNOWN")
                ret.numEmptySockets = ret.numEmptySockets + 1
            end
        end
    end

    return ret
end

local function ClearOverlays()
    for _, tex in pairs(overlays) do
        tex:Hide()
        tex:SetTexture(nil)
    end
    for _, txt in pairs(ilvlTexts) do
        txt:Hide()
    end
end

function GearInspectorLite_UpdatePlayerEmptySocketIcons()
    ClearOverlays()

    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Character" .. slotName]
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotId)

        if itemLink and slotFrame then
            local socketInfo = GetItemSocketInfo(itemLink)

            if socketInfo and socketInfo.numEmptySockets > 0 then
                local cover = overlays[slotName .. "_cover"]
                if not cover then
                    cover = slotFrame:CreateTexture(nil, "ARTWORK")
                    cover:SetAllPoints(slotFrame)
                    overlays[slotName .. "_cover"] = cover
                end
                cover:SetColorTexture(0, 0, 0, 0.8)
                cover:Show()

                -- Socket icons
                for i, socketType in ipairs(socketInfo.emptySockets) do
                    local iconPath = socketFileIDs[socketType]
                    if iconPath then
                        local tex = overlays[slotName .. i]
                        if not tex then
                            tex = slotFrame:CreateTexture(nil, "OVERLAY")
                            tex:SetSize(socketIconSize, socketIconSize)
                            tex:SetPoint("TOPRIGHT", slotFrame, "TOPRIGHT", -(i - 1) * (socketIconSize + 2), 0)
                            overlays[slotName .. i] = tex
                        end
                        tex:SetTexture(iconPath)
                        tex:Show()
                    end
                end
            else
                local cover = overlays[slotName .. "_cover"]
                if cover then cover:Hide() end
            end
        end
    end
end

function GearInspectorLite_UpdateInspectEmptySocketIcons(unitToken)
    GearInspectorLite_Overlays = GearInspectorLite_Overlays or {}
    local overlays = GearInspectorLite_Overlays

    local slotIds = {
        "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
        "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot",
        "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
        "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
    }
    local maxSockets = 3  -- max gem sockets per item

    -- Clear all previous overlays before updating
    for _, slotName in ipairs(slotIds) do
        local cover = overlays[slotName .. "_cover"]
        if cover then
            cover:Hide()
            cover:SetTexture(nil)
        end

        for i = 1, maxSockets do
            local tex = overlays[slotName .. i]
            if tex then
                tex:Hide()
                tex:SetTexture(nil)
            end
        end
    end

    local totalMissingGems = 0
    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Inspect" .. slotName]
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink(unitToken, slotId)

        if itemLink and slotFrame then
            local socketInfo = GetItemSocketInfo(itemLink)

            if socketInfo and socketInfo.numEmptySockets > 0 then
                totalMissingGems = totalMissingGems + socketInfo.numEmptySockets
                local cover = overlays[slotName .. "_cover"]
                if not cover then
                    cover = slotFrame:CreateTexture(nil, "ARTWORK")
                    cover:SetAllPoints(slotFrame)
                    overlays[slotName .. "_cover"] = cover
                end
                cover:SetColorTexture(0, 0, 0, 0.8)
                cover:Show()

                for i, socketType in ipairs(socketInfo.emptySockets) do
                    local iconPath = socketFileIDs[socketType]
                    if iconPath then
                        local tex = overlays[slotName .. i]
                        if not tex then
                            tex = slotFrame:CreateTexture(nil, "OVERLAY")
                            tex:SetSize(socketIconSize, socketIconSize)
                            tex:SetPoint("TOPRIGHT", slotFrame, "TOPRIGHT", -(i - 1) * (socketIconSize + 2), 0)
                            overlays[slotName .. i] = tex
                        end
                        tex:SetTexture(iconPath)
                        tex:Show()
                    end
                end
            else
                -- No empty sockets: hide any overlays for this slot
                local cover = overlays[slotName .. "_cover"]
                if cover then
                    cover:Hide()
                    cover:SetTexture(nil)
                end

                for i = 1, maxSockets do
                    local tex = overlays[slotName .. i]
                    if tex then
                        tex:Hide()
                        tex:SetTexture(nil)
                    end
                end
            end
        end
    end

    if not inspectMissingGemCountText then
        local inspectFrame = _G["InspectPaperDollFrame"]
        local levelClassText = _G["InspectLevelText"]

        inspectMissingGemCountText = inspectFrame:CreateFontString(nil, "OVERLAY")
        inspectMissingGemCountText:SetFont(STANDARD_TEXT_FONT, 8)
        inspectMissingGemCountText:SetTextColor(1, 0.82, 0)

        if levelClassText then
            inspectMissingGemCountText:SetPoint("TOP", levelClassText, "BOTTOM", 0, -8)
        else
            inspectMissingGemCountText:SetPoint("TOP", inspectFrame, "TOP", 0, -75)
        end

    end

    inspectMissingGemCountText:SetText("Missing Gem Count: " .. totalMissingGems)
    inspectMissingGemCountText:Show()
end
