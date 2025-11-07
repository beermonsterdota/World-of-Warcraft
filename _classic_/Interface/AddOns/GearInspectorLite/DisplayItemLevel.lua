-- DisplayItemLevel.lua (GearInspectorLite) — effective ilvl with upgrades
-- Drop-in replacement for your current file.
-- Reads the equipped-slot tooltip (which shows upgraded ilvl) and supports "Upgrade Level: n/2".
-- Classic‑safe: avoids C_Item.* APIs.

GearInspectorLite = GearInspectorLite or {}

local MAX_RETRIES  = 5
local RETRY_DELAY  = 0.2
local UPGRADE_STEP = 4   -- MoP Classic valor upgrades are +4 per rank (set to 2/8 if your season differs)

local slotIds = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}

local ilvlTextConfig = {
    default = { point = "LEFT",  relativePoint = "RIGHT", xOffset =  8,  yOffset = 0 },
    rightSide= { point = "RIGHT", relativePoint = "LEFT",  xOffset = -10, yOffset = 0 },
    above    = { point = "BOTTOM",relativePoint = "TOP",   xOffset =  0,  yOffset = 6 },
}

-- =========================
-- Tooltip helpers (EQUIPPED SLOT)
-- =========================
local GIL_ScanTT = CreateFrame("GameTooltip", "GIL_ScanTT", UIParent, "GameTooltipTemplate")
GIL_ScanTT:SetOwner(UIParent, "ANCHOR_NONE")

local function ParseTooltipItemLevel(maxLines)
    local pat = (_G.ITEM_LEVEL or "Item Level %d"):gsub("%%d", "(%%d+)")
    local n = math.min(GIL_ScanTT:NumLines(), maxLines or 10)
    for i = 2, n do
        local line = _G["GIL_ScanTTTextLeft"..i]
        local txt  = line and line.GetText and line:GetText()
        if txt then
            local v = tonumber(txt:match(pat))
            if v then return v end
        end
    end
end

local function ParseTooltipUpgradeRank(maxLines)
    -- Matches "Upgrade Level: n/2" (case-insensitive; tolerant of spaces)
    local pat = "[Uu][Pp][Gg][Rr][Aa][Dd][Ee]%s+[Ll][Ee][Vv][Ee][Ll]%s*:%s*(%d+)%s*/%s*(%d+)"
    local n = math.min(GIL_ScanTT:NumLines(), maxLines or 14)
    for i = 2, n do
        local line = _G["GIL_ScanTTTextLeft"..i]
        local txt  = line and line.GetText and line:GetText()
        if txt then
            local cur, max = txt:match(pat)
            if cur and max then return tonumber(cur), tonumber(max) end
        end
    end
end

local function BaseIlvlFromLink(link)
    if not link then return nil end
    local base = select(4, GetItemInfo(link))
    if base and base > 0 then return base end
end

-- Single, authoritative function to fetch EFFECTIVE ilvl from the EQUIPPED SLOT
local function GIL_GetSlotEffectiveItemLevel(unit, slotId)
    if not UnitExists(unit) then return nil end

    -- 1) Equipped slot tooltip (this is what shows 504 on upgraded boots)
    GIL_ScanTT:ClearLines()
    local ok = pcall(GIL_ScanTT.SetInventoryItem, GIL_ScanTT, unit, slotId)
    if ok then
        local tipIlvl      = ParseTooltipItemLevel(12)
        local upCur, upMax = ParseTooltipUpgradeRank(14)
        if tipIlvl and tipIlvl > 0 then
            -- Many Classic branches already show the FINAL effective ilvl here
            return tipIlvl
        end
        -- If tooltip ilvl is base but upgrade rank is present, synthesise
        if upCur and upCur > 0 then
            local link = GetInventoryItemLink(unit, slotId)
            local base = BaseIlvlFromLink(link) or 0
            if base > 0 then
                return base + (upCur * UPGRADE_STEP)
            end
        end
    end

    -- 2) Try global GetDetailedItemLevelInfo(link) if present on your client
    local link = GetInventoryItemLink(unit, slotId)
    if link and GetDetailedItemLevelInfo then
        local eff = GetDetailedItemLevelInfo(link)
        if eff and eff > 0 then return eff end
    end

    -- 3) Fallback: base
    return BaseIlvlFromLink(link)
end

-- =========================
-- Colour rules (unchanged)
-- =========================
local function GetFlatIlvlColor(ilvl, minIlvl, maxIlvl)
    if not ilvl then return 1,1,1 end
    if maxIlvl == minIlvl then
        return 0, 1, 0   -- all green
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

