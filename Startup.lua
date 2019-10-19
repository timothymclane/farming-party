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

local DIGIT_GROUP_REPLACER = ","
local DIGIT_GROUP_DECIMAL_REPLACER = "."
local DIGIT_GROUP_REPLACER_THRESHOLD = zo_pow(10, GetDigitGroupingSize())

-- Because the ZOS function doesn't handle strings and I don't want to reparse the string later to require 2 decimal places.
-- Maybe I can use the ZOS function with some finagling, but I don't feel like doing that right now.
function FP_LocalizeDecimalNumber(amount)
    -- Guards against negative 0 as a displayed numeric value
    if amount == 0 then
        amount = "0"
    end

    local amountNumber = tonumber(amount)
    if amountNumber >= DIGIT_GROUP_REPLACER_THRESHOLD then
        -- We have a number like 10000.5, so localize the non-decimal digit group separators (e.g., 10000 becomes 10,000)
        local decimalSeparatorIndex = zo_strfind(amount, "%" .. DIGIT_GROUP_DECIMAL_REPLACER) -- Look for the literal separator
        local decimalPartString = decimalSeparatorIndex and zo_strsub(amount, decimalSeparatorIndex) or ""
        local wholePartString = zo_strsub(amount, 1, decimalSeparatorIndex and decimalSeparatorIndex - 1)

        amount = ZO_CommaDelimitNumber(tonumber(wholePartString)) .. decimalPartString
    end

    return amount
end

function FarmingParty.FormatNumber(num, numDecimalPlaces)
    return FP_LocalizeDecimalNumber(string.format("%0." .. (numDecimalPlaces or 0) .. "f", num))
end

local function OnPlayerDeactivated(eventCode)
    FarmingParty:Finalize()
end

function FarmingParty:OnAddOnLoaded(event, addonName)
    if (addonName ~= ADDON_NAME) then
        return
    end

    ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_SCOREBOARD", "Toggle Scoreboard")
    
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_DEACTIVATED, OnPlayerDeactivated)
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    FarmingParty.Settings = FarmingPartySettings:New()
    self:Initialize()
end

function FarmingParty:Finalize()
    for moduleName, moduleObject in pairs(self.Modules) do
        moduleObject:Finalize()
    end

    if (self.Settings:ResetStatusOnLogout()) then
        self.Settings:ToggleStatusValue(FarmingParty.Settings.TRACKING_STATUS.DISABLED)
    end
end

function FarmingParty:Initialize()
    self.Modules.MemberList = FarmingPartyMemberList:New()
    self.Modules.Logger = FarmingPartyLogger:New()
    self.Modules.MemberItems = FarmingPartyMemberItems:New()
    self.Modules.Loot = FarmingPartyLoot:New()
    FarmingParty:ConsoleCommands()
end

function FarmingParty:Prune()
    self.Modules.MemberList:PruneMissingMembers()
    d("[Farming Party]: Members have been pruned")    
end

function FarmingParty:UpdateMembers()
    self.Modules.MemberList:PruneMissingMembers()
    self.Modules.MemberList:AddAllGroupMembers()
    d("[Farming Party]: Members have been updated")  
end

function FarmingParty:Reset()
    self.Modules.MemberList:Reset()
    d("[Farming Party]: Tracking data has been reset")
end

function FarmingParty:ConsoleCommands()
    -- Print all available commands to chat
    SLASH_COMMANDS["/fphelp"] = function()
        d("-- Farming Party commands --")
        d("/fp                  Show or hide the highscore window.")
        d("/fp prune            Removes members no longer in group. (Useful when tracking is off and you want to remove members who have left.)")
        d("/fp reset            Resets all loot data.")
        d("/fp [start||stop]    Start or stop loot tracking.")
        d("/fp [status]         Show loot tracking status.")
        d("/fp update           Adds or removes members to match current group. (Useful when tracking is off and you want to update the members.)")
        d("/fpc                 Puts high score output into the chat box.")
    end

    SLASH_COMMANDS["/fp"] = function(param)
        local trimmedParam = string.gsub(param, "%s$", ""):lower()
        if(trimmedParam == "") then
            self.Modules.MemberList:ToggleMembersWindow()
        elseif (trimmedParam == 'prune') then
            self:Prune()
        elseif (trimmedParam == 'reset') then
            self:Reset()
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
        elseif (trimmedParam == 'update') then
            self:UpdateMembers()
        elseif (trimmedParam == 'help') then
            SLASH_COMMANDS["/fphelp"]()
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
end

EVENT_MANAGER:RegisterForEvent(
    ADDON_NAME,
    EVENT_ADD_ON_LOADED,
    function(...)
        FarmingParty:OnAddOnLoaded(...)
    end
)
