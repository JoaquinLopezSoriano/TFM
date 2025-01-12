-- Author      : ChimoB
-- Create Date : 10/12/2024 13:07:47

--[[ Variables ]]--
-- get the final GUI constants
local GUI = Globals().GUI
local EVENT = Globals().EVENT
local ITEM = Globals().ITEM

-- locals --
-- local ContentPlayerInfoFrame -- frame (child) for the scroll name list frame
local ContentLootFrame      -- frame (child) for the scroll loot frame
local ContentRankFrame      -- frame (child) for the scroll rank frame
local playerInfoList    -- players list 
local lootInfoList      -- loot list
local assignLootList      -- assignation loot list
local raidDifficulty    -- set the raid difficulty
local filterText        -- filter name text
--[[ Structure of an playerSelected
{
    {GUID = identifier},
    {name = word the player is known},
    {class = The player's class name (e.g., "Warrior", "Mage", etc.)}
}
]]--
local playerSelected       -- player selected
--[[ Structure of an item
{
    {id = identifier},
    {name = word the item is known},
    {link = linked name},
	{icon = graphic image},
    {type = item's category (e.g., Weapon, Armor, Consumable, etc.).},
	{subtype = item's sub-category (e.g., Cloth, Plate, Two-Handed Sword)},
    {equipSlot = the location where the item can be equipped (e.g., HEAD, CHEST)}
}
]]--
local lootItem     -- loot selected

	
--[[ Events Handlers ]]-- 

-- initialize --
-- Called when the addon is shown
function OnLoad()
    -- Create the content frame (child) for the scroll frame
    -- ContentPlayerInfoFrame = CreateFrame("Frame", "ContentPlayerInfoFrame", NameListScrollFrame)    -- create the frame
    -- ContentPlayerInfoFrame:SetSize(NameListScrollFrame:GetWidth(), NameListScrollFrame:GetHeight()) -- Initial size larger than the scroll frame
    -- NameListScrollFrame:SetScrollChild(ContentPlayerInfoFrame)                                      -- attach the frame to its scroll frame parent

    -- Create the content frame (child) for the scroll frame
    ContentLootFrame = CreateFrame("Frame", "ContentLootFrame", LootListScrollFrame)          -- create the frame   
    ContentLootFrame:SetSize(LootListScrollFrame:GetWidth(), LootListScrollFrame:GetHeight()) -- Initial size larger than the scroll frame
    LootListScrollFrame:SetScrollChild(ContentLootFrame)                                      -- attach the frame to its scroll frame parent

    -- Create the content frame (child) for the scroll frame
    ContentRankFrame = CreateFrame("Frame", "ContentRankFrame", RankListScrollFrame)          -- create the frame  
    ContentRankFrame:SetSize(RankListScrollFrame:GetWidth(), RankListScrollFrame:GetHeight()) -- Initial size larger than the scroll frame
    RankListScrollFrame:SetScrollChild(ContentRankFrame)                                      -- attach the frame to its scroll frame parent                       


    -- initialize variables
    playerInfoList = {}   -- member list  ESTA TODAVIA NO LA USO 
    lootInfoList = {}     -- loot list
    playerSelected = {}   -- player selected
    lootItem = {}         -- loot selected
    -- call here, because the event OnEnable is not triggered
    OnEnable()

    

end

-- OnEnable --
-- Called when the addon is enabled
function OnEnable()

    -- Register events
    HandleLootFrame:RegisterEvent(EVENT.GROUP_ROSTER_UPDATE)
    HandleLootFrame:RegisterEvent(EVENT.LOOT_OPENED)            -- LOOT_OPENED
    HandleLootFrame:RegisterEvent(EVENT.PLAYER_ENTERING_WORLD)
    HandleLootFrame:RegisterEvent(EVENT.ZONE_CHANGED_NEW_AREA)
    HandleLootFrame:RegisterEvent(EVENT.PLAYER_LOGIN)
    HandleLootFrame:RegisterEvent(EVENT.PARTY_LEADER_CHANGED)
    -- HandleLootFrame:RegisterEvent("ADDON_LOADED")

    -- Set the function to be called when any registered event is triggered
    HandleLootFrame:SetScript("OnEvent", function(self, event, ...)
        -- register WoW event when the party/raid composition changes, 
	    -- when one player enters or goes off the party or raid
        if event == EVENT.GROUP_ROSTER_UPDATE then
            OnGroupRosterUpdate()
        -- register WoW event when loot is opened   -- MIRAR OTRO EVENTO A VER, PERO ESTE EN PRINCIPIO FUNCIONA, OTROS ME DABAN MAS PROBLEMAS
        elseif event == EVENT.LOOT_OPENED then
            OnLootReceived()
        elseif event == EVENT.PLAYER_ENTERING_WORLD or event == EVENT.ZONE_CHANGED_NEW_AREA then
            CheckRaidLeaderStatus() 
			CheckRaidDifficulty()
        -- This runs when the player logs in or reloads the UI
        elseif event == EVENT.PLAYER_LOGIN then
            OnGroupRosterUpdate()    
        elseif event == EVENT.PARTY_LEADER_CHANGED then
            CheckRaidLeaderStatus()     -- comprobar que con este metodo funciona
        -- elseif event == "ADDON_LOADED" then
           -- CheckRaidLeaderStatus()     -- comprobar que con este metodo funciona
        end
    end)  
end

-- OnDisable --
-- Called when the addon is disabled
function OnDisable()
    -- unregister WoW event when the party/raid composition changes
    HandleLootFrame:UnregisterEvent(EVENT.GROUP_ROSTER_UPDATE)
    -- unregister WoW event when loot is opened
    HandleLootFrame:UnregisterEvent(EVENT.LOOT_OPENED)  
     -- unregister WoW event when player enters the world
    HandleLootFrame:UnregisterEvent(EVENT.PLAYER_ENTERING_WORLD)
    -- unregister WoW event when player changes the area, there is a loading screen
    HandleLootFrame:UnregisterEvent(EVENT.ZONE_CHANGED_NEW_AREA)
    -- unregister WoW event when player is logged
    HandleLootFrame:UnregisterEvent(EVENT.PLAYER_LOGIN)
    -- unregister WoW event when the leader of a party or raid changes
    HandleLootFrame:UnregisterEvent(EVENT.PARTY_LEADER_CHANGED)
    -- unregister WoW event when an addon is loaded
    -- HandleLootFrame:UnregisterEvent("ADDON_LOADED")
end


--[[ Functions ]]--

-- Reset the text on the edit box
function ResetEditBoxText()
    filterText = ""     -- reset the filter name text variable too
	FilterEditBox:SetText(filterText)   -- reset the edit box
end

-- Set the filter text to its variable 
function SetFilterText()
    filterText = FilterEditBox:GetText()    -- get the text written at the edit box
	if #filterText == 0 then                -- if there is no text, hide the reset button
        ResetFilterTextButton:Hide()
	else 
        ResetFilterTextButton:Show()        -- otherwise, show it
	end
    if lootItem.id then                     -- update the list
        ShowRankInfo(lootItem)
    end
end

-- Enable the edit box only if the list has content
function EnableEditBox()
    if lootItem.id then
        FilterEditBox:Enable()
    end
end

-- Function to check conditions and perform actions
function CheckRaidLeaderStatus()
    local name, instanceType = GetInstanceInfo()
    -- Check if the player is in a raid instance and is the raid leader
    if instanceType == "raid" or instanceType == "party" then
		if UnitIsGroupLeader("player") then     -- if the player is the raid leader
         --   C_AddOns.EnableAddOn("BLoot")           
            UseAddon()                          -- show/enable the addon
		else 
            -- C_AddOns.DisableAddOn("BLoot")
            CloseAddon()                        -- hide/disable the addon
		end
    end
end

-- Set the raid difficulty
function CheckRaidDifficulty()
    -- set to default
    raidDifficulty = "Normal"   --- raidDifficulty = "---" ESTO
    RaidDifficultyEditString:SetText(raidDifficulty)
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "raid" or instanceType == "party") then
	    local _, _, difficultyID, difficultyName = GetInstanceInfo()
        -- difficultyID -> numeric ID for the difficulty (1 for Normal, 2 for Heroic)
        -- in some cases it returns 0, so avoid it
        if difficultyID > 0 then            -- if enters in a dungeon or raid     
            raidDifficulty = difficultyName
            RaidDifficultyEditString:SetText(raidDifficulty)
		end
	end
end

-- Info to the raid the item looting
-- Send to the pertinent channels the item being looted 
function YellItem()
     if lootItem.id then    -- checks if the loot item is selected
        if IsInRaid() or IsInGroup() then
            SendChatMessage(lootItem.link, "YELL")
        end
         -- send the message to the raid and raid warning channel ( show it on screen )
        if IsInRaid() then
            SendChatMessage(lootItem.link, "RAID")
            SendChatMessage(lootItem.link, "RAID_WARNING")
        elseif IsInGroup() then
            SendChatMessage(lootItem.link, "PARTY")
        end
	 end
end

-- Set the values of the selected item and show it at an icon and text
function SetShowLootItem(id, name, link, icon, type, subtype, equipSlot)
    -- set item values
    lootItem.id = id
    lootItem.name = name
    lootItem.link = link
    lootItem.icon = icon
    lootItem.type = type
    lootItem.subtype = subtype
    lootItem.equipSlot = equipSlot
    showIcon(lootItem)
end

-- show the icon on the texture and enables the button informing about the item to loot 
function showIcon(lootItem)
     -- show on text and icon
    IconEquipTexture:SetTexture(lootItem.icon)   -- Set the icon texture on the frame
    LootEditText:SetText(lootItem.name)          -- Set the text
	YellButton:Enable()             -- to enable the yell button
end

-- Resets all the values related with the item selected
function resetLootItem()
    IconEquipTexture:SetTexture(nil)    -- Set the icon texture on the frame to its default value
    LootEditText:SetText("---")         -- Set the text to its default value
    lootItem = {}                       -- Set the selected item to its default value
    YellButton:Disable()                -- Disable the yell button
    AssignItemButton:Disable()          -- Disable the assign button
end

 -- Reset lootItem at the IconEquipFrame
function ResetIcon(self,button)
    if lootItem.icon and button == "RightButton" then   -- if the icon frame is right mouse clicked
        resetLootItem()         -- reset the selected item related values 
        GameTooltip:Hide()      -- hide the item tool tip
        RemoveAllChildren(ContentRankFrame) -- refresh the list at the GUI
	 end
end   

 -- Handler when an item is entered or dragged onto the frame
function DragEquip(self)
    --[[ Get the item info selected from the cursor, 
	    the info  of object the player is currently interacting with
        Only get the info related with the item, the only object that can be selected
            inforType -> the type of object the cursor is over (e.g., "item", "spell", "unit")
            itemID -> identifier of the item 
            itemLink -> item link 
	]]-- 
    local infoType, itemID, itemLink = GetCursorInfo()  
    if infoType == "item" and itemLink then     -- checks that it only can by of type item and itemLink has a value
        -- get the item info, the structure described at the lootItem variable
		local name, _, quality, _, _, type, subtype, _, equipSlot, icon = GetItemInfo(itemLink)
        -- checks if the item has an icon and the quality is for purple items = 4
        if icon and quality >= ITEM.MAX_QUALITY then  
            -- set the lootItem values
            SetShowLootItem(itemID, name, itemLink, icon, type, subtype, SetEquipSlot(equipSlot))
            -- show the looted rank related with the equipSlot value ( if its a weapon, armor or trinket) 
            ShowRankInfo(lootItem)
        end
        -- clear any item or spell currently held by the in-game cursor
        ClearCursor()
	end     -- PONER UN ELSE POR SI NO SE QUIERE MOSTRAR AL PONERLO
    if lootItem.link then                       -- if an item is selected at the frame icon 
	    ShowGameTooltip(self, lootItem.link)    -- show its tool tip
    end

end 

-- Show the rank info from the database, the looted items of each online player
function ShowRankInfo(lootItem, playerGUID, isShown)
    local sortedList = SortListByLootItems(lootItem.type, lootItem.equipSlot, raidDifficulty, filterText, BLootDB)
    RemoveAllChildren(ContentRankFrame) -- refresh the list at the GUI
    local i = 1     -- index
    -- loop through the playerInfoList, the online players
	for _, key in ipairs(sortedList) do
        local playerInfo = playerInfoList[key]  
        if playerInfo then
		    -- show only the list or player with the class related with its subtype armor (Cloth, Leather, Mail, and Plate) 
		    -- and all the list for the other items like neck, cloak, shield, weapon, trinket or finger
		    if not IsArmor(lootItem.subtype, lootItem.equipSlot) or GetClassArmor(playerInfo.class) == lootItem.subtype then
                -- IF THE PLAYER IS ONLINE -- comparar con la lista playerInfoList
                -- set the number of items looted based of the type of the raid difficulty and the
				-- item (weapon, armor or trinket) of each player 
			    local lootList = GetLootListType(lootItem.type, lootItem.equipSlot, GetLootListDifficulty(raidDifficulty, BLootDB[playerInfo.GUID]))
                -- create a frame with the player's name and items looted at the ContentRankFrame frame
                local PlayerInfoLootFrame = CreateFrame("Frame", "PlayerInfoLootFrame", ContentRankFrame)
                PlayerInfoLootFrame:SetSize(ContentRankFrame:GetWidth(), GUI.BUTTON_HEIGHT)  -- Set the size of the frame
                PlayerInfoLootFrame:SetPoint(GUI.TOPLEFT, ContentRankFrame, GUI.TOPLEFT, 0, -((i-1) * GUI.BUTTON_HEIGHT + GUI.BUTTON_PADDING))
                -- Create the text, showing the items looted
                local text = PlayerInfoLootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("RIGHT", PlayerInfoLootFrame, "RIGHT", -GUI.LEFT_PADDING, 0)  -- Position it on the left side of the frame
                text:SetSize(GUI.TEXT_WIDTH, PlayerInfoLootFrame:GetHeight()) 
			    text:SetText(#lootList)  -- Set the text
                text:SetTextColor(GetClassColor(playerInfo.class))
                -- Create the button with the player's name
                local button = CreateFrame("Button", nil, PlayerInfoLootFrame, "OptionsListButtonTemplate")
                button:SetSize(PlayerInfoLootFrame:GetWidth(), PlayerInfoLootFrame:GetHeight())  -- Set the button size
                button:SetPoint("LEFT", PlayerInfoLootFrame, "LEFT", 0, 0)  -- Position it on the right side of the frame
                button:SetText(playerInfo.name)  -- Set the button text
                button:GetFontString():SetPoint(GUI.LEFT, button, GUI.LEFT, GUI.LEFT_PADDING/2, 0)
                -- Get the class color based of the class player
                button:GetFontString():SetTextColor(GetClassColor(playerInfo.class))
                
				local j = 1
                local show = false
                if playerGUID == playerInfo.GUID and not isShown then      -- show/hide the item link list based of the isShown value
					for _, link in ipairs(lootList) do          -- create a button with every link of the list at the ContentRankFrame frame
                        local linkButton = CreateFrame("Button", nil, ContentRankFrame, "OptionsListButtonTemplate")
                        linkButton:SetSize(ContentRankFrame:GetWidth(), GUI.BUTTON_HEIGHT)
                        linkButton:SetPoint(GUI.TOPLEFT, ContentRankFrame, GUI.TOPLEFT, 0, -((i+j-1) * GUI.BUTTON_HEIGHT + GUI.BUTTON_PADDING))
		                linkButton:SetText(link)
                        linkButton:GetFontString():SetPoint(GUI.LEFT, linkButton, GUI.LEFT, GUI.LEFT_PADDING, 0) 
                        linkButton:SetScript("OnEnter", function()  -- when the cursor is over the button,
                            ShowGameTooltip(linkButton, link)       --  show the item tool tip
			            end)
                        j = j + 1
		            end
                    show = not isShown
                end
                button:SetScript("OnClick", function(self, button)      -- when click on it, show/hide the item link list
                    if button == "LeftButton" then
					    ShowRankInfo(lootItem, playerInfo.GUID, show)   -- repaint the list with the show/hide item link list
                        if not show then
					        playerSelected = playerInfo 
                            PlayerNameEditText:SetText(playerSelected.name)
                            if lootItem.id then     -- if the item to loot is selected, enable the yell button
                                AssignItemButton:Enable() 
                                YellButton:Disable()
			                end
					    else 
					        playerSelected = {} 
                            PlayerNameEditText:SetText("---")
                            AssignItemButton:Disable() 
                            YellButton:Enable()
					    end
					end
				end)    
                i = i + j
            end
		end 
    end
end

-- Refresh the loot list when loot is opened
function OnLootReceived()
    assignLootList = {} -- clear the list
    lootInfoList = {}   -- clear the list
    for i = 1, GetNumLootItems() do -- loop through the number of items looted. GetNumLootItems() retrieve the number of looted items
      local itemLink = GetLootSlotLink(i) -- get each item link looted
      if itemLink then  -- checks if its a looted item, not coins or so on
            local itemID = select(1, strmatch(itemLink, "item:(%d+)"))  -- get the id from the link
            -- GetItemInfo() -> retrieve detailed information about a specific item        
            local name, _, quality, _, _, type, subtype, _, equipSlot, icon = GetItemInfo(itemLink)
            -- checks if the item has an icon and the quality is for purple items = 4
		    if itemID and quality >= ITEM.MAX_QUALITY then -- QUALITY CHECKS and quality >= 4  --
                -- set a new item with its structure
			    lootInfoList[i] = {}            -- set a new field
                lootInfoList[i].id = itemID     -- id
                lootInfoList[i].name = name     -- name
                lootInfoList[i].link = itemLink -- link
                lootInfoList[i].icon = icon     -- icon
			    lootInfoList[i].type = type     -- type
                lootInfoList[i].subtype = subtype   -- subtype
                lootInfoList[i].equipSlot = SetEquipSlot(equipSlot)   -- equipSlot
                lootInfoList[i].index = i       -- index
            end
		end
    end
    ShowItemLootList() -- refresh the item loot list
end

-- Show the item loot list
function ShowItemLootList()
    RemoveAllChildren(ContentLootFrame) -- refresh the list at the GUI
    for i, lootInfo in pairs(lootInfoList) do   -- loop through the list and show the items looted as a button at the ContentLootFrame frame
	    local ItemInfoLootFrame = CreateFrame("Frame", "ItemInfoLootFrame", ContentLootFrame)
        ItemInfoLootFrame:SetSize(ContentLootFrame:GetWidth(), GUI.BUTTON_HEIGHT)  -- Set the size of the frame
        ItemInfoLootFrame:SetPoint(GUI.TOPLEFT, ContentLootFrame, GUI.TOPLEFT, 0, -((i-1) * GUI.BUTTON_HEIGHT + GUI.BUTTON_PADDING))
        -- Create the text, showing the items looted
        local text = ItemInfoLootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("RIGHT", ItemInfoLootFrame, "RIGHT", GUI.LEFT_PADDING, 0)  -- Position it on the left side of the frame
        text:SetSize(GUI.TEXT_WIDTH*3, ItemInfoLootFrame:GetHeight()) 
        if assignLootList[i] then   -- if the item is assigned, show the player's name too
		    text:SetText(assignLootList[i].playerName)
            text:SetTextColor(GetClassColor(assignLootList[i].playerClass))
		end
        -- Create the button with the player's name
        local button = CreateFrame("Button", nil, ItemInfoLootFrame, "OptionsListButtonTemplate")
        button:SetSize(ItemInfoLootFrame:GetWidth(), GUI.BUTTON_HEIGHT)
        button:SetPoint("LEFT", ItemInfoLootFrame, "LEFT", 0, 0)  -- Position it on the right side of the frame
		button:SetText(lootInfo.link)       -- show the item link
        button:GetFontString():SetPoint(GUI.LEFT, button, GUI.LEFT, 25, 0) 
        if not text:GetText() then  -- check the index value so it can't be clicked again after be assigned
            button:SetScript("OnClick", function(self, button)      -- when left clicked, set the item as the looted item
			    if button == "LeftButton" then
                    lootItem = lootInfo
                    showIcon(lootItem)
                    ShowRankInfo(lootItem)  -- list the looted list based on the item type
                end
            end)
        else 
            button:SetScript("OnClick", function(self, button)      -- when left clicked, set the item as the looted item
			    if button == "RightButton" then
                    local assigment = assignLootList[i]
                    RemoveLootItem(assigment.itemLink, assigment.itemType, 
						assigment.itemEquipSlot, assigment.playerGUID)
                    assignLootList[i] = nil
                    ShowItemLootList()
                end
            end)
		end
    end
end

-- Refresh the name list when the party composition changes
function OnGroupRosterUpdate()
	-- loop through the group members
    for i = 1, GetNumGroupMembers() do
        -- get player's info at a group/raid. GetRaidRosterInfo -> retrieve information about players in your raid group 
        local name, rank, _, _, class, _, _, online = GetRaidRosterInfo(i)
        local playerGUID
		if name then            
            playerGUID = UnitGUID(name)     -- get the GUID of the player using its name
		end

        -- if the playerGUID is obtained and is on line
        if playerGUID and online then               
            -- If a new player has joined, save it at the players group/raid list
            if not playerInfoList[playerGUID] then
                playerInfoList[playerGUID] = {}
                playerInfoList[playerGUID].GUID = playerGUID
            end
            -- Checks if the players is or not on the database
            if not BLootDB[playerGUID] then -- if not, store it, defining its structure
                BLootDB[playerGUID] = {}
                BLootDB[playerGUID].GUID = playerGUID   -- GUID
                BLootDB[playerGUID].name = name         -- name
                BLootDB[playerGUID].class = class       -- players class
                BLootDB[playerGUID].normal = {}
                BLootDB[playerGUID].normal.armor = {}          -- link list of normal armor looted
                BLootDB[playerGUID].normal.weapon = {}         -- link list of normal weapon looted
                BLootDB[playerGUID].normal.trinket = {}        -- link list of normal trinket looted
                BLootDB[playerGUID].normal.tier = {}           -- link list of normal tier looted
                BLootDB[playerGUID].heroic = {}
                BLootDB[playerGUID].heroic.armor = {}          -- link list of heroic armor looted
                BLootDB[playerGUID].heroic.weapon = {}         -- link list of heroic weapon looted
                BLootDB[playerGUID].heroic.trinket = {}        -- link list of heroic trinket looted
                BLootDB[playerGUID].heroic.tier = {}           -- link list of heroic tier looted
                BLootDB[playerGUID].mythic = {}
                BLootDB[playerGUID].mythic.armor = {}          -- link list of mythic armor looted
                BLootDB[playerGUID].mythic.weapon = {}         -- link list of mythic weapon looted
                BLootDB[playerGUID].mythic.trinket = {}        -- link list of mythic trinket looted
                BLootDB[playerGUID].mythic.tier = {}           -- link list of mythic tier looted
            end
            -- on the list
            playerInfoList[playerGUID].name = name
            playerInfoList[playerGUID].class = class          

        else
            -- If a player has left the raid, delete from the list
            if playerInfoList[playerGUID] then
                playerInfoList[playerGUID] = nil
            end
        end
    end
end

-- Stores the selected item with the selected player
function AssignItem()
    -- if the player and the item to loot are selected, enable the assign button
    if playerSelected.name and lootItem.id then         
        -- get the type of item list ( weapon, armor or trinket ) related with the raid difficulty and insert the item
        local lootList =  GetLootListType(lootItem.type, lootItem.equipSlot, GetLootListDifficulty(raidDifficulty, BLootDB[playerSelected.GUID]))
		table.insert(lootList, lootItem.link)
	
        -- add the item and the player to the assignLootList
        if lootItem.index then         
            assignLootList[lootItem.index] = {}
			assignLootList[lootItem.index].itemLink = lootItem.link 
            assignLootList[lootItem.index].itemType = lootItem.type
            assignLootList[lootItem.index].itemEquipSlot = lootItem.equipSlot
            assignLootList[lootItem.index].playerGUID = playerSelected.GUID
            assignLootList[lootItem.index].playerName = playerSelected.name
            assignLootList[lootItem.index].playerClass = playerSelected.class
            ShowItemLootList()
		end
         -- after assign the item to the player, reset variables
        playerSelected = {} -- reset the selected player
        PlayerNameEditText:SetText("---") -- and the text that shows it
        resetLootItem()     -- reset the values related with the item selected
        RemoveAllChildren(ContentRankFrame)  -- refresh the list at the GUI
    end 
end

function RemoveLootItem(link, type, equipSlot, GUID)
    -- get the loot list where the item is stored of the selected player
    local lootList =  GetLootListType(type, equipSlot, GetLootListDifficulty(raidDifficulty, BLootDB[GUID]))
    for i, itemLink in ipairs(lootList) do  -- loop through the list
         if link == itemLink then   -- if the selected item is stored
            table.remove(lootList, i)   -- remove it
            break
        end 
	end
end