-- =========================
-- Inspect average ilvl
-- =========================
local inspectAvgIlvlText

local function CalculateAndPrintInspectAverageItemLevel(inspectUnit)
    if not inspectUnit or not UnitExists(inspectUnit) then return end

    local sumIlvl, count = 0, 0
    local offhandLink = GetInventoryItemLink(inspectUnit, GetInventorySlotInfo("SecondaryHandSlot"))

    for _, slotName in ipairs(slotIds) do
        local slotId = GetInventorySlotInfo(slotName)
        local ilvl   = GIL_GetSlotEffectiveItemLevel(inspectUnit, slotId)
        if ilvl and ilvl > 0 then
            if slotName == "MainHandSlot" and not offhandLink then
                sumIlvl = sumIlvl + ilvl * 2
                count   = count + 2
            elseif slotName ~= "SecondaryHandSlot" then
                sumIlvl = sumIlvl + ilvl
                count   = count + 1
            end
        end
    end

    if count == 0 then return end
    local avgIlvl = math.floor(sumIlvl / count)

    if not inspectAvgIlvlText then
        local inspectFrame   = _G["InspectPaperDollFrame"]
        local levelClassText = _G["InspectLevelText"]
        inspectAvgIlvlText = (inspectFrame and inspectFrame:CreateFontString(nil, "OVERLAY")) or nil
        if inspectAvgIlvlText then
            inspectAvgIlvlText:SetFont(STANDARD_TEXT_FONT, 8)
            inspectAvgIlvlText:SetTextColor(1, 0.82, 0)
            if levelClassText then
                inspectAvgIlvlText:SetPoint("TOP", levelClassText, "BOTTOM", 0, 0)
            else
                inspectAvgIlvlText:SetPoint("TOP", inspectFrame, "TOP", 0, -75)
            end
        end
    end

    if inspectAvgIlvlText then
        inspectAvgIlvlText:SetText("Average Item Level: " .. avgIlvl)
        inspectAvgIlvlText:Show()
    end
end

-- =========================
-- Player & Inspect displays
-- =========================
local playerRetryCount = 0
local inspectRetryCount = {}

function GearInspectorLite_UpdatePlayerItemLevelDisplay()
    local ilvlTexts = GearInspectorLite.playerIlvlTexts or {}
    GearInspectorLite.playerIlvlTexts = ilvlTexts

    local minIlvl, maxIlvl = math.huge, 0
    local foundValid = false

    -- pre-pass to find min/max
    for _, slotName in ipairs(slotIds) do
        local slotId = GetInventorySlotInfo(slotName)
        local ilvl   = GIL_GetSlotEffectiveItemLevel("player", slotId)
        if ilvl and ilvl > 0 then
            foundValid = true
            if ilvl < minIlvl then minIlvl = ilvl end
            if ilvl > maxIlvl then maxIlvl = ilvl end
        end
    end

    if not foundValid then
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

    -- render
    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Character" .. slotName]
        if slotFrame then
            local slotId = GetInventorySlotInfo(slotName)
            local ilvl   = GIL_GetSlotEffectiveItemLevel("player", slotId)

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

function GearInspectorLite_UpdateInspectItemLevelDisplay(inspectUnit)
    if not inspectUnit or not UnitExists(inspectUnit) then return end

    local guid = UnitGUID(inspectUnit)
    if not guid then return end
    inspectRetryCount[guid] = inspectRetryCount[guid] or 0

    local ilvlTexts = GearInspectorLite.inspectIlvlTexts or {}
    GearInspectorLite.inspectIlvlTexts = ilvlTexts

    local minIlvl, maxIlvl = math.huge, 0
    local foundValid = false

    -- pre-pass to find min/max
    for _, slotName in ipairs(slotIds) do
        local slotId = GetInventorySlotInfo(slotName)
        local ilvl   = GIL_GetSlotEffectiveItemLevel(inspectUnit, slotId)
        if ilvl and ilvl > 0 then
            foundValid = true
            if ilvl < minIlvl then minIlvl = ilvl end
            if ilvl > maxIlvl then maxIlvl = ilvl end
        end
    end

    if not foundValid then
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

    -- render
    for _, slotName in ipairs(slotIds) do
        local slotFrame = _G["Inspect" .. slotName]
        if slotFrame then
            local slotId = GetInventorySlotInfo(slotName)
            local ilvl   = GIL_GetSlotEffectiveItemLevel(inspectUnit, slotId)

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

-- Optional cleanup on frame close (no persistent state kept here)
if InspectFrame then
    InspectFrame:HookScript("OnHide", function() end)
end
