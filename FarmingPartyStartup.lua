local ADDON_NAME = "FarmingParty"

local FPSettings
local listContainer
local highscoreWindowIsHidden = true

FarmingParty = ZO_Object:Subclass()
FarmingParty.Modules = {}
FarmingParty.DataTypes = {
    MEMBER = 1,
    MEMBER_ITEM = 2
}
FarmingParty.SaveData = {}
FarmingParty.Settings = {}

local function OnPlayerDeactivated(eventCode)
    FarmingParty:Finalize()
end

-- EVENT_ADD_ON_LOADED
function FarmingParty:OnAddOnLoaded(event, addonName)
    if (addonName ~= ADDON_NAME) then
        return
    end

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_DEACTIVATED, OnPlayerDeactivated)
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    FarmingParty.Settings = FarmingPartySettings:New()
    self:Initialize()
end

function FarmingParty:Finalize()
    for moduleName, moduleObject in pairs(self.Modules) do
        moduleObject:Finalize()
    end
end

function FarmingParty:Initialize()
    self.Modules.MemberList = FarmingPartyMemberList:New()
    FarmingParty:ConsoleCommands()
end

function FarmingParty:ConsoleCommands()
    -- Print all available commands to chat
    SLASH_COMMANDS["/fphelp"] = function()
        d("-- Farming Party commands --")
        d("/fp         Show or hide the highscore window.")
        d("/fpc        Print highscores to the chat.")
        d("/fpreset    Reset all highscore values (doesn't remove).")
        d("/fpdelete   Remove everything from highscores.")
    end

    -- Toggle the highscore window
    SLASH_COMMANDS["/fp"] = function()
        self.Modules.MembersList:ToggleMembersWindow()
    end

    SLASH_COMMANDS["/fpc"] = function()
        self.Modules.MembersList:PrintScoresToChat()
    end

    -- Reset all stats from the .member table
    SLASH_COMMANDS["/fpreset"] = function()
        FarmingPartyHighScore:ResetMembers()
        d("Farming Party highscores have been reset")
    end

    -- Clear all members from the .member table
    SLASH_COMMANDS["/fpdelete"] = function()
        FarmingPartyHighScore:DeleteMembers()
        d("Farming Party highscores have been deleted")
    end

    -- Clear all members from the .member table
    SLASH_COMMANDS["/fpm"] = function()
        self.Modules.MembersList:UpdateScrollList()
    end
end

-- Load the addon with this
EVENT_MANAGER:RegisterForEvent(
    ADDON_NAME,
    EVENT_ADD_ON_LOADED,
    function(...)
        FarmingParty:OnAddOnLoaded(...)
    end
)
