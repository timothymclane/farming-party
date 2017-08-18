FarmingPartyHighScore = ZO_Object:Subclass()
local highscoreSettings = nil
local highscoreWindowIsHidden = true

function FarmingPartyHighScore:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function FarmingPartyHighScore:Initialize()
    --highscoreSettings = ZO_SavedVars:New("FarmingPartyHighScore_db", 1, nil, { members = {}, memberCount = 0, positionLeft = 0, positionTop = 0, })
    highscoreSettings = {members = {}, memberCount = 0, positionLeft = 0, positionTop = 0}

    EVENT_MANAGER:RegisterForEvent(
        ADDON_NAME,
        EVENT_GROUP_MEMBER_JOINED,
        function(...)
            self:OnMemberJoined(...)
        end
    )
    EVENT_MANAGER:RegisterForEvent(
        ADDON_NAME,
        EVENT_GROUP_MEMBER_LEFT,
        function(...)
            self:OnMemberLeft(...)
        end
    )

    FarmingPartyHighScoreWindow:SetHidden(true)
    FarmingPartyHighScoreWindow:ClearAnchors()
    FarmingPartyHighScoreWindow:SetAnchor(
        TOPLEFT,
        GuiRoot,
        TOPLEFT,
        highscoreSettings.positionLeft,
        highscoreSettings.positionTop
    )

    self:ConsoleCommands()
    self:UpdateHighscoreWindow()
end

-- EVENT_GROUP_MEMBER_JOINED
function FarmingPartyHighScore:OnMemberJoined(event, memberName)
    self:AddAllMembersInGroup()
end

-- EVENT_GROUP_MEMBER_LEFT
function FarmingPartyHighScore:OnMemberLeft(event, memberName, reason, wasLocalPlayer)
    self:RemoveMember(memberName)
end
--

--[[
    Member functions
]] function FarmingPartyHighScore:NewMember(name, displayName)
    name = zo_strformat(SI_UNIT_NAME, name)

    if not highscoreSettings.members[name] then
        highscoreSettings.members[name] = {
            trash = 0,
            normal = 0,
            fine = 0,
            superior = 0,
            epic = 0,
            legendary = 0,
            bestLoot = "None (0g)",
            deaths = 0,
            totalValue = 0,
            isRowHidden = false,
            rowPosition = 0, -- maybe useless
            items = {},
            displayName = displayName
        }

        highscoreSettings.memberCount = highscoreSettings.memberCount + 1
        highscoreSettings.members[name].rowPosition = highscoreSettings.memberCount
    end

    return highscoreSettings.members[name]
end

function FarmingPartyHighScore:RemoveMember(name)
    name = zo_strformat(SI_UNIT_NAME, name)
    highscoreSettings.members[name] = nil
    highscoreSettings.memberCount = highscoreSettings.memberCount - 1
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighScore:DeleteMembers()
    ZO_ClearTable(highscoreSettings.members)
    highscoreSettings.memberCount = 0
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighScore:MemberExists(name)
    name = zo_strformat(SI_UNIT_NAME, name)
    return highscoreSettings.members[name] ~= nil
end

function FarmingPartyHighScore:ResetMembers()
    for k, v in pairs(highscoreSettings.members) do
        highscoreSettings.members[k] = {
            trash = 0,
            normal = 0,
            fine = 0,
            superior = 0,
            epic = 0,
            legendary = 0,
            bestLoot = "None (0g)",
            deaths = 0,
            totalValue = 0,
            isRowHidden = false,
            rowPosition = 0,
            items = {},
            displayName = v.displayName
        }
    end

    self:UpdateHighscoreWindow()
end

function FarmingPartyHighScore:AddAllMembersInGroup()
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
    for name, displayName in pairs(members) do
        if not Members:HasMember(name) then
            local newMember = Members:NewMember(name)
            Members:SetMember(name, displayName)
        end
    end

    -- Check memberCount, if it's not equal to countMembers, it must be more then that
    -- (each call self:NewMember adds one to the counter). So we have to remove invalid
    -- items from the master list
    if highscoreSettings.memberCount ~= countMembers then
        for name in pairs(highscoreSettings.members) do
            if members[name] == nil then
                highscoreSettings.members[name] = nil
                highscoreSettings.memberCount = highscoreSettings.memberCount - 1
                if highscoreSettings.memberCount == countMembers then
                    break
                end
            end
        end
    end

    self:UpdateHighscoreWindow()
end

function FarmingPartyHighScore:UpdateWindowSize()
    FarmingPartyHighScoreWindow:SetDimensions(500, 122 + (highscoreSettings.memberCount * 26))
end

function FarmingPartyHighScore:UpdateHighscoreWindow()
    self:UpdateWindowSize()

    local count = 0
    for k, v in pairs(highscoreSettings.members) do
        count = count + 1

        if count > 12 then
            break
        end

        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "NAME"):SetText(v.displayName)
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "BESTLOOT"):SetText(v.bestLoot)
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "TOTALVALUE"):SetText(
            FarmingParty:FormatNumber(v.totalValue, 2)
        )

        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "NAME"):SetHidden(false)
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "BESTLOOT"):SetHidden(false)
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "TOTALVALUE"):SetHidden(false)
    end

    -- Make sure that the memberCount is correct
    highscoreSettings.memberCount = count

    -- Hide all the rest lines that are not needed
    -- 24 is the max amount of rows
    while count < 12 do
        count = count + 1
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "NAME"):SetHidden(true)
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "BESTLOOT"):SetHidden(true)
        FarmingPartyHighScoreWindow:GetNamedChild("ROW" .. count .. "TOTALVALUE"):SetHidden(true)
    end
end

