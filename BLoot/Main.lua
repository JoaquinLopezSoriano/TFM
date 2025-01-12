-- Author      : ChimoB
-- Create Date : 05/01/2025 1:54:49

--[[ Variables ]]--
-- library --
-- load the ace3 libraries
BLootAddon = LibStub("AceAddon-3.0"):NewAddon("BLoot", "AceConsole-3.0", "AceEvent-3.0" )
-- load the mini map icon library
local icon = LibStub("LibDBIcon-1.0", true)

 --[[ Structure of the BLootDB database
{
    {GUID = player's identifier},
    {name = word the player is known},
    {class = The player's class name (e.g., "Warrior", "Mage", etc.)},
	{armor = link list of armor looted},
	{tier = link list of tier looted},
    {trinket = link list of trinket looted},
	{weapon = link list of weapons looted},
}
]]--


-- Set the mini map button ( copied from the example )
local bLootLIcon = LibStub("LibDataBroker-1.1"):NewDataObject("BLoot", {  
	type = "data source",  
	text = "BLoot!",  
	icon = "Interface\\AddOns\\BLoot\\Icons\\logo",  
	OnClick = function(self, button)
        ToggleMainFrame(self, button)
	end,
    OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end

		tooltip:AddLine("BLoot\n\nLeft-click: Open BLoot\nRight-click: Open BLoot Settings", nil, nil, nil, nil)
	end,
})  


--[[ Events Handlers ]]--

-- initialize --
-- Called when the addon is loaded
function BLootAddon:OnInitialize()
	
	ManageDBFrame:Hide()    -- hide the second frame tab
	-- set the mini map button ( copied from the example )
    -- Assuming you have a ## SavedVariables: BLootSavedIcon line in your TOC
	self.db = LibStub("AceDB-3.0"):New("BLootSavedIcon", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	-- register the minimap button in the saved variable ( copied from the example )
    icon:Register("BLoot", bLootLIcon, self.db.profile.minimap)
	
	--  our frame with 'Escape' on our keyboard
    -- table.insert(UISpecialFrames, HandleLootFrame:GetName())

    -- Register the slash command
    SLASH_BLOOT1 = "/BLoot" -- The slash command name
    SlashCmdList["BLOOT"] = CommandHandler    -- The function that will be executed

	-- SavedVariables / Database --
    -- Check if the SavedVariables are already initialized, otherwise initialize them
    if not BLootDB then
        BLootDB = {}
    end

end

--[[ Functions ]]--

    -- Command functions --
-- Define a function that will be called when the slash command is used
function CommandHandler(msg)
    -- the comparison is key sensitive, so format it.
    msg = CapitalizeFirstLetter(msg)    -- the format is, first-> capital letter, rest->lower case
    if msg == "Show" then       -- display main frame
		MainFrame:Show() 
	elseif msg == "Hide" then   -- conceal main frame
		MainFrame:Hide()
    elseif msg == "Help" then   -- show the possible commands
        -- This prints a message in yellow in the default chat window
        DEFAULT_CHAT_FRAME:AddMessage("Commands: /BLoot show, /BLoot hide.", 1, 1, 0)
    else
        -- This prints a message in yellow in the default chat window
        DEFAULT_CHAT_FRAME:AddMessage("Unknown command. Type /BLoot help for usage.", 1, 1, 0)
    end
end


-- Toggle the HandleLootFrame after clicking on a button
function ToggleMainFrame(self, button)
    if button == "LeftButton" then          -- left mouse button clicked
        if not MainFrame:IsShown() then     -- toggle the main frame
            MainFrame:Show()
        else
            MainFrame:Hide()
        end
	elseif button == "RightButton" then     -- right mouse button clicked
         print("BLoot Setting on Process")  -- toggle the setting frame
	 end
end 

function CloseAddon()
    -- Hide the frame
    MainFrame:Hide()
    -- Disable mouse interaction
    MainFrame:EnableMouse(false)
    -- Optionally, you can also unregister all events to prevent any updates:
    MainFrame:UnregisterAllEvents()
    SlashCmdList["BLOOT"] = nil
    icon:Hide("BLoot")
end

function UseAddon()
    -- Hide the frame
    MainFrame:Show()
    -- Disable mouse interaction
    MainFrame:EnableMouse(true)
    -- Optionally, you can also unregister all events to prevent any updates:
    -- MainFrame:UnregisterAllEvents()
    SlashCmdList["BLOOT"] = CommandHandler
    icon:Show("BLoot")
end

