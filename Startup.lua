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
FarmingParty.FormatNumber = function(num, numDecimalPlaces)
        return string.format("%0." .. (numDecimalPlaces or 0) .. "f", num)
    end

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
    self.Modules.Logger = FarmingPartyLogger:New()
    self.Modules.MemberItems = FarmingPartyMemberItems:New()
    self.Modules.Loot = FarmingPartyLoot:New()
    FarmingParty:ConsoleCommands()
end

function FarmingParty:ConsoleCommands()
    -- Print all available commands to chat
    SLASH_COMMANDS["/fphelp"] = function()
        d("-- Farming Party commands --")
        d("/fp                  Show or hide the highscore window.")
        d("/fp [start||stop]    Start or stop loot tracking.")
        d("/fp [status]         Show loot tracking status.")
        d("/fpc                 Puts high score output into the chat box.")
        d("/fpreset             Resets all loot data.")
    end

    -- Toggle the highscore window
    SLASH_COMMANDS["/fp"] = function(param)
        local trimmedParam = string.gsub(param, "%s$", "")
        if(trimmedParam == "") then
            self.Modules.MemberList:ToggleMembersWindow()            
        elseif (trimmedParam == 'start') then
            if (FarmingParty.Settings:Status() == FarmingParty.Settings.TRACKING_STATUS.DISABLED) then
                self.Modules.MemberList:AddEventHandlers()
                self.Modules.Loot:AddEventHandlers()
            end
            d("[Farming Party]: Tracking is on")
        elseif (trimmedParam == 'stop' or trimmedParam == 'pause') then
            self.Modules.MemberList:RemoveEventHandlers()
            self.Modules.Loot:RemoveEventHandlers()
            d("[Farming Party]: Tracking is off")
        elseif (trimmedParam == 'status') then
            if (FarmingParty.Settings:Status() == FarmingParty.Settings.TRACKING_STATUS.ENABLED) then
                d("[Farming Party]: Tracking is on")
            else
                d("[Farming Party]: Tracking is off")
            end
        else
            d(string.format('Invalid parameter %s.', trimmedParam))
            SLASH_COMMANDS["/fphelp"]()
        end
    end

    SLASH_COMMANDS["/fpc"] = function()
        self.Modules.MemberList:PrintScoresToChat()
    end

    SLASH_COMMANDS["/fpm"] = function()
        FarmingPartyMemberItems:ToggleWindow()
    end

    -- Reset all stats from the .member table
    SLASH_COMMANDS["/fpreset"] = function()
        self.Modules.MemberList:Reset()
        d("Farming Party has been reset")
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