function FarmingPartyHighScore:MoveStop()
    highscoreSettings.positionLeft = math.floor(FarmingPartyHighScoreWindow:GetLeft())
    highscoreSettings.positionTop = math.floor(FarmingPartyHighScoreWindow:GetTop())
end
--

--[[
    Update functions
]] function FarmingPartyHighScore:IsBestLoot(name, newLootValue)
    name = zo_strformat(SI_UNIT_NAME, name)
    local currentBestLootValue = tonumber(string.match(highscoreSettings.members[name].bestLoot, "%d+"))
    return newLootValue > currentBestLootValue
end

function FarmingPartyHighScore:UpdateBestLoot(name, itemLink, itemValue)
    name = zo_strformat(SI_UNIT_NAME, name)
    local oldValue = tonumber(string.match(highscoreSettings.members[name].bestLoot, "%d+"))
    highscoreSettings.members[name].bestLoot = zo_strformat("<<t:1>> (<<2>>g)", GetItemLinkName(itemLink), itemValue)
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighScore:UpdateTotalValue(name, newValue)
    name = zo_strformat(SI_UNIT_NAME, name)
    local oldValue = highscoreSettings.members[name].totalValue
    newValue = oldValue + newValue
    highscoreSettings.members[name].totalValue = newValue
    self:UpdateHighscoreWindow()
end

function FarmingPartyHighScore:UpdateLootList(name, itemLink, count, mmPrice)
    name = zo_strformat(SI_UNIT_NAME, name)
    local itemDetails = self:GetItemListFromMembers(name, itemLink)
    itemDetails.count = itemDetails.count + count
    itemDetails.mmPrice = mmPrice
    self:SetItemListForMember(name, itemDetails)
end

function FarmingPartyHighScore:GetItemListFromMembers(memberName, itemLink)
    local itemId = tonumber(string.match(itemLink, "|H.-:item:(.-):"))
    local oldItemList = highscoreSettings.members[memberName].items
    local itemDetails = oldItemList[itemId]
    if (itemDetails == nil) then
        itemDetails = {id = itemId, itemLink = itemLink, count = 0}
    end
    return itemDetails
end

function FarmingPartyHighScore:SetItemListForMember(memberName, item)
    highscoreSettings.members[memberName].items[item.id] = item
end

function FarmingPartyHighScore:ShowMemberItems()
    local fpmWindow = {}
    FarmingPartyMemberItemsWindow:SetHidden(true)
    FarmingPartyMemberItemsWindow:ClearAnchors()
    FarmingPartyMemberItemsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, fpmWindow.positionLeft, fpmWindow.positionTop)
    FarmingPartyMemberItemsWindow:SetHidden(false)
    FarmingPartyHighScore:SetupItemRow()
end

function FarmingPartyHighScore:SetupScrollList()
    local ENTRY_TYPE = 1
    local listContainer = FarmingPartyMemberItemsWindow:GetNamedChild("List")
    ZO_ScrollList_AddDataType(listContainer, ENTRY_TYPE, "FarmingPartyDataRow", 20, InitializeRow)

    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Clear(listContainer)

    local entries = storage:GetKeys()
    for i = 1, #entries do
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(NOTE_TYPE, {key = entries[i]})
    end

    ZO_ScrollList_Commit(indexContainer)
end

function FarmingPartyHighScore:SetupItemRow(control, data)
    local list = FarmingPartyMemberItemsWindow:GetNamedChild("List")
    if (highscoreSettings.members["Aldanga"] == nil) then
        d("no items")
        return
    end
    for k, v in pairs(highscoreSettings.members["Aldanga"].items) do
        d("item: ")
        d(v)
        local dynamicControl = CreateControlFromVirtual("FarmingPartyDataRow", list, "FarmingPartyDataRow", v.id)

        -- dynamicControl.rowId = GetControl(dynamicControl, "RowId")
        -- dynamicControl.farmer = GetControl(dynamicControl, "Farmer")
        -- dynamicControl.icon = GetControl(dynamicControl, "ItemIcon")
        -- dynamicControl.itemName = GetControl(dynamicControl, "ItemName")
        -- dynamicControl.count = GetControl(dynamicControl, "Count")
        -- dynamicControl.totalValue = GetControl(dynamicControl, "TotalValue")

        -- dynamicControl.farmer:SetText("Aldanga")
        -- dynamicControl.itemName:SetText(v.itemLink)
        -- dynamicControl.count:SetText(v.count)
    end
end

local function InitializeRow(control, data)
    control:GetNamedChild("Farmer"):SetText("Aldanga")
    control:GetNamedChild("Count"):SetText(v.count)
    control:GetNamedChild("ItemName"):SetText(v.itemLink)
    control:GetNamedChild("Total Value"):SetText(v.mmPrice * v.count)
end

--
--[[
    Console commands
]] function FarmingPartyHighScore:ConsoleCommands()
    -- Print all available commands to chat
    SLASH_COMMANDS["/glhelp"] = function()
        d("-- Farming Party commands --")
        d("/fp         Show or hide the highscore window.")
        d("/fpc        Print highscores to the chat.")
        d("/fpreset    Reset all highscore values (doesn't remove).")
        d("/fpdelete   Remove everything from highscores.")
    end

    -- Toggle the highscore window
    SLASH_COMMANDS["/fp"] = function()
        if highscoreWindowIsHidden then
            FarmingPartyHighScoreWindow:SetHidden(false)
            highscoreWindowIsHidden = false
        else
            FarmingPartyHighScoreWindow:SetHidden(true)
            highscoreWindowIsHidden = true
        end
    end

    -- Print highscores to the chat
    SLASH_COMMANDS["/fpc"] = function()
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
        FarmingPartyHighScore:ShowMemberItems()
    end
end
