FarmingPartyHighscore = ZO_Object:Subclass()
local highscoreSettings = nil
local highscoreWindowIsHidden = true

function FarmingPartyHighscore:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function FarmingPartyHighscore:Initialize()
    --highscoreSettings = ZO_SavedVars:New("FarmingPartyHighscore_db", 1, nil, { members = {}, memberCount = 0, positionLeft = 0, positionTop = 0, })
    highscoreSettings = { members = {}, memberCount = 0, positionLeft = 0, positionTop = 0, }

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_JOINED, function(...) self:OnMemberJoined(...) end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_LEFT, function(...) self:OnMemberLeft(...) end)

    FarmingPartyHighscoreWindow:SetHidden(true)
    FarmingPartyHighscoreWindow:ClearAnchors()
    FarmingPartyHighscoreWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, highscoreSettings.positionLeft, highscoreSettings.positionTop)

    self:ConsoleCommands()
    self:UpdateHighscoreWindow()
end

-- EVENT_GROUP_MEMBER_JOINED
function FarmingPartyHighscore:OnMemberJoined(event, memberName)
    self:AddAllMembersInGroup()
end

-- EVENT_GROUP_MEMBER_LEFT
function FarmingPartyHighscore:OnMemberLeft(event, memberName, reason, wasLocalPlayer)
    self:RemoveMember(memberName)
end

--[[
    Member functions
]]--
function FarmingPartyHighscore:NewMember(name, displayName)
    name = zo_strformat(SI_UNIT_NAME, name)

    if not highscoreSettings.members[name] then
        highscoreSettings.members[name] = {
            trash       = 0,
            normal      = 0,
            fine        = 0,
            superior    = 0,
            epic        = 0,
            legendary   = 0,
            bestLoot    = "None (0g)",
            deaths      = 0,
            totalValue  = 0,
            isRowHidden = false,
            rowPosition = 0, -- maybe useless
            items       = {},
            displayName = displayName,
        }

        highscoreSettings.memberCount               = highscoreSettings.memberCount + 1
        highscoreSettings.members[name].rowPosition = highscoreSettings.memberCount
    end

    return highscoreSettings.members[name]
end

function FarmingPartyHighscore:RemoveMember(name)
    name = zo_strformat(SI_UNIT_NAME, name)
    highscoreSettings.members[name] = nil
    highscoreSettings.memberCount = highscoreSettings.memberCount - 1
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighscore:DeleteMembers()
    ZO_ClearTable(highscoreSettings.members)
    highscoreSettings.memberCount = 0
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighscore:MemberExists(name)
    name = zo_strformat(SI_UNIT_NAME, name)
    return highscoreSettings.members[name] ~= nil
end

function FarmingPartyHighscore:ResetMembers()
    for k, v in pairs(highscoreSettings.members) do

        highscoreSettings.members[k] = {
            trash       = 0,
            normal      = 0,
            fine        = 0,
            superior    = 0,
            epic        = 0,
            legendary   = 0,
            bestLoot    = "None (0g)",
            deaths      = 0,
            totalValue  = 0,
            isRowHidden = false,
            rowPosition = 0,
            items       = {},
            displayName = v.displayName,
        }
    end

    self:UpdateHighscoreWindow()
end

function FarmingPartyHighscore:AddAllMembersInGroup()
    local countMembers = GetGroupSize()

    -- Get list of member names in current group
    local members = {}
    for i = 1, countMembers do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then        
            local name = zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag))
            members[name] = GetUnitDisplayName(unitTag)
        end
    end

    -- Add all missing members
    for name,displayName in pairs(members) do
        if not self:MemberExists(name) then self:NewMember(name, displayName) end
    end

    -- Check memberCount, if it's not equal to countMembers, it must be more then that
    -- (each call self:NewMember adds one to the counter). So we have to remove invalid
    -- items from the master list
    if highscoreSettings.memberCount ~= countMembers then
        for name in pairs(highscoreSettings.members) do
            if members[name] == nil then
                highscoreSettings.members[name] = nil
                highscoreSettings.memberCount = highscoreSettings.memberCount - 1
                if highscoreSettings.memberCount == countMembers then break end
            end
        end
    end

    self:UpdateHighscoreWindow()
end


function FarmingPartyHighscore:UpdateWindowSize()
    FarmingPartyHighscoreWindow:SetDimensions(500, 122 + (highscoreSettings.memberCount * 26))
end

