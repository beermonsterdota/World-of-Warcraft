local SharedMedia = LibStub("LibSharedMedia-3.0")
EmityCore = {}
EmityCore_Version = "2.2.0"

-- Get Font
function EmityCore:GetFontFromAura(auraName)
    local data = WeakAuras.GetData(auraName)
    if data and data.config and data.config.option and data.config.option.font then
        local path = SharedMedia:Fetch("font", data.config.option.font)
        return path
    end
end

-- Apply Font to Single Region
function EmityCore:ApplyFontToRegion(region, fontPath)
    if not region or not fontPath then return end

    for i, subRegion in ipairs(region.subRegions or {}) do
        if subRegion.type == "subtext" then
			local _, size, flags = subRegion.text:GetFont()
            subRegion.text:SetFont(fontPath, size, flags)
        end
    end
end

-- Apply Font to a Dynamic Group
function EmityCore:ApplyFontToGroup(activeRegions, fontPath)
    if not fontPath then
        return
    end

    for _, regionData in ipairs(activeRegions or {}) do
        local region = regionData.region
        self:ApplyFontToRegion(region, fontPath)
    end
end

-- Update All Fonts in a Group
function EmityCore:PatchFontForGroup(groupName, fontName, isRecursive)
    local icon = "|TInterface\\AddOns\\EmityCore\\icon\\emity_logo.tga:12:12|t"
    local prefix = string.format("%s |cffff3c2dEmityCore|r", icon)

    local groupData = WeakAuras.GetData(groupName)
    if not groupData or not groupData.controlledChildren then return end

    if not isRecursive then
        print(string.format("%s Шрифт изменен в группе: |cffddeeff%s|r", prefix, groupName))
    end

    for _, childName in ipairs(groupData.controlledChildren) do
        local childData = WeakAuras.GetData(childName)

        if childData and (childData.regionType == "group" or childData.regionType == "dynamicgroup") and childData.controlledChildren then
            self:PatchFontForGroup(childName, fontName, true)
        else
            local saved = WeakAurasSaved and WeakAurasSaved.displays and WeakAurasSaved.displays[childName]
				if saved then
					if saved.regionType == "text" then
						saved.font = fontName
					end
				if saved.subRegions then
					for _, sub in ipairs(saved.subRegions) do
						if sub.type == "subtext" then
							sub.text_font = fontName
						end
					end
				end
			end
        end
    end

    if not isRecursive then
        print(string.format("%s |cffa2fff9Пропишите /reload чтобы применить изменения.|r", prefix))
    end
end

-- Get Texture
function EmityCore:GetTextureFromAura(auraName)
    local data = WeakAuras.GetData(auraName)
    if data and data.config and data.config.option and data.config.option.texture then
        return data.config.option.texture
    end
end

-- Apply Texture to Single Region
function EmityCore:ApplyTextureToRegion(region, texture)
    if not region or (region and region.regionType ~= "aurabar") or not texture then return end
    region:SetStatusBarTextureInput("LSM")
    region:SetStatusBarTextureLSM(texture)
end

-- Apply Texture to a Dynamic Group
function EmityCore:ApplyTextureToGroup(activeRegions, texture)
    if not texture then
        return
    end

    for _, regionData in ipairs(activeRegions or {}) do
        local region = regionData.region
        self:ApplyTextureToRegion(region, texture)
    end
end

-- Update All Textures in a Group
function EmityCore:PatchTextureForGroup(groupName, texture, isRecursive)
    local icon = "|TInterface\\AddOns\\EmityCore\\icon\\emity_logo.tga:12:12|t"
    local prefix = string.format("%s |cffff3c2dEmityCore|r", icon)
    
    local groupData = WeakAuras.GetData(groupName)
    if not groupData or not groupData.controlledChildren then return end
    
    if not isRecursive then
        print(string.format("%s Текстуры изменены в группе: |cffddeeff%s|r", prefix, groupName))
    end
    
    for _, childName in ipairs(groupData.controlledChildren) do
        local childData = WeakAuras.GetData(childName)
        
        if childData and (childData.regionType == "group" or childData.regionType == "dynamicgroup") and childData.controlledChildren then
            self:PatchTextureForGroup(childName, texture, true)
        else
            local saved = WeakAurasSaved and WeakAurasSaved.displays and WeakAurasSaved.displays[childName]
            if saved and saved.regionType == "aurabar" then
                saved.textureSource = "LSM"
                saved.texture = texture 
            end
        end
    end
    
    if not isRecursive then
        print(string.format("%s |cffa2fff9Пропишите /reload чтобы применить изменения.|r", prefix))
    end
end