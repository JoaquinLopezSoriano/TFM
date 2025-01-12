-- Author      : ChimoB
-- Create Date : 04/01/2025 18:44:53

--[[ Variables ]]--
-- get the final GUI constants
local GUI = Globals().GUI

local ContentRankDBFrame    -- frame (child) for the scroll rank frame
local raidDifficulty        -- difficulty or the raid ( "Normal", "Heroic" or "Mythic"}
--[[ Structure of an itemType
{
    {type = item's category (e.g., Weapon, Armor, Consumable, etc.).},
	{subtype = item's sub-category (e.g., Cloth, Plate, Two-Handed Sword)},
}
]]--
local itemType              -- item type to show the looted number of the item type 
local playerSelected        -- player selected GUID   
local itemSelected          -- item selected link
local filterText            -- filter name text

--[[ Initialize Dropdown ]]-- 

-- Select the raid difficulty and refresh the list
local function OnClickRaidDifficulty(self)
    UIDropDownMenu_SetSelectedID(RaidDifficultyDropdown, self:GetID());
    raidDifficulty = self:GetText()                     -- set the raid difficulty
    RaidDifficultyDBEditString:SetText(raidDifficulty)  -- show it
    ShowRankDBInfo(itemType, raidDifficulty)            -- refresh the list
end

-- Define the raid difficulty dropdown menu
function InitializeRaidDifficultyDropdown(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo();
    -- Define dropdown options
    local items = {"Normal", "Heroic", "Mythic"}
    for i, option in ipairs(items) do
        info.text = option
        info.padding = 10
        info.leftPadding = 5
        info.func = OnClickRaidDifficulty
        info.checked = false
        -- Set the font and size for the dropdown item
        info.fontObject = GameFontHighlightLarge 
        UIDropDownMenu_AddButton(info, level)
	end
end

-- Select the item type and refresh the list
local function OnClickItemType(self)
    UIDropDownMenu_SetSelectedID(ItemTypeDropdown, self:GetID());
    itemType.type = self:GetText()           -- set the raid difficulty
    itemType.equipSlot = nil
    if(itemType.type == "Trinket") then     
        itemType.equipSlot = itemType.type
        itemType.type = "Armor"
    end
    ShowRankDBInfo(itemType, raidDifficulty)    -- refresh the list            
end

-- Define the item type dropdown menu
function InitializeItemTypeDropdown(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo();
    -- Define dropdown options
    local items = {"Armor", "Weapon", "Trinket"}
    for i, option in ipairs(items) do
        info.text = option
        info.padding = 10
        info.leftPadding = 5
        info.func = OnClickItemType
        info.checked = false
        -- Set the font and size for the dropdown item
        info.fontObject = GameFontHighlightLarge 
        UIDropDownMenu_AddButton(info, level)
    end
   
end


--[[ Events Handlers ]]-- 

-- initialize --
-- Called when the addon is shown
function OnLoadDB()
    -- Create the content frame (child) for the scroll frame
    ContentRankDBFrame = CreateFrame("Frame", "ContentRankDBFrame", RankDBListScrollFrame)          -- create the frame  
    ContentRankDBFrame:SetSize(RankDBListScrollFrame:GetWidth(), RankDBListScrollFrame:GetHeight()) -- Initial size larger than the scroll frame
    RankDBListScrollFrame:SetScrollChild(ContentRankDBFrame)                                      -- attach the frame to its scroll frame parent                       
	-- initialize the raid difficulty
    raidDifficulty = raidDifficulty or "Normal"
    RaidDifficultyDBEditString:SetText(raidDifficulty)
    -- initialize the item type
    itemType = {}
    itemType.type = itemType.type or "Armor"
   
end

-- Show the list when the frame is visible
function OnShowDB()
    -- Show the list
    ShowRankDBInfo(itemType, raidDifficulty)
end

-- Remove the children on the list when it hides to hide them too
function OnHideDB()
    RemoveAllChildren(ContentRankDBFrame)
end

--[[ Functions ]]--

-- Show the item tool tip
function ShowDBTooltip(self)
    ShowGameTooltip(self, itemSelected)
end

-- Reset the text on the edit box
function ResetDBEditBoxText()
    filterText = ""     -- reset the filter name text variable too
	FilterDBEditBox:SetText(filterText)   -- reset the edit box
    ShowRankDBInfo(itemType, raidDifficulty)
end

-- Set the filter text to its variable 
function SetDBFilterText()
    filterText = FilterDBEditBox:GetText()    -- get the text written at the edit box
	if #filterText == 0 then                -- if there is no text, hide the reset button
	    ResetFilterTextDBButton:Hide()
	else 
	    ResetFilterTextDBButton:Show()        -- otherwise, show it
        ShowRankDBInfo(itemType, raidDifficulty)  -- update the list
	end                   
end

-- Reset the selected item related values 
local function resetItemSelected()
    itemSelected = nil
	LootDBEditText:SetText("---")
    IconEquipDBTexture:SetTexture(nil)  
    GameTooltip:Hide()                  -- hide the item tool tip
end

 -- Reset lootItem at the IconEquipFrame
function ResetDBIcon(self,button)
    if itemSelected and button == "RightButton" then   -- if the icon frame is right mouse clicked
        resetItemSelected()     -- reset the selected item related values 
        RemoveItemButton:Disable()
        RemovePlayerButton:Enable()
	 end
end 

-- Show the rank info from the database, the looted items of each online player
function ShowRankDBInfo(itemType, raidDifficulty, playerGUID, isShown)
    local sortedList = SortListByName(filterText, BLootDB)
    RemoveAllChildren(ContentRankDBFrame) -- refresh the list at the GUI
    local i = 1     -- index
    for _, key in ipairs(sortedList) do
        local playerInfo = BLootDB[key]       -- LOOP through the database
        -- set the number of items looted based of the type of the raid difficulty and the
		-- item (weapon, armor or trinket) of each player 
		local lootList = GetLootListType(itemType.type, itemType.equipSlot, GetLootListDifficulty(raidDifficulty, BLootDB[playerInfo.GUID]))
        -- create a frame with the player's name and items looted at the ContentRankDBFrame frame
        local PlayerInfoLootDBFrame = CreateFrame("Frame", "PlayerInfoLootDBFrame", ContentRankDBFrame)
        PlayerInfoLootDBFrame:SetSize(ContentRankDBFrame:GetWidth(), GUI.BUTTON_HEIGHT)  -- Set the size of the frame
        PlayerInfoLootDBFrame:SetPoint(GUI.TOPLEFT, ContentRankDBFrame, GUI.TOPLEFT, 0, -((i-1) * GUI.BUTTON_HEIGHT + GUI.BUTTON_PADDING))
        -- Create the text, showing the items looted
        local text = PlayerInfoLootDBFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("RIGHT", PlayerInfoLootDBFrame, "RIGHT", -GUI.LEFT_PADDING, 0)  -- Position it on the left side of the frame
        text:SetSize(GUI.TEXT_WIDTH, PlayerInfoLootDBFrame:GetHeight()) 
		text:SetText(#lootList)  -- Set the text
        text:SetTextColor(GetClassColor(playerInfo.class))
        -- Create the button with the player's name
        local button = CreateFrame("Button", nil, PlayerInfoLootDBFrame, "OptionsListButtonTemplate")
        button:SetSize(PlayerInfoLootDBFrame:GetWidth(), PlayerInfoLootDBFrame:GetHeight())  -- Set the button size
        button:SetPoint("LEFT", PlayerInfoLootDBFrame, "LEFT", 0, 0)  -- Position it on the right side of the frame
        button:SetText(playerInfo.name)  -- Set the button text
        button:GetFontString():SetPoint(GUI.LEFT, button, GUI.LEFT, GUI.LEFT_PADDING/2, 0)
        -- Get the class color based of the class player
        button:GetFontString():SetTextColor(GetClassColor(playerInfo.class))
        local j = 1
       
        local show = false
        if playerGUID == playerInfo.GUID and not isShown then      -- show/hide the item link list based of the isShown value
    		for _, link in ipairs(lootList) do          -- create a button with every link of the list at the ContentRankDBFrame frame
                local linkButton = CreateFrame("Button", nil, ContentRankDBFrame, "OptionsListButtonTemplate")
                linkButton:SetSize(ContentRankDBFrame:GetWidth(), GUI.BUTTON_HEIGHT)
                linkButton:SetPoint(GUI.TOPLEFT, ContentRankDBFrame, GUI.TOPLEFT, 0, -((i+j-1) * GUI.BUTTON_HEIGHT + GUI.BUTTON_PADDING))
		        linkButton:SetText(link)
                linkButton:GetFontString():SetPoint(GUI.LEFT, linkButton, GUI.LEFT, GUI.LEFT_PADDING, 0) 
                linkButton:SetScript("OnEnter", function()  -- when the cursor is over the button,
                    ShowGameTooltip(linkButton, link)       --  show the item tool tip
			    end)
                linkButton:SetScript("OnClick", function(self, button)  -- select a looted item
                    if button == "LeftButton" then
					    itemSelected = link
                        LootDBEditText:SetText(link)
                        IconEquipDBTexture:SetTexture(GetItemIcon(link))
                        RemoveItemButton:Enable()
                        RemovePlayerButton:Disable()
			        end
			    end)
                j = j + 1
		    end
            show = not isShown
        end
        button:SetScript("OnClick", function(self, button)      -- when click on it, show/hide the item link list
			if button == "LeftButton" then
			    ShowRankDBInfo(itemType, raidDifficulty, playerInfo.GUID, show)   -- repaint the list with the show/hide item link list
                resetItemSelected()
                playerSelected = playerInfo.GUID
			    PlayerNameDBEditText:SetText(playerInfo.name)
                RemoveItemButton:Disable()
                RemovePlayerButton:Enable()
			end
        end)    
        i = i + j
    end
end

-- Remove the selected player
function RemovePlayer()
    if playerSelected then
        BLootDB[playerSelected] = nil   -- remove it
        -- Refresh the list
        ShowRankDBInfo(itemType, raidDifficulty)
	end
end

-- Remove the item from the selected player
function RemoveItem()
    -- get the loot list where the item is stored of the selected player
	local lootList = GetLootListType(itemType.type, itemType.equipSlot, GetLootListDifficulty(raidDifficulty, BLootDB[playerSelected]))
    for i, link in ipairs(lootList) do  -- loop through the list
         if link == itemSelected then   -- if the selected item is stored
            table.remove(lootList, i)   -- remove it
            break
        end 
	end
    -- Refresh the list
    ShowRankDBInfo(itemType, raidDifficulty)
end