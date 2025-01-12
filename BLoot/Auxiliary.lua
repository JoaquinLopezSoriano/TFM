-- Author      : ChimoB
-- Create Date : 03/01/2025 11:56:12

    -- Auxiliary functions --
-- Left-aligning pad with spaces
function PadWithSpaces(text, totalLength)
    local textLength = #text
    if textLength < totalLength then
        return text .. string.rep(" ", totalLength - textLength)
    else
        return text  -- If the text is longer, leave it unchanged
    end
end

-- Capitalize the first letter, lower text the rest
function CapitalizeFirstLetter(str)
    if str == nil or str == "" then
        return str  -- Return the string as is if it's nil or empty
    end
    return string.upper(string.sub(str, 1, 1)) .. string.lower(string.sub(str, 2))
end

-- Get the equipSlot, removing the first part and capitalize the first letter, lower text the rest
-- The raw INVT_HAND or INVT_TRINKET
function SetEquipSlot(equipSlot)
    local start_pos = string.find(equipSlot, "_")
    local substr = string.sub(equipSlot, start_pos + 1)  -- Skip the underscore
    return CapitalizeFirstLetter(substr)
end

-- Remove all children of a frame 
function RemoveAllChildren(frame) 
	local children = { frame:GetChildren() } 
	for _, child in ipairs(children) do 
		child:Hide() 
		child:SetParent(nil) 
	end 
end 

-- Show the tool tip 
function ShowGameTooltip(frame, text) 
    if text then
	    GameTooltip:SetOwner(frame, Globals().GUI.ANCHOR_RIGHT)
	    GameTooltip:SetHyperlink(text) 
	    GameTooltip:Show()
	end
end 

-- Sort a list by name
function SortListByName(filterText, playerTable)
	-- Create an auxiliary array to hold keys
    local sortedKeys = {}
    local filteredPlayer = {}

    -- filter the list by name
    if filterText then 
	    for GUID, playerInfo in pairs(playerTable) do
            if playerInfo.name:lower():find(filterText:lower()) then
                filteredPlayer[GUID] = playerInfo
            end
        end
	else
	    filteredPlayer = playerTable       -- if there is nothing, the filter list is the primary list
	end

    -- Insert keys into the array
    for key in pairs(filteredPlayer) do
        table.insert(sortedKeys, key)
    end

    -- Sort the keys based on their associated values
    table.sort(sortedKeys, function(key1, key2)
        return filteredPlayer[key1].name < filteredPlayer[key2].name
    end)

    return sortedKeys
end

-- Sort a list by name
--[[
    itemType -> the item type (weapon, armor or trinket)
    itemEquipSlot -> if its a trinket
    raidDifficulty  -> raid difficulty (Normal, Heroic, Mythic)
    filterText  -> text to filter by name
    playerTable -> player list
]]--
function SortListByLootItems(itemType, itemEquipSlot, raidDifficulty, filterText, playerTable)
	-- Create an auxiliary array to hold keys
    local sortedKeys = {}
    local filteredPlayer = {}

    -- filter the list by name
    if filterText then 
	    for GUID, playerInfo in pairs(playerTable) do
            if playerInfo.name:lower():find(filterText:lower()) then
                filteredPlayer[GUID] = playerInfo
            end
        end
	else
	    filteredPlayer = playerTable       -- if there is nothing, the filter list is the primary list
	end

    -- Insert keys into the array
    for key in pairs(filteredPlayer) do
        table.insert(sortedKeys, key)
    end
  

    -- Sort the keys based 1º on the number of items looted, 2º by name
    table.sort(sortedKeys, function(key1, key2)
        -- Compare by length of the list first
        aLength = #GetLootListType(itemType, itemEquipSlot, GetLootListDifficulty(raidDifficulty,filteredPlayer[key1]))
        bLength = #GetLootListType(itemType, itemEquipSlot, GetLootListDifficulty(raidDifficulty,filteredPlayer[key2]))
   
		if aLength == bLength then  -- If list lengths are equal, sort alphabetically
            return filteredPlayer[key1].name < filteredPlayer[key2].name 
        else
            return aLength < bLength  -- Otherwise, sort by list length
        end			
    end)

    return sortedKeys
end

-- Return the color related with its class
function GetClassColor(class)
    local classColor = RAID_CLASS_COLORS[class:upper()]
    return classColor.r, classColor.g, classColor.b
end

-- Return the hexadecimal color related with its class
function GetHexClassColor(class)
    return RAID_CLASS_COLORS[class:upper()]:GenerateHexColor()
end

-- Get the type of list based on of the difficulty of the raid
function GetLootListDifficulty(raidDifficulty, rankInfo)
    if raidDifficulty == "Normal" then
        return rankInfo.normal
	elseif raidDifficulty == "Heroic" then
	    return rankInfo.heroic
	elseif raidDifficulty == "Mythic" then
        return rankInfo.mythic
    end
    return {}
end

-- get the list of the item type and equipSlot (Weapon, Armor, Trinket)
function GetLootListType(itemType, itemEquipSlot,rankInfo)
    if itemType == "Weapon" then            
        return rankInfo.weapon              -- weapon list links
    elseif itemType == "Armor" then
		if itemEquipSlot == "Trinket" then
	        return rankInfo.trinket         -- trinket list links
		else    
		    return rankInfo.armor or {}     -- armor list links
		end
	end    
    return {}
end

local armorSubtype = {"Cloth", "Leather", "Mail", "Plate"}
-- Check if the item is an armor (Cloth, Leather, Mail, and Plate)
-- is not a neck, cloak, shield, weapon, trinket or finger
function IsArmor(itemSubtype, itemEquipSlot)
    if itemEquipSlot == "Cloak" then    -- the cloak is of cloth subtype
        return false
    else
        -- not common armor like Trinket, Finger, Neck o Cloak
        for _, value in ipairs(armorSubtype) do -- loop through the armor subtypes
            if value == itemSubtype then
                return true
            end
        end
    end    
    return false
end

-- Define the armor types for each class
local armorTypes = {
    ["Warrior"] = "Plate",
    ["Paladin"] = "Plate",
    ["Death Knight"] = "Plate",
    ["Hunter"] = "Mail",
    ["Shaman"] = "Mail",
    ["Rogue"] = "Leather",
    ["Monk"] = "Leather",
    ["Druid"] = "Leather",
    ["Mage"] = "Cloth",
    ["Warlock"] = "Cloth",
    ["Priest"] = "Cloth",
}
-- Get the class armor type
function GetClassArmor(class)
    return armorTypes[class]
end