function FarmingPartyHighscore:UpdateHighscoreWindow()
    self:UpdateWindowSize()

    local count = 0
    for k, v in pairs(highscoreSettings.members) do
        count = count + 1

        if count > 12 then break end

        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "NAME"):SetText(v.displayName)
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "BESTLOOT"):SetText(v.bestLoot)
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "TOTALVALUE"):SetText(FarmingParty:FormatNumber(v.totalValue, 2))

        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "NAME"):SetHidden(false)
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "BESTLOOT"):SetHidden(false)
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "TOTALVALUE"):SetHidden(false)
    end

    -- Make sure that the memberCount is correct
    highscoreSettings.memberCount = count

    -- Hide all the rest lines that are not needed
    -- 24 is the max amount of rows
    while count < 12 do
        count = count + 1
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "NAME"):SetHidden(true)
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "BESTLOOT"):SetHidden(true)
        FarmingPartyHighscoreWindow:GetNamedChild("ROW" .. count .. "TOTALVALUE"):SetHidden(true)
    end
end

function FarmingPartyHighscore:MoveStop()
    highscoreSettings.positionLeft = math.floor(FarmingPartyHighscoreWindow:GetLeft())
    highscoreSettings.positionTop = math.floor(FarmingPartyHighscoreWindow:GetTop())
end

--[[
    Update functions
]]--
function FarmingPartyHighscore:IsBestLoot(name, newLootValue)
    name = zo_strformat(SI_UNIT_NAME, name)
    local currentBestLootValue = tonumber(string.match(highscoreSettings.members[name].bestLoot, "%d+"))
    return newLootValue > currentBestLootValue
end

function FarmingPartyHighscore:UpdateBestLoot(name, itemLink, itemValue)
    name = zo_strformat(SI_UNIT_NAME, name)
    local oldValue = tonumber(string.match(highscoreSettings.members[name].bestLoot, "%d+"))
    highscoreSettings.members[name].bestLoot = zo_strformat("<<t:1>> (<<2>>g)", GetItemLinkName(itemLink), itemValue)
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighscore:UpdateTotalValue(name, newValue)
    name = zo_strformat(SI_UNIT_NAME, name)
    local oldValue = highscoreSettings.members[name].totalValue
    newValue = oldValue + newValue
    highscoreSettings.members[name].totalValue = newValue
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighscore:UpdateLootList(name, itemLink, count)
    name = zo_strformat(SI_UNIT_NAME, name)
    local itemDetails = self:GetItemListFromMembers(name, itemLink)
    itemDetails.count = itemDetails.count + count
    self:SetItemListForMember(name, itemDetails)
end

function FarmingPartyHighscore:GetItemListFromMembers(memberName, itemLink)
    local itemId = tonumber(string.match(itemLink, '|H.-:item:(.-):'))
    local oldItemList = highscoreSettings.members[memberName].items
    local itemDetails = oldItemList[itemId]
    if(itemDetails == nil) then
        itemDetails = {id = itemId, itemLink = itemLink, count = 0}
    end
    return itemDetails
end

function FarmingPartyHighscore:SetItemListForMember(memberName, item)
    highscoreSettings.members[memberName].items[item.id] = item
end
--[[
    Console commands
]]--
function FarmingPartyHighscore:ConsoleCommands()
    -- Print all available commands to chat
    SLASH_COMMANDS["/glhelp"] = function ()
        d("-- Farming Party commands --")
        d("/fp         Show or hide the highscore window.")
        d("/fpc        Print highscores to the chat.")
        d("/fpreset    Reset all highscore values (doesn't remove).")
        d("/fpdelete   Remove everything from highscores.")
    end

    -- Toggle the highscore window
    SLASH_COMMANDS["/fp"] = function ()
        if highscoreWindowIsHidden then
            FarmingPartyHighscoreWindow:SetHidden(false)
            highscoreWindowIsHidden = false
        else
            FarmingPartyHighscoreWindow:SetHidden(true)
            highscoreWindowIsHidden = true
        end
    end

    -- Print highscores to the chat
    SLASH_COMMANDS["/fpc"] = function ()
        local next = next
        if next(highscoreSettings.members) ~= nil then
            d("Name: Best Loot | Total Value")
            for k, v in pairs(highscoreSettings.members) do
                d(k .. ": " .. v.bestLoot .. " | " .. v.totalValue)
            end
        else
            d("Nothing recorded yet.")
        end
    end

    -- Reset all stats from the .member table
    SLASH_COMMANDS["/fpreset"] = function ()
        FarmingPartyHighscore:ResetMembers()
        d("Farming Party highscores have been reset")
    end

    -- Clear all members from the .member table
    SLASH_COMMANDS["/fpdelete"] = function ()
        FarmingPartyHighscore:DeleteMembers()
        d("Farming Party highscores have been deleted")
    end
